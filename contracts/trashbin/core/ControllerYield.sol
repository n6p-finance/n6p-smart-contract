// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import "../BaseStrategy.sol";

/**
 * @title TestControllerWithBaseStrategy
 * @notice Controller that manages multiple BaseStrategy-compatible strategies
 *         Supports deposit/withdraw, harvest, tend, and asset reporting
 */
abstract contract ControllerYield is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// Vault address
    address public vault;

    /// Underlying token
    IERC20 public immutable token;

    /// Managed strategies
    address[] public strategies;
    mapping(address => bool) public isStrategy;

    /// Governance
    address public governance;

    /// Timelock for strategy addition
    TimelockController public immutable timelock;
    uint256 public constant TIMELOCK_DURATION = 1 days;
    mapping(address => uint256) public pendingStrategies;
    mapping(address => bool) public blacklistedStrategies;

    /// Events
    event StrategyAdded(address indexed strategy);
    event StrategyRemoved(address indexed strategy);
    event FundsAllocated(address indexed strategy, uint256 amount);
    event FundsWithdrawn(address indexed strategy, uint256 amount);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);
    event VaultChanged(address indexed newVault);
    event ControllerPaused();
    event ControllerUnpaused();
    event StrategyProposed(address indexed strategy, uint256 timestamp);
    event StrategyBlacklisted(address indexed strategy);

    constructor(address _token, address _initialOwner, address _timelock) Ownable(_initialOwner) {
        require(_token != address(0), "Token zero");
        require(_initialOwner != address(0), "Owner zero");
        require(_timelock != address(0), "Timelock zero");

        token = IERC20(_token);
        governance = _initialOwner;
        timelock = TimelockController(payable(_timelock));
    }

    // ----------------------
    // Modifiers
    // ----------------------
    modifier onlyVault() {
        require(msg.sender == vault, "Controller: caller not vault");
        _;
    }

    modifier onlyManagedStrategy(address _strategy) {
        require(isStrategy[_strategy], "Controller: not a strategy");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Controller: caller not governance");
        _;
    }

    // ----------------------
    // Admin Functions
    // ----------------------
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault zero");
        vault = _vault;
        emit VaultChanged(_vault);
    }

    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "Governance zero");
        governance = _governance;
    }

    function proposeStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Strategy zero");
        require(!isStrategy[_strategy], "Already added");
        require(!blacklistedStrategies[_strategy], "Strategy blacklisted");
        pendingStrategies[_strategy] = block.timestamp;
        emit StrategyProposed(_strategy, block.timestamp);
    }

    function addStrategy(address _strategy) external onlyGovernance {
        require(msg.sender == address(timelock), "Controller: caller not timelock");
        require(_strategy != address(0), "Strategy zero");
        require(!isStrategy[_strategy], "Already added");
        require(!blacklistedStrategies[_strategy], "Strategy blacklisted");
        require(pendingStrategies[_strategy] != 0, "Strategy not proposed");
        require(block.timestamp >= pendingStrategies[_strategy] + TIMELOCK_DURATION, "Timelock not elapsed");

        // Verify BaseStrategy interface compliance
        BaseStrategy strategy = BaseStrategy(_strategy);
        require(address(strategy) == _strategy, "Invalid strategy");

        isStrategy[_strategy] = true;
        strategies.push(_strategy);
        delete pendingStrategies[_strategy];
        emit StrategyAdded(_strategy);
    }

    function removeStrategy(address _strategy) external onlyOwner onlyManagedStrategy(_strategy) {
        // Must withdraw funds first
        require(strategyTokenBalance(_strategy) == 0, "Withdraw funds first");
        isStrategy[_strategy] = false;
        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; ++i) {
            if (strategies[i] == _strategy) {
                strategies[i] = strategies[len - 1];
                strategies.pop();
                break;
            }
        }
        emit StrategyRemoved(_strategy);
    }

    function blacklistStrategy(address _strategy) external onlyOwner {
        blacklistedStrategies[_strategy] = true;
        emit StrategyBlacklisted(_strategy);
    }

    function pause() external onlyOwner {
        _pause();
        emit ControllerPaused();
    }

    function unpause() external onlyOwner {
        _unpause();
        emit ControllerUnpaused();
    }

    // ----------------------
    // Vault <-> Strategy Flow
    // ----------------------
    function depositFromVault(address _strategy, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        onlyVault
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");

        token.safeTransferFrom(vault, address(this), _amount);
        token.safeIncreaseAllowance(_strategy, _amount);

        BaseStrategy(_strategy).deposit(_amount);

        emit FundsAllocated(_strategy, _amount);
    }

    // return from Controller to Vault
    function returnFundsToVault(address _strategy, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        onlyVault
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");

        BaseStrategy(_strategy).withdraw(_amount);

        token.safeTransfer(vault, _amount);
        emit FundsWithdrawn(_strategy, _amount);
    }

    function emergencyWithdrawFromStrategy(address _strategy, uint256 _amount)
        external
        nonReentrant
        onlyOwner
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");

        BaseStrategy(_strategy).withdraw(_amount);

        token.safeTransfer(vault, _amount);
        emit EmergencyWithdraw(_strategy, _amount);
    }

    // ----------------------
    // Strategy Utilities
    // ----------------------
    // Call harvest on a strategy to realize gains/losses
    function harvestStrategy(address _strategy) external onlyOwner onlyManagedStrategy(_strategy) {
        BaseStrategy(_strategy).harvest();
    }

    // Call tend on a strategy to reinvest yields
    function tendStrategy(address _strategy) external onlyOwner onlyManagedStrategy(_strategy) {
        BaseStrategy(_strategy).tend();
    }

    // estimate total assets managed by a strategy
    function estimatedStrategyAssets(address _strategy) external view onlyManagedStrategy(_strategy) returns (uint256) {
        return BaseStrategy(_strategy).estimatedTotalAssets();
    }

    // get the token balance held by a strategy
    function strategyTokenBalance(address _strategy) public view onlyManagedStrategy(_strategy) returns (uint256) {
        return token.balanceOf(_strategy);
    }

    // strategy count and address getters
    function getStrategyCount() external view returns (uint256) {
        return strategies.length;
    }

    // Get strategy address by index
    function getStrategyAddress(uint256 index) external view returns (address) {
        require(index < strategies.length, "Index OOB");
        return strategies[index];
    }
}
