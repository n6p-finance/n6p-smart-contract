// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import "../interfaces/IStrategyAPI.sol";

/*
  TestController.sol - improved and aligned with TestVault.sol
  - Provides controller role that can manage multiple strategies and route funds
  - Vault can call depositFromVault(...) to have controller allocate funds into a chosen strategy
  - Vault can call returnFundsToVault(...) to retrieve funds from a chosen strategy back to vault
  - Admin (owner) can add/remove strategies and perform emergency actions
  - SafeERC20, ReentrancyGuard, Pausable, Ownable used for safety
  - Updated to include strategy verification methods
  - Modified to support multiple strategies by removing single-strategy assumption
*/
contract ControllerAPIYield is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice The vault contract that is allowed to interact (set by owner)
    address public vault;

    /// @notice Underlying token (immutable)
    IERC20 public immutable token;

    /// @notice List of managed strategies
    address[] public strategies;

    /// @notice Quick lookup: is address a managed strategy
    mapping(address => bool) public isStrategy;

    /// @notice Accounting: amount allocated to each strategy (bookkeeping)
    mapping(address => uint256) public strategyBalances;

    /// @notice Governance address for approving strategies
    address public governance;

    /// @notice Proposed strategies awaiting timelock approval to track
    mapping(address => uint256) public pendingStrategies; // strategy => timestamp

    /// @notice Blacklisted strategies to prevent re-adding
    mapping(address => bool) public blacklistedStrategies;

    /// @notice Timelock duration for strategy addition (in seconds)
    uint256 public constant TIMELOCK_DURATION = 1 days;

    /// @notice Timelock contract for strategy additions
    TimelockController public immutable timelock;

    /// --------------------
    /// Events (minimal & meaningful)
    /// --------------------
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

    /**
     * @param _token underlying token address (use same token as Vault)
     * @param _initialOwner owner address
     * @param _timelock address of the TimelockController contract
     * @dev Updated to set governance to initial owner and initialize timelock
     */
    constructor(address _token, address _initialOwner, address _timelock) Ownable(_initialOwner) {
        require(_token != address(0), "Token zero");
        require(_initialOwner != address(0), "Owner zero");
        require(_timelock != address(0), "Timelock zero");
        token = IERC20(_token);
        governance = _initialOwner;
        timelock = TimelockController(payable(_timelock));
    }

    // ---------------------
    // Modifiers
    // ---------------------

    /// Only callable by the vault contract
    modifier onlyVault() {
        require(msg.sender == vault, "Controller: caller not vault");
        _;
    }

    /// Strategy must be managed
    modifier onlyManagedStrategy(address _strategy) {
        require(isStrategy[_strategy], "Controller: not a strategy");
        _;
    }

    /// Only callable by governance
    modifier onlyGovernance() {
        require(msg.sender == governance, "Controller: caller not governance");
        _;
    }

    // ---------------------
    // Admin functions
    // ---------------------

    /**
     * @notice Set the vault address (owner only)
     */
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault zero");
        vault = _vault;
        emit VaultChanged(_vault);
    }

    /**
     * @notice Set the governance address (owner only)
     * @dev Added to allow changing governance (e.g., to a DAO or multisig)
     * @param _governance New governance address
     */
    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "Governance zero");
        governance = _governance;
    }

    /**
     * @notice Propose a new strategy for addition (owner only)
     * @dev Starts a timelock; governance must approve after delay
     * @param _strategy Address of the strategy to propose
     */
    function proposeStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Strategy zero");
        require(!isStrategy[_strategy], "Already added");
        require(!blacklistedStrategies[_strategy], "Strategy blacklisted");
        pendingStrategies[_strategy] = block.timestamp;
        emit StrategyProposed(_strategy, block.timestamp);
    }

    /**
     * @notice Add a proposed strategy to the whitelist after timelock (governance only)
     * @dev Verifies interface compliance and runtime behavior before adding
     * @param _strategy Address of the strategy to add
     */
    function addStrategy(address _strategy) external onlyGovernance {
        require(msg.sender == address(timelock), "Controller: caller not timelock");
        require(_strategy != address(0), "Strategy zero");
        require(!isStrategy[_strategy], "Already added");
        require(!blacklistedStrategies[_strategy], "Strategy blacklisted");
        require(pendingStrategies[_strategy] != 0, "Strategy not proposed");
        require(block.timestamp >= pendingStrategies[_strategy] + TIMELOCK_DURATION, "Timelock not elapsed");

        // Verify interface compliance and runtime behavior
        testStrategy(_strategy);

        isStrategy[_strategy] = true;
        strategies.push(_strategy);
        delete pendingStrategies[_strategy];
        emit StrategyAdded(_strategy);
    }

    /**
     * @notice Remove strategy from whitelist (owner only)
     * @dev This does not force withdrawing funds — owner should call emergencyWithdraw first if needed
     */
    function removeStrategy(address _strategy) external onlyOwner onlyManagedStrategy(_strategy) {
        require(strategyBalances[_strategy] == 0, "Withdraw funds first");
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

    /**
     * @notice Blacklist a strategy to prevent re-adding (owner only)
     * @dev Useful for known malicious or failed strategies
     * @param _strategy Address of the strategy to blacklist
     */
    function blacklistStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Strategy zero");
        blacklistedStrategies[_strategy] = true;
        emit StrategyBlacklisted(_strategy);
    }

    /**
     * @notice Pause controller actions (owner only)
     */
    function pause() external onlyOwner {
        _pause();
        emit ControllerPaused();
    }

    /**
     * @notice Unpause (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
        emit ControllerUnpaused();
    }

    /**
     * @notice Test a strategy’s behavior before adding to whitelist
     * @dev Simulates deposit, balance check, and withdrawal to ensure correctness
     * @param _strategy Address of the strategy to test
     */
    function testStrategy(address _strategy) internal {
        // Ensure strategy implements IStrategy interface
        IStrategy strategy = IStrategy(_strategy);
        require(address(strategy) == _strategy, "Invalid strategy interface");

        // Test deposit and balance
        uint256 testAmount = 1 ether; // Small test amount
        uint256 initialBalance = token.balanceOf(address(this));
        require(token.balanceOf(address(this)) >= testAmount, "Insufficient controller balance");
        uint256 currentAllowance = token.allowance(address(this), _strategy);
        if (currentAllowance != 0) {
            token.approve(_strategy, 0);
        }
        token.approve(_strategy, testAmount);
        try strategy.deposit(testAmount) {
            uint256 balanceAfterDeposit = strategy.getBalance(address(this));
            require(balanceAfterDeposit >= testAmount, "Strategy balance mismatch after deposit");
        } catch {
            revert("Strategy deposit failed");
        }

        // Test withdrawal
        try strategy.withdraw(testAmount) {
            uint256 balanceAfterWithdraw = strategy.getBalance(address(this));
            require(balanceAfterWithdraw == 0, "Strategy balance mismatch after withdraw");
            require(token.balanceOf(address(this)) >= initialBalance, "Funds not returned");
        } catch {
            revert("Strategy withdraw failed");
        }

        // Test APY and yield generation
        try strategy.apy() returns (uint256) {} catch {
            revert("Strategy APY failed");
        }
        try strategy.generateYield() {} catch {
            revert("Strategy yield generation failed");
        }
    }

    // ---------------------
    // Vault <-> Controller flow
    // ---------------------
    //
    // Flow design decision:
    // - Vault will call `depositFromVault(strategy, amount)` when it wants to route funds through controller.
    // - Vault must approve controller to spend `amount` on its behalf BEFORE calling.
    // - Controller transfers tokens from vault -> controller -> approves strategy -> deposits.
    // - When vault requests funds back, it calls `returnFundsToVault(strategy, amount)`.
    // - Controller withdraws from strategy and transfers tokens back to vault.
    //

    /**
     * @notice Called by Vault to allocate funds into a strategy.
     * @dev Updated to include pre- and post-deposit balance checks
     * @param _strategy address of the whitelisted strategy
     * @param _amount amount of underlying to allocate
     *
     * Requirements:
     * - Vault must have approved the controller to pull `_amount`
     * - `_strategy` must be whitelisted
     */
    function depositFromVault(address _strategy, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        onlyVault
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");

        // Pre-deposit balance check
        uint256 balanceBefore = IStrategy(_strategy).getBalance(address(this));

        // Transfer _amount from vault to controller
        token.safeTransferFrom(vault, address(this), _amount);

        // Approve strategy to pull the tokens
        uint256 currentAllowance = token.allowance(address(this), _strategy);
        if (currentAllowance != 0) {
            token.approve(_strategy, 0);
        }
        token.approve(_strategy, _amount);

        // Deposit into strategy
        IStrategy(_strategy).deposit(_amount);

        // Post-deposit balance check
        uint256 balanceAfter = IStrategy(_strategy).getBalance(address(this));
        require(balanceAfter >= balanceBefore + _amount, "Deposit: strategy balance mismatch");

        // Update bookkeeping
        strategyBalances[_strategy] += _amount;

        emit FundsAllocated(_strategy, _amount);
    }

    /**
     * @notice Called by Vault to request funds returned from a strategy back to the vault.
     * @param _strategy address of the whitelisted strategy
     * @param _amount amount of underlying to return to vault
     *
     * Requirements:
     * - Only vault can call
     * - Controller will call strategy.withdraw(_amount)
     */
    function returnFundsToVault(address _strategy, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
        onlyVault
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");
        require(strategyBalances[_strategy] >= _amount, "Insufficient allocated balance");

        // Withdraw from strategy
        IStrategy(_strategy).withdraw(_amount);

        // Update bookkeeping
        strategyBalances[_strategy] -= _amount;

        // Transfer tokens back to vault
        token.safeTransfer(vault, _amount);

        emit FundsWithdrawn(_strategy, _amount);
    }

    /**
     * @notice Emergency withdraw from a specific strategy (owner only)
     * @dev Pull funds immediately and forward to vault
     */
    function emergencyWithdrawFromStrategy(address _strategy, uint256 _amount)
        external
        nonReentrant
        onlyOwner
        onlyManagedStrategy(_strategy)
    {
        require(_amount > 0, "Amount zero");

        // Withdraw requested amount from strategy to controller
        IStrategy(_strategy).withdraw(_amount);

        // Update bookkeeping (saturating)
        if (strategyBalances[_strategy] >= _amount) {
            strategyBalances[_strategy] -= _amount;
        } else {
            strategyBalances[_strategy] = 0;
        }

        // Forward funds to vault
        token.safeTransfer(vault, _amount);

        emit EmergencyWithdraw(_strategy, _amount);
    }

    // ---------------------
    // View helpers
    // ---------------------

    /**
     * @notice Number of strategies managed
     */
    function getStrategyCount() external view returns (uint256) {
        return strategies.length;
    }

    /**
     * @notice Returns (strategyAddress, allocatedAmount)
     */
    function getStrategyInfo(uint256 index) external view returns (address, uint256) {
        require(index < strategies.length, "Index OOB");
        address s = strategies[index];
        return (s, strategyBalances[s]);
    }

    /**
     * @notice Controller token balance
     */
    function getControllerBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Get reported strategy balance for an account (proxy to strategy)
     * @dev strategy.getBalance(account) should exist on IStrategy
     */
    function getStrategyBalance(address _strategy, address account) external view onlyManagedStrategy(_strategy) returns (uint256) {
        return IStrategy(_strategy).getBalance(account);
    }

    /**
     * @notice Proxy to strategy apy
     */
    function getStrategyAPY(address _strategy) external view onlyManagedStrategy(_strategy) returns (uint256) {
        return IStrategy(_strategy).apy();
    }

    /**
     * @notice Trigger yield generation on specific strategy (owner-controlled)
     */
    function triggerYieldGeneration(address _strategy) external onlyOwner onlyManagedStrategy(_strategy) {
        IStrategy(_strategy).generateYield();
    }
}