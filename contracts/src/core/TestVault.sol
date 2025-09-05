// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./TestController.sol"; // Updated import to reference TestController

/**
 * @title TestVault
 * @dev A minimal vault that mints/burns internal "shares" against a single strategy.
 *

NOTE: Architecture inspired by Yearn V2 vaults but simplified for testing.

user <-> TestVault <-> TestController <-> TestStrategies


 * Main features:
 * - Users deposit tokens and receive proportional shares
 * - Users can withdraw tokens by burning shares
 * - Funds are invested in an external strategy (yield farming, lending, etc.)
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

    // User address => number of vault shares owned
    mapping(address => uint256) public shares;

    // Total supply of shares issued
    uint256 public totalShares;

    // -----------------
    // Events
    // -----------------
    event Deposit(address indexed user, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed user, uint256 amount, uint256 sharesBurned);
    event StrategyUpdated(address indexed newStrategy);
    event EmergencyWithdraw(uint256 amount);
    event EmergencyUserWithdraw(address indexed user, uint256 amount, uint256 sharesBurned);

    // -----------------
    // Constructor
    // -----------------

    /**
     * @notice Initialize vault with underlying token and controller
     * @dev Updated to use controller instead of direct strategy
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
        controller.addStrategy(_strategy);
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
     * @notice Pull all funds back from strategy to vault
     * @dev Use only in emergencies — this breaks normal accounting
     * @dev Updated to route through controller
     */
    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 strategyBal = controller.getStrategyBalance(address(controller.getStrategy()), address(this));
        if (strategyBal > 0) {
            controller.emergencyWithdrawFromStrategy(address(controller.getStrategy()), strategyBal);
            emit EmergencyWithdraw(strategyBal);
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

    // -----------------
    // User functions
    // -----------------

    /**
     * @notice Deposit underlying tokens into vault
     * @dev User receives proportional shares representing their ownership
     * @dev Updated to route deposits through controller
     */
    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Deposit: amount must be greater than zero");

        // Get current total pool value from controller
        address activeStrategy = controller.getStrategy();
        uint256 poolBalance = controller.getStrategyBalance(activeStrategy, address(this));

        // Calculate how many shares to mint
        uint256 sharesToMint;
        if (totalShares == 0) {
            // First depositor gets 1:1 shares
            sharesToMint = _amount;
        } else {
            require(poolBalance > 0, "Deposit: invalid pool balance");
            sharesToMint = (_amount * totalShares) / poolBalance;
        }
        require(sharesToMint > 0, "Deposit: zero shares");

        // Pull tokens from user into vault
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Update user and total share accounting
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;

        // Approve controller to pull tokens
        uint256 currentAllowance = token.allowance(address(this), address(controller));
        if (currentAllowance != 0) {
            token.approve(address(controller), 0); // Reset allowance (safety pattern)
        }
        token.approve(address(controller), _amount);

        // Deposit into strategy via controller
        controller.depositFromVault(activeStrategy, _amount);

        // Post-deposit balance check (basic sanity)
        uint256 newPoolBalance = controller.getStrategyBalance(activeStrategy, address(this));
        require(newPoolBalance >= poolBalance + _amount, "Deposit: pool balance mismatch");

        emit Deposit(msg.sender, _amount, sharesToMint);
    }

    /**
     * @notice Withdraw underlying tokens from vault
     * @dev Updated to route withdrawals through controller
     * @param _amount Amount of tokens user wants back
     */
    function withdraw(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Withdraw: amount must be greater than zero");
        require(shares[msg.sender] > 0, "Withdraw: no shares owned");

        // Get current pool balance from controller
        address activeStrategy = controller.getStrategy();
        uint256 poolBalance = controller.getStrategyBalance(activeStrategy, address(this));
        require(poolBalance > 0 && totalShares > 0, "Withdraw: empty pool");

        // Compute user’s max withdrawable balance
        uint256 userBalance = (shares[msg.sender] * poolBalance) / totalShares;
        require(_amount <= userBalance, "Withdraw: amount exceeds balance");

        // Calculate how many shares to burn
        uint256 sharesToBurn = (_amount * totalShares) / poolBalance;
        require(sharesToBurn > 0, "Withdraw: zero shares to burn");

        // Update accounting
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // Ensure vault has enough tokens to pay user
        uint256 vaultBalance = token.balanceOf(address(this));
        if (vaultBalance < _amount) {
            // Pull missing amount from strategy via controller
            uint256 missing = _amount - vaultBalance;
            controller.returnFundsToVault(activeStrategy, missing);
        }

        // Transfer tokens back to user
        token.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, sharesToBurn);
    }

    /**
     * @notice Emergency withdrawal for users
     * @dev Lets users redeem their proportional share of idle vault tokens
     *      Does not interact with strategy (assume it may be broken)
     */
    function emergencyUserWithdraw() external nonReentrant whenPaused {
        require(shares[msg.sender] > 0, "Emergency: no shares owned");
        require(totalShares > 0, "Emergency: no shares supply");

        // Only use tokens already idle in vault
        uint256 vaultBalance = token.balanceOf(address(this));
        require(vaultBalance > 0, "Emergency: no idle tokens");

        // Calculate user’s proportional share of idle tokens
        uint256 userShares = shares[msg.sender];
        uint256 amountToWithdraw = (userShares * vaultBalance) / totalShares;

        // Burn all user shares
        shares[msg.sender] = 0;
        totalShares -= userShares;

        // Transfer idle tokens to user
        token.safeTransfer(msg.sender, amountToWithdraw);

        emit EmergencyUserWithdraw(msg.sender, amountToWithdraw, userShares);
    }

    // -----------------
    // View helpers
    // -----------------

    /**
     * @notice Total value managed by vault (in strategy)
     * @dev Updated to query controller for strategy balance
     */
    function getBalance() external view returns (uint256) {
        return controller.getStrategyBalance(controller.getStrategy(), address(this));
    }

    /**
     * @notice User’s balance in underlying tokens (not shares)
     * @dev Updated to query controller for strategy balance
     */
    function getUserBalance(address _user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        uint256 poolBalance = controller.getStrategyBalance(controller.getStrategy(), address(this));
        return (shares[_user] * poolBalance) / totalShares;
    }

    /**
     * @notice Price per share = total pool / total shares
     * @dev Updated to query controller for strategy balance
     */
    function getPricePerShare() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        uint256 poolBalance = controller.getStrategyBalance(controller.getStrategy(), address(this));
        return (poolBalance * 1e18) / totalShares;
    }

    /**
     * @notice Balance of tokens sitting idle in vault
     */
    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Balance of tokens inside strategy
     * @dev Updated to query controller for strategy balance
     */
    function getStrategyBalance() external view returns (uint256) {
        return controller.getStrategyBalance(controller.getStrategy(), address(this));
    }

    /**
     * @notice Get the underlying token address
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @notice Get the controller address
     * @dev Updated to return controller instead of unused controller field
     */
    function getController() external view returns (address) {
        return address(controller);
    }

    /**
     * @notice Get the active strategy address
     * @dev Added to query controller for the active strategy
     */
    function getStrategy() external view returns (address) {
        return controller.getStrategy();
    }

    /**
     * @notice Strategy-reported APY (for UI only, not trustless)
     * @dev Updated to query controller for strategy APY
     */
    function apy() external view returns (uint256) {
        return controller.getStrategyAPY(controller.getStrategy());
    }

    /**
     * @notice Total supply of shares
     */
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    /**
     * @notice Forward call to strategy to simulate yield generation (testing only)
     * @dev Updated to route through controller
     */
    function generateYield() external {
        controller.triggerYieldGeneration(controller.getStrategy());
    }
}