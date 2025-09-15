// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./ControllerYield.sol";

/**
 * @title TestVault
 * @dev Vault that issues per-strategy shares. Integrates with ControllerAPIYield
 *      (which itself manages BaseStrategy-compatible strategies).
 *
 * Flow:
 *              Vault (ERC-7540)  <-> ControllerYield (RWA) <-> RWA Strategies (BaseStrategy)
 *                      |
 *  user  <->  Vault (ERC-4626)  <->  ControllerYield (DeFi) <-> DeFi Strategies (BaseStrategy)
 *                     |
 *                     +-- idle tokens   ---> insurancePool (fee)
 * Notes:
 *  - Shares are per-strategy (user -> strategy -> shares)
 *  - Price per share is computed as (poolBalance * 1e18) / totalShares
 *  - Vault always tries to use idle vault tokens first; pulls from controller if needed
 *  - Controller didnt pass exact event of asset in deposit, withdrawl. Instead it only event the strategy
 *  - With that it shows that the one in control is actually the strategy.
 */
contract TestVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    ControllerAPIYield public controller;

    // user => strategy => shares
    mapping(address => mapping(address => uint256)) public userStrategyShares;
    // strategy => total shares
    mapping(address => uint256) public totalStrategyShares;

    // fees buffered (accumulated but not yet transferred to insurancePool)
    uint256 public feesOutstanding;

    address public insurancePool;

    // events
    event Deposit(address indexed user, uint256 amount, uint256 sharesMinted, address indexed strategy);
    event Withdraw(address indexed user, uint256 amount, uint256 sharesBurned, address indexed strategy);
    event StrategyUpdated(address indexed strategy);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);
    event EmergencyUserWithdraw(address indexed user, uint256 amount, uint256 sharesBurned, address indexed strategy);
    event FeeDeposited(uint256 amount);
    event FeeClaimed(address indexed to, uint256 amount);
    event Harvested(address indexed strategy);
    event Tended(address indexed strategy);

    constructor(IERC20 _token, ControllerAPIYield _controller) Ownable(msg.sender) {
        require(address(_token) != address(0), "Token zero");
        require(address(_controller) != address(0), "Controller zero");
        token = _token;
        controller = _controller;
    }

    // -------------------------
    // Admin / config
    // -------------------------
    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Controller zero");
        controller = ControllerAPIYield(_controller);
    }

    function setInsurancePool(address _insurancePool) external onlyOwner {
        // allow disabling by setting to address(0)
        insurancePool = _insurancePool;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice claim buffered fees to insurance pool
     */
    function claimFees() external onlyOwner {
        require(insurancePool != address(0), "InsurancePool not set");
        uint256 amount = feesOutstanding;
        require(amount > 0, "No fees");
        feesOutstanding = 0;
        token.safeTransfer(insurancePool, amount);
        emit FeeClaimed(insurancePool, amount);
    }

    // -------------------------
    // Deposits
    // -------------------------
    /**
     * @notice Deposit multiple strategy deposits in one call
     * @dev Arrays must match in length
     */
    function depositToMultipleStrategies(uint256[] calldata _amounts, address[] calldata _strategies)
        external
        nonReentrant
        whenNotPaused
    {
        require(_amounts.length == _strategies.length, "Mismatched inputs");
        for (uint256 i = 0; i < _amounts.length; i++) {
            deposit(_amounts[i], _strategies[i]);
        }
    }

    /**
     * @notice Deposit into a single strategy and mint strategy-specific shares
     */
    function deposit(uint256 _amount, address _strategy) public nonReentrant whenNotPaused {
        require(_amount > 0, "Deposit: zero amount");
        require(controller.isStrategy(_strategy), "Deposit: invalid strategy");

        // compute fee
        uint256 fee = 0;
        uint256 depositAmount = _amount;
        if (insurancePool != address(0)) {
            fee = (_amount * 2) / 1000; // 0.2%
            depositAmount = _amount - fee;
        }

        // pull tokens from user
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // buffer fee to feesOutstanding (do not immediately send: owner can batch send)
        if (fee > 0) {
            feesOutstanding += fee;
            emit FeeDeposited(fee);
        }

        // get pool balance for vault inside strategy (controller tracks per-vault holdings)
        uint256 balanceBefore = controller.getStrategyBalance(_strategy, address(this));

        uint256 sharesToMint;
        if (totalStrategyShares[_strategy] == 0) {
            // first depositor: 1:1 with depositAmount
            sharesToMint = depositAmount;
        } else {
            require(balanceBefore > 0, "Deposit: invalid pool balance");
            // shares = depositAmount * totalShares / poolBalance
            sharesToMint = (depositAmount * totalStrategyShares[_strategy]) / balanceBefore;
        }
        require(sharesToMint > 0, "Deposit: zero shares");

        // update accounting
        userStrategyShares[msg.sender][_strategy] += sharesToMint;
        totalStrategyShares[_strategy] += sharesToMint;

        // Approve vault -> controller only for the deposit amount (safeIncreaseAllowance)
        token.safeIncreaseAllowance(address(controller), depositAmount);

        // route funds to controller which will deposit into strategy
        controller.depositFromVault(_strategy, depositAmount);

        // sanity check: controller should report increased strategy balance for the vault
        uint256 balanceAfter = controller.getStrategyBalance(_strategy, address(this));
        require(balanceAfter >= balanceBefore + depositAmount, "Deposit: strategy balance mismatch");

        emit Deposit(msg.sender, depositAmount, sharesToMint, _strategy);
    }

    // -------------------------
    // Withdraw
    // -------------------------
    /**
     * @notice Withdraw amount from vault for a specific strategy by burning shares
     */
    function withdraw(uint256 _amount, address _strategy) external nonReentrant whenNotPaused {
        require(_amount > 0, "Withdraw: zero amount");
        uint256 userShares = userStrategyShares[msg.sender][_strategy];
        require(userShares > 0, "Withdraw: no shares");
        require(controller.isStrategy(_strategy), "Withdraw: invalid strategy");

        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        require(poolBalance > 0 && totalStrategyShares[_strategy] > 0, "Withdraw: empty pool");

        // compute user's token balance denominated in underlying
        uint256 userBalance = (userShares * poolBalance) / totalStrategyShares[_strategy];
        require(_amount <= userBalance, "Withdraw: exceeds user balance");

        // compute shares to burn = _amount * totalShares / poolBalance
        uint256 sharesToBurn = (_amount * totalStrategyShares[_strategy]) / poolBalance;
        require(sharesToBurn > 0, "Withdraw: zero shares to burn");

        // update accounting
        userStrategyShares[msg.sender][_strategy] = userShares - sharesToBurn;
        totalStrategyShares[_strategy] -= sharesToBurn;

        // ensure vault has tokens; otherwise pull from strategy via controller
        uint256 vaultBalance = token.balanceOf(address(this));
        if (vaultBalance < _amount) {
            uint256 missing = _amount - vaultBalance;
            controller.returnFundsToVault(_strategy, missing);
        }

        // withdrawal fee
        uint256 fee = 0;
        uint256 amountAfterFee = _amount;
        if (insurancePool != address(0)) {
            fee = (_amount * 2) / 1000;
            amountAfterFee = _amount - fee;
            // buffer fee
            feesOutstanding += fee;
            emit FeeDeposited(fee);
        }

        // transfer
        token.safeTransfer(msg.sender, amountAfterFee);

        emit Withdraw(msg.sender, amountAfterFee, sharesToBurn, _strategy);
    }

    // -------------------------
    // Emergency flows
    // -------------------------
    /**
     * @notice Owner emergency: pull all idle funds from a strategy back into vault
     * @dev Owner must call pause first (we require whenPaused)
     */
    function emergencyWithdraw(address _strategy) external onlyOwner whenPaused {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        uint256 strategyBal = controller.getStrategyBalance(_strategy, address(this));
        if (strategyBal > 0) {
            controller.emergencyWithdrawFromStrategy(_strategy, strategyBal);
            emit EmergencyWithdraw(_strategy, strategyBal);
        }
    }

    /**
     * @notice Emergency user withdraw: redeem share of idle tokens in the vault (when paused)
     * @dev Useful if strategy is broken and owner hasn't pulled funds back yet
     */
    function emergencyUserWithdraw(address _strategy) external nonReentrant whenPaused {
        uint256 userShares = userStrategyShares[msg.sender][_strategy];
        require(userShares > 0, "Emergency: no shares");
        require(totalStrategyShares[_strategy] > 0, "Emergency: no supply");
        require(controller.isStrategy(_strategy), "Invalid strategy");

        uint256 vaultBalance = token.balanceOf(address(this));
        require(vaultBalance > 0, "Emergency: no idle tokens");

        uint256 amountToWithdraw = (userShares * vaultBalance) / totalStrategyShares[_strategy];

        // burn
        userStrategyShares[msg.sender][_strategy] = 0;
        totalStrategyShares[_strategy] -= userShares;

        token.safeTransfer(msg.sender, amountToWithdraw);
        emit EmergencyUserWithdraw(msg.sender, amountToWithdraw, userShares, _strategy);
    }

    // -------------------------
    // Harvest / Tend helpers
    // -------------------------
    /**
     * @notice Trigger harvest on a strategy via controller (owner)
     * @dev After harvest, strategy's total assets (poolBalance) will typically increase
     */
    function harvestStrategy(address _strategy) external onlyOwner {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        controller.harvestStrategy(_strategy);
        emit Harvested(_strategy);
    }

    /**
     * @notice Trigger tend on a strategy via controller (owner)
     */
    function tendStrategy(address _strategy) external onlyOwner {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        controller.tendStrategy(_strategy);
        emit Tended(_strategy);
    }

    // -------------------------
    // Views / helpers
    // -------------------------
    function getBalance(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyBalance(_strategy, address(this));
    }

    function getUserBalance(address _user, address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        if (totalStrategyShares[_strategy] == 0) return 0;
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        return (userStrategyShares[_user][_strategy] * poolBalance) / totalStrategyShares[_strategy];
    }

    /**
     * @notice Price per share scaled to 1e18
     */
    function getPricePerShare(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        if (totalStrategyShares[_strategy] == 0) return 1e18;
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        // scaled to 1e18 to avoid decimals
        return (poolBalance * 1e18) / totalStrategyShares[_strategy];
    }

    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getStrategyBalance(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyBalance(_strategy, address(this));
    }

    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    function getController() external view returns (address) {
        return address(controller);
    }

    function apy(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyAPY(_strategy);
    }

    function generateYield(address _strategy) external {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        controller.triggerYieldGeneration(_strategy);
    }

    function getTotalShares(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return totalStrategyShares[_strategy];
    }

    // -------------------------
    // Rescue tokens (non-vault token)
    // -------------------------
    function rescueTokens(IERC20 _token, uint256 amount, address to) external onlyOwner {
        require(address(_token) != address(token), "Cannot rescue vault token");
        _token.safeTransfer(to, amount);
    }
}
