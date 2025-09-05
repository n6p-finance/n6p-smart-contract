// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/core/TestVault.sol";
import "../../src/core/TestController.sol"; // Added import for TestController
import "../../src/interfaces/IStrategy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title MockERC20
/// @notice A minimal ERC20 token implementation for testing purposes.
/// @dev Implements IERC20 with basic functionality and console logging for debugging.
contract MockERC20 is IERC20 {
    string public name = "MockToken";
    string public symbol = "MCK";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice Mints new tokens to a specified address.
    /// @dev Increases the recipient's balance and total supply, emitting a Transfer event.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint (in wei).
    function mint(address to, uint256 amount) external {
        console.log("MockERC20.mint: Minting amount");
        console.logUint(amount);
        console.log("MockERC20.mint: to address");
        console.logAddress(to);
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
        console.log("MockERC20.mint: New balanceOf[to]");
        console.logUint(balanceOf[to]);
        console.log("MockERC20.mint: totalSupply");
        console.logUint(totalSupply);
    }

    /// @notice Transfers tokens from the caller to a specified address.
    /// @dev Requires sufficient balance, updates balances, and emits a Transfer event.
    /// @param to The recipient address.
    /// @param amount The amount of tokens to transfer (in wei).
    /// @return bool True if the transfer succeeds.
    function transfer(address to, uint256 amount) external override returns (bool) {
        console.log("MockERC20.transfer: Transferring amount");
        console.logUint(amount);
        console.log("MockERC20.transfer: from address");
        console.logAddress(msg.sender);
        console.log("MockERC20.transfer: to address");
        console.logAddress(to);
        require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        console.log("MockERC20.transfer: New balanceOf[msg.sender]");
        console.logUint(balanceOf[msg.sender]);
        console.log("MockERC20.transfer: balanceOf[to]");
        console.logUint(balanceOf[to]);
        return true;
    }

    /// @notice Approves a spender to transfer tokens on behalf of the caller.
    /// @dev Sets the allowance and emits an Approval event.
    /// @param spender The address allowed to spend tokens.
    /// @param amount The amount of tokens approved (in wei).
    /// @return bool True if the approval succeeds.
    function approve(address spender, uint256 amount) external override returns (bool) {
        console.log("MockERC20.approve: Approving amount");
        console.logUint(amount);
        console.log("MockERC20.approve: for address");
        console.logAddress(spender);
        console.log("MockERC20.approve: by address");
        console.logAddress(msg.sender);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        console.log("MockERC20.approve: New allowance");
        console.logUint(allowance[msg.sender][spender]);
        return true;
    }

    /// @notice Transfers tokens from one address to another on behalf of the sender.
    /// @dev Requires sufficient balance and allowance, updates balances and allowance, and emits a Transfer event.
    /// @param from The address to transfer tokens from.
    /// @param to The address to transfer tokens to.
    /// @param amount The amount of tokens to transfer (in wei).
    /// @return bool True if the transfer succeeds.
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        console.log("MockERC20.transferFrom: Transferring amount");
        console.logUint(amount);
        console.log("MockERC20.transferFrom: from address");
        console.logAddress(from);
        console.log("MockERC20.transferFrom: to address");
        console.logAddress(to);
        console.log("MockERC20.transferFrom: by address");
        console.logAddress(msg.sender);
        require(balanceOf[from] >= amount, "ERC20: insufficient balance");
        require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        console.log("MockERC20.transferFrom: New balanceOf[from]");
        console.logUint(balanceOf[from]);
        console.log("MockERC20.transferFrom: balanceOf[to]");
        console.logUint(balanceOf[to]);
        console.log("MockERC20.transferFrom: allowance");
        console.logUint(allowance[from][msg.sender]);
        return true;
    }
}

/// @title MockStrategy
/// @notice A mock strategy contract for testing vault interactions.
/// @dev Implements IStrategy with deposit, withdraw, and yield generation functionality.
contract MockStrategy is IStrategy {
    MockERC20 public token;
    mapping(address => uint256) public accounted;

    /// @notice Initializes the strategy with a token address.
    /// @param _token The ERC20 token to be used by the strategy.
    constructor(MockERC20 _token) {
        console.log("MockStrategy.constructor: Initializing with token");
        console.logAddress(address(_token));
        token = _token;
    }

    /// @notice Deposits tokens into the strategy.
    /// @dev Transfers tokens from the caller to the strategy.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        console.log("MockStrategy.deposit: Depositing amount");
        console.logUint(amount);
        console.log("MockStrategy.deposit: from address");
        console.logAddress(msg.sender);
        require(token.transferFrom(msg.sender, address(this), amount), "MockStrategy: transferFrom failed");
        console.log("MockStrategy.deposit: Successfully deposited, strategy balance");
        console.logUint(token.balanceOf(address(this)));
    }

    /// @notice Withdraws tokens from the strategy.
    /// @dev Transfers tokens from the strategy to the caller.
    /// @param amount The amount of tokens to withdraw (in wei).
    function withdraw(uint256 amount) external override {
        console.log("MockStrategy.withdraw: Withdrawing amount");
        console.logUint(amount);
        console.log("MockStrategy.withdraw: to address");
        console.logAddress(msg.sender);
        require(token.transfer(msg.sender, amount), "MockStrategy: transfer failed");
        console.log("MockStrategy.withdraw: Successfully withdrawn, strategy balance");
        console.logUint(token.balanceOf(address(this)));
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Ignores the account parameter for simplicity.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        console.log("MockStrategy.getBalance: Strategy balance");
        console.logUint(balance);
        return balance;
    }

    /// @notice Generates yield by minting additional tokens.
    /// @dev Mints 10% of the current balance as yield.
    function generateYield() external override {
        console.log("MockStrategy.generateYield: Generating yield");
        uint256 base = token.balanceOf(address(this));
        uint256 yieldAmount = base / 10;
        console.log("MockStrategy.generateYield: Base");
        console.logUint(base);
        console.log("MockStrategy.generateYield: Yield amount");
        console.logUint(yieldAmount);
        if (yieldAmount > 0) {
            token.mint(address(this), yieldAmount);
            console.log("MockStrategy.generateYield: Yield minted, new balance");
            console.logUint(token.balanceOf(address(this)));
        }
    }

    /// @notice Returns a dummy APY value.
    /// @dev Returns a fixed value of 1000 for testing.
    /// @return A dummy APY value (1000).
    function apy() external view override returns (uint256) {
        console.log("MockStrategy.apy: Returning dummy APY 1000");
        return 1000;
    }
}

/// @title MaliciousStrategy
/// @notice A malicious strategy that steals deposited tokens by transferring them to an attacker.
/// @dev Used to test vault behavior with an untrusted strategy.
contract MaliciousStrategy is IStrategy {
    MockERC20 public token;
    address public attacker;

    /// @notice Initializes the strategy with a token and attacker address.
    /// @param _token The ERC20 token to be used by the strategy.
    /// @param _attacker The address to receive stolen tokens.
    constructor(MockERC20 _token, address _attacker) {
        console.log("MaliciousStrategy.constructor: Initializing with token");
        console.logAddress(address(_token));
        console.log("MaliciousStrategy.constructor: attacker");
        console.logAddress(_attacker);
        token = _token;
        attacker = _attacker;
    }

    /// @notice Deposits tokens and immediately transfers them to the attacker.
    /// @dev Steals all deposited tokens, leaving the strategy empty.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        console.log("MaliciousStrategy.deposit: Depositing amount");
        console.logUint(amount);
        console.log("MaliciousStrategy.deposit: from address");
        console.logAddress(msg.sender);
        require(token.transferFrom(msg.sender, address(this), amount), "MaliciousStrategy: transferFrom failed");
        console.log("MaliciousStrategy.deposit: Transferring amount");
        console.logUint(amount);
        console.log("MaliciousStrategy.deposit: to attacker");
        console.logAddress(attacker);
        require(token.transfer(attacker, amount), "MaliciousStrategy: transfer failed");
        console.log("MaliciousStrategy.deposit: Post-deposit strategy balance");
        console.logUint(token.balanceOf(address(this)));
    }

    /// @notice Disables withdrawals by reverting.
    /// @dev Always reverts to simulate a malicious strategy.
    function withdraw(uint256 /*amount*/) external pure override {
        console.log("MaliciousStrategy.withdraw: Withdraw disabled, reverting");
        revert("MaliciousStrategy: withdraw disabled");
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Typically returns 0 due to funds being stolen.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        console.log("MaliciousStrategy.getBalance: Strategy balance");
        console.logUint(balance);
        return balance;
    }

    /// @notice No-op function for yield generation.
    /// @dev Does nothing, as the strategy is malicious.
    function generateYield() external override {
        console.log("MaliciousStrategy.generateYield: No-op");
    }

    /// @notice Returns a zero APY.
    /// @dev Returns 0 to reflect the malicious nature.
    /// @return A zero APY value.
    function apy() external view override returns (uint256) {
        console.log("MaliciousStrategy.apy: Returning 0");
        return 0;
    }
}

/// @title BrokenStrategy
/// @notice A strategy that allows deposits but reverts on withdrawals.
/// @dev Used to test vault behavior when withdrawals are blocked.
contract BrokenStrategy is IStrategy {
    MockERC20 public token;

    /// @notice Initializes the strategy with a token address.
    /// @param _token The ERC20 token to be used by the strategy.
    constructor(MockERC20 _token) {
        console.log("BrokenStrategy.constructor: Initializing with token");
        console.logAddress(address(_token));
        token = _token;
    }

    /// @notice Deposits tokens into the strategy.
    /// @dev Transfers tokens from the caller to the strategy.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        console.log("BrokenStrategy.deposit: Depositing amount");
        console.logUint(amount);
        console.log("BrokenStrategy.deposit: from address");
        console.logAddress(msg.sender);
        require(token.transferFrom(msg.sender, address(this), amount), "BrokenStrategy: transferFrom failed");
        console.log("BrokenStrategy.deposit: Successfully deposited, strategy balance");
        console.logUint(token.balanceOf(address(this)));
    }

    /// @notice Reverts on withdrawal attempts.
    /// @dev Always reverts to simulate a broken strategy.
    function withdraw(uint256 /*amount*/) external pure override {
        console.log("BrokenStrategy.withdraw: Withdraw called, reverting");
        revert("BrokenStrategy: cannot withdraw");
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Returns the current balance, typically non-zero due to trapped funds.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        console.log("BrokenStrategy.getBalance: Strategy balance");
        console.logUint(balance);
        return balance;
    }

    /// @notice No-op function for yield generation.
    /// @dev Does nothing, as the strategy is broken.
    function generateYield() external override {
        console.log("BrokenStrategy.generateYield: No-op");
    }

    /// @notice Returns a zero APY.
    /// @dev Returns 0 to reflect the broken nature.
    /// @return A zero APY value.
    function apy() external view override returns (uint256) {
        console.log("BrokenStrategy.apy: Returning 0");
        return 0;
    }
}

/// @title TestVaultTest
/// @notice Test suite for the TestVault contract, verifying deposit, withdrawal, and emergency functionality.
/// @dev Uses MockERC20, MockStrategy, MaliciousStrategy, and BrokenStrategy to simulate various scenarios.
/// @dev Updated to include TestController in setup and tests.
contract TestVaultTest is Test {
    MockERC20 token;
    MockStrategy strategy;
    TestController controller;
    TestVault vault;

    address owner = address(0xABCD);
    address alice = address(0xA11ce);
    address bob = address(0xB0b);
    address attacker = address(0xDEAD);

    /// @notice Sets up the test environment by deploying contracts and minting tokens.
    /// @dev Deploys MockERC20, MockStrategy, TestController, and TestVault, and mints 1000 ether to test accounts.
    /// @dev Updated to deploy TestController and set it in TestVault.
    function setUp() public {
        console.log("TestVaultTest.setUp: Deploying contracts");
        token = new MockERC20();
        console.log("TestVaultTest.setUp: MockERC20 deployed at");
        console.logAddress(address(token));
        token.mint(alice, 1_000 ether);
        token.mint(bob, 1_000 ether);
        token.mint(attacker, 1_000 ether);
        console.log("TestVaultTest.setUp: Minted 1000 ether to alice, bob, attacker");

        strategy = new MockStrategy(token);
        console.log("TestVaultTest.setUp: MockStrategy deployed at");
        console.logAddress(address(strategy));
        controller = new TestController(address(token), owner);
        console.log("TestVaultTest.setUp: TestController deployed at");
        console.logAddress(address(controller));
        vm.prank(owner);
        controller.addStrategy(address(strategy));
        console.log("TestVaultTest.setUp: Strategy added to controller");
        vm.prank(owner);
        vault = new TestVault(token, controller);
        console.log("TestVaultTest.setUp: TestVault deployed at");
        console.logAddress(address(vault));
        console.log("TestVaultTest.setUp: by owner");
        console.logAddress(owner);
    }

    /// @notice Deposits tokens as a specified user, assuming prior approval.
    /// @dev Approves and deposits tokens into the vault, logging shares issued.
    /// @param user The address to deposit as.
    /// @param amount The amount of tokens to deposit (in wei).
    function _depositAs(address user, uint256 amount) internal {
        console.log("TestVaultTest._depositAs: Depositing amount");
        console.logUint(amount);
        console.log("TestVaultTest._depositAs: as address");
        console.logAddress(user);
        vm.startPrank(user);
        token.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();
        console.log("TestVaultTest._depositAs: Deposit complete, user shares");
        console.logUint(vault.shares(user));
    }

    /// @notice Approves and deposits tokens as a specified user.
    /// @dev Handles both approval and deposit in a single function.
    /// @param user The address to deposit as.
    /// @param amount The amount of tokens to deposit (in wei).
    function _directApproveAndDeposit(address user, uint256 amount) internal {
        console.log("TestVaultTest._directApproveAndDeposit: Approving and depositing amount");
        console.logUint(amount);
        console.log("TestVaultTest._directApproveAndDeposit: as address");
        console.logAddress(user);
        vm.prank(user);
        token.approve(address(vault), amount);
        vm.prank(user);
        vault.deposit(amount);
        console.log("TestVaultTest._directApproveAndDeposit: Deposit complete, user shares");
        console.logUint(vault.shares(user));
    }

    /// @notice Tests a malicious strategy that steals user funds.
    /// @dev Verifies that a malicious strategy can steal the first deposit, but the vault prevents further deposits due to balance validation.
    /// @dev Suggests future vaults implement strategy vetting and pre-deposit checks to prevent initial losses.
    function test_maliciousStrategy_steals_funds_users_loss() public {
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Starting test");
        MaliciousStrategy mal = new MaliciousStrategy(token, attacker);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: MaliciousStrategy deployed at");
        console.logAddress(address(mal));
        vm.prank(owner);
        TestController malController = new TestController(address(token), owner);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Malicious controller deployed at");
        console.logAddress(address(malController));
        vm.prank(owner);
        malController.addStrategy(address(mal));
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Malicious strategy added to controller");
        vm.prank(owner);
        TestVault malVault = new TestVault(token, malController);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Malicious vault deployed at");
        console.logAddress(address(malVault));

        vm.prank(alice);
        token.approve(address(malVault), 100 ether);
        vm.prank(bob);
        token.approve(address(malVault), 200 ether);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Alice and Bob approved tokens");

        vm.prank(alice);
        malVault.deposit(100 ether);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Alice deposited 100 ether");
        assertEq(token.balanceOf(address(mal)), 0, "Malicious strategy balance not zero");
        assertEq(token.balanceOf(attacker), 1100 ether, "Attacker balance incorrect");
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Malicious strategy balance");
        console.logUint(token.balanceOf(address(mal)));
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Attacker balance");
        console.logUint(token.balanceOf(attacker));

        vm.prank(bob);
        vm.expectRevert(bytes("Deposit: invalid pool balance"));
        malVault.deposit(200 ether);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Bob deposit attempt reverted as expected");

        uint256 pps = malVault.getPricePerShare();
        assertEq(pps, 0, "Price per share incorrect");
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Price per share");
        console.logUint(pps);

        vm.prank(alice);
        vm.expectRevert(bytes("Withdraw: empty pool"));
        malVault.withdraw(10 ether);
        console.log("TestVaultTest.test_maliciousStrategy_steals_funds_users_loss: Alice withdraw attempt reverted");
    }
}