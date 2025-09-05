// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./TestController.sol";

/**
 * @title TestVault
 * @dev A minimal vault that mints/burns internal "shares" against multiple strategies.
 *
 * NOTE: Architecture inspired by Yearn V2 vaults but simplified for testing.
 *
 * user <-> TestVault <-> TestController <-> TestStrategies
 *                     |
 *                InsurancePool

 User
  ↕ (deposit/withdraw)
TestVault
  ↕ (depositFromVault/returnFundsToVault)
TestController
  ↕ (allocateToStrategy/withdraw)
StrategyRegistry ← AIDecisionModule
  ↕ (strategy selection)   ↑ (allocation decisions)
Strategies (Aave, Compound, etc.)
  ↕ (price/yield data)
PriceOracle / YieldOracle
  ↕ (security checks)
SecurityModule
  ↕ (fees)
InsurancePool

 *
 * Main features:
 * - Users deposit tokens and receive proportional shares per strategy
 * - Users can withdraw tokens by burning shares from a specific strategy
 * - Funds are invested in external strategies (yield farming, lending, etc.)
 * - Pausable: deposits/withdraws can be paused in emergencies
 * - Owner can rescue funds (emergencyWithdraw)
 * - Users can redeem only idle vault tokens (emergencyUserWithdraw) if strategy is broken
 */
contract TestVault is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // The ERC20 token the vault accepts (e.g. USDC, DAI)
    IERC20 public immutable token;

    // The controller contract managing strategies
    TestController public controller;

    // User address => strategy address => number of vault shares owned
    mapping(address => mapping(address => uint256)) public userStrategyShares;

    // Strategy address => total supply of shares issued
    mapping(address => uint256) public totalStrategyShares;

    // InsurancePool address for fee collection
    address public insurancePool;

    // -----------------
    // Events
    // -----------------
    event Deposit(address indexed user, uint256 amount, uint256 sharesMinted, address indexed strategy);
    event Withdraw(address indexed user, uint256 amount, uint256 sharesBurned, address indexed strategy);
    event StrategyUpdated(address indexed newStrategy);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);
    event EmergencyUserWithdraw(address indexed user, uint256 amount, uint256 sharesBurned, address indexed strategy);
    event FeeDeposited(uint256 amount);
    event FeeClaimed(address indexed to, uint256 amount);

    // -----------------
    // Constructor
    // -----------------

    /**
     * @notice Initialize vault with underlying token and controller
     * @param _token ERC20 token accepted by the vault
     * @param _controller Controller contract managing strategies
     */
    constructor(IERC20 _token, TestController _controller) Ownable(msg.sender) {
        require(address(_controller) != address(0), "Controller zero");
        token = _token;
        controller = _controller;
    }

    // -----------------
    // Admin controls
    // -----------------

    /**
     * @notice Set controller address (optional role for automation/governance)
     * @dev Updated to set new controller and ensure non-zero address
     */
    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Controller zero");
        controller = TestController(_controller);
    }

    /**
     * @notice Update strategy contract
     * @dev Routes through controller to add strategy to whitelist
     */
    function setStrategy(address _strategy) external onlyOwner {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        emit StrategyUpdated(_strategy);
    }

    /**
     * @notice Pause deposits and withdrawals (emergency mode)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resume normal operation
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Pull all funds back from a specific strategy to vault
     * @dev Use only in emergencies — this breaks normal accounting
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
     * @notice Rescue non-vault tokens accidentally sent here
     * @dev Prevents owner from stealing the vault's main token
     */
    function rescueTokens(IERC20 _token, uint256 amount, address to) external onlyOwner {
        require(address(_token) != address(token), "Rescue: cannot withdraw vault token");
        _token.safeTransfer(to, amount);
    }

    /**
     * @notice Set the Insurance Pool address for fee collection
     * @dev Can be set to address(0) to disable fees
     */
    function setInsurancePool(address _insurancePool) external onlyOwner {
        require(_insurancePool != address(0), "InsurancePool zero");
        insurancePool = _insurancePool;
    }

    // -----------------
    // User functions
    // -----------------

    /**
     * @notice Deposit underlying tokens into vault for multiple strategies
     * @dev User receives proportional shares representing their ownership in each strategy
     * @param _amounts Array of amounts of tokens to deposit per strategy
     * @param _strategies Array of whitelisted strategy addresses
     */
    function depositToMultipleStrategies(uint256[] calldata _amounts, address[] calldata _strategies) external nonReentrant whenNotPaused {
        require(_amounts.length == _strategies.length, "Mismatched inputs");
        for (uint256 i = 0; i < _amounts.length; i++) {
            deposit(_amounts[i], _strategies[i]);
        }
    }

    /**
     * @notice Deposit underlying tokens into vault for a specific strategy
     * @dev User receives proportional shares representing their ownership in the strategy
     * @param _amount Amount of tokens to deposit
     * @param _strategy Address of the whitelisted strategy
     */
    function deposit(uint256 _amount, address _strategy) external nonReentrant whenNotPaused {
        require(_amount > 0, "Deposit: amount must be greater than zero");
        require(controller.isStrategy(_strategy), "Invalid strategy");

        uint256 fee = 0;
        uint256 depositAmount = _amount;
        if (insurancePool != address(0)) {
            fee = (_amount * 2) / 1000; // 0.2% fee
            depositAmount = _amount - fee;
        }

        // Pull full amount from user
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Send fee to Insurance Pool
        if (fee > 0) {
            token.safeTransfer(insurancePool, fee);
            emit FeeDeposited(fee);
        }

        // --- SHARES CALCULATION ---
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        uint256 balanceBefore = poolBalance;

        uint256 sharesToMint;
        if (totalStrategyShares[_strategy] == 0) {
            sharesToMint = depositAmount; // first depositor = 1:1
        } else {
            require(poolBalance > 0, "Deposit: invalid pool balance");
            sharesToMint = (depositAmount * totalStrategyShares[_strategy]) / poolBalance;
        }
        require(sharesToMint > 0, "Deposit: zero shares");

        // Update accounting
        userStrategyShares[msg.sender][_strategy] += sharesToMint;
        totalStrategyShares[_strategy] += sharesToMint;

        // Approve and send funds to strategy via controller
        token.approve(address(controller), depositAmount);
        controller.depositFromVault(_strategy, depositAmount);

        // Check balance protection
        uint256 balanceAfter = controller.getStrategyBalance(_strategy, address(this));
        require(balanceAfter >= balanceBefore + depositAmount, "Deposit: strategy balance mismatch");

        emit Deposit(msg.sender, depositAmount, sharesToMint, _strategy);
    }

    /**
     * @notice Withdraw underlying tokens from vault for a specific strategy
     * @param _amount Amount of tokens user wants back
     * @param _strategy Address of the whitelisted strategy
     */
    function withdraw(uint256 _amount, address _strategy) external nonReentrant whenNotPaused {
        require(_amount > 0, "Withdraw: amount must be greater than zero");
        require(userStrategyShares[msg.sender][_strategy] > 0, "Withdraw: no shares owned");
        require(controller.isStrategy(_strategy), "Invalid strategy");

        // Get current pool balance from controller
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        require(poolBalance > 0 && totalStrategyShares[_strategy] > 0, "Withdraw: empty pool");

        // Compute user’s max withdrawable balance
        uint256 userBalance = (userStrategyShares[msg.sender][_strategy] * poolBalance) / totalStrategyShares[_strategy];
        require(_amount <= userBalance, "Withdraw: amount exceeds balance");

        // Calculate how many shares to burn
        uint256 sharesToBurn = (_amount * totalStrategyShares[_strategy]) / poolBalance;
        require(sharesToBurn > 0, "Withdraw: zero shares to burn");

        // Update accounting
        userStrategyShares[msg.sender][_strategy] -= sharesToBurn;
        totalStrategyShares[_strategy] -= sharesToBurn;

        // Ensure vault has enough tokens to pay user
        uint256 vaultBalance = token.balanceOf(address(this));
        if (vaultBalance < _amount) {
            // Pull missing amount from strategy via controller
            uint256 missing = _amount - vaultBalance;
            controller.returnFundsToVault(_strategy, missing);
        }

        // --- WITHDRAWAL FEE LOGIC ---
        uint256 fee = 0;
        uint256 amountAfterFee = _amount;
        if (insurancePool != address(0)) {
            fee = (_amount * 2) / 1000; // 0.2% fee
            amountAfterFee = _amount - fee;
            if (fee > 0) {
                token.safeTransfer(insurancePool, fee);
                emit FeeDeposited(fee);
            }
        }

        // Transfer tokens back to user
        token.safeTransfer(msg.sender, amountAfterFee);

        emit Withdraw(msg.sender, amountAfterFee, sharesToBurn, _strategy);
    }

    /**
     * @notice Emergency withdrawal for users
     * @dev Lets users redeem their proportional share of idle vault tokens
     *      Does not interact with strategy (assume it may be broken)
     *      Note: Users may receive less than their full balance if strategy funds are trapped
     */
    function emergencyUserWithdraw(address _strategy) external nonReentrant whenPaused {
        require(userStrategyShares[msg.sender][_strategy] > 0, "Emergency: no shares owned");
        require(totalStrategyShares[_strategy] > 0, "Emergency: no shares supply");
        require(controller.isStrategy(_strategy), "Invalid strategy");

        // Only use tokens already idle in vault
        uint256 vaultBalance = token.balanceOf(address(this));
        require(vaultBalance > 0, "Emergency: no idle tokens");

        // Calculate user’s proportional share of idle tokens
        uint256 userShares = userStrategyShares[msg.sender][_strategy];
        uint256 amountToWithdraw = (userShares * vaultBalance) / totalStrategyShares[_strategy];

        // Burn all user shares for this strategy
        userStrategyShares[msg.sender][_strategy] = 0;
        totalStrategyShares[_strategy] -= userShares;

        // Transfer idle tokens to user
        token.safeTransfer(msg.sender, amountToWithdraw);

        emit EmergencyUserWithdraw(msg.sender, amountToWithdraw, userShares, _strategy);
    }

    // -----------------
    // View helpers
    // -----------------

    /**
     * @notice Total value managed by vault for a specific strategy
     */
    function getBalance(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyBalance(_strategy, address(this));
    }

    /**
     * @notice User’s balance in underlying tokens for a specific strategy
     */
    function getUserBalance(address _user, address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        if (totalStrategyShares[_strategy] == 0) return 0;
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        return (userStrategyShares[_user][_strategy] * poolBalance) / totalStrategyShares[_strategy];
    }

    /**
     * @notice Price per share for a specific strategy
     */
    function getPricePerShare(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        if (totalStrategyShares[_strategy] == 0) return 1e18;
        uint256 poolBalance = controller.getStrategyBalance(_strategy, address(this));
        return (poolBalance * 1e18) / totalStrategyShares[_strategy];
    }

    /**
     * @notice Balance of tokens sitting idle in vault
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Balance of tokens inside a specific strategy
     */
    function getStrategyBalance(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyBalance(_strategy, address(this));
    }

    /**
     * @notice Get the underlying token address
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @notice Get the controller address
     */
    function getController() external view returns (address) {
        return address(controller);
    }

    /**
     * @notice Strategy-reported APY for a specific strategy
     */
    function apy(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return controller.getStrategyAPY(_strategy);
    }

    /**
     * @notice Forward call to strategy to simulate yield generation (testing only)
     */
    function generateYield(address _strategy) external {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        controller.triggerYieldGeneration(_strategy);
    }

    /**
     * @notice Total supply of shares for a specific strategy
     */
    function getTotalShares(address _strategy) external view returns (uint256) {
        require(controller.isStrategy(_strategy), "Invalid strategy");
        return totalStrategyShares[_strategy];
    }
}