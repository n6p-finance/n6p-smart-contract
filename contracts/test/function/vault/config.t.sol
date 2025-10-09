// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/core/DeFi/VaultDeFi.sol";

contract MockToken is IERC20, IDetailedERC20 {
    string public name = "Test Token";
    string public symbol = "TEST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "insufficient allowance");
        allowance[sender][msg.sender] = currentAllowance - amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockStrategy {
    address public want;
    address public vault;
    bool public isActive = true;
    bool public emergencyExit = false;
    uint256 public delegatedAssets = 0;

    constructor(address _vault, address _token) {
        vault = _vault;
        want = _token;
    }

    function estimatedTotalAssets() external view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function withdraw(uint256 _amount) external returns (uint256 loss) {
        uint256 balance = IERC20(want).balanceOf(address(this));
        loss = _amount > balance ? _amount - balance : 0;
        uint256 toTransfer = _amount > balance ? balance : _amount;
        IERC20(want).transfer(vault, toTransfer);
        return loss;
    }

    function migrate(address _newStrategy) external {
        // Mock migration
    }

    function setEmergencyExit(bool _exit) external {
        emergencyExit = _exit;
    }
}

contract ConfigTest is Test {
    Vault public vault;
    MockToken public token;
    address public governance;
    address public management;
    address public guardian;
    address public rewards;
    address public user;

    function setUp() public {
        governance = makeAddr("governance");
        management = makeAddr("management");
        guardian = makeAddr("guardian");
        rewards = makeAddr("rewards");
        user = makeAddr("user");

        token = new MockToken();
        vault = new Vault();

        // Initialize vault
        vault.initialize(
            address(token),
            governance,
            rewards,
            "",
            "",
            guardian,
            management
        );
    }

    function test_vault_deployment() public {
        console.log("Testing vault deployment...");
        
        // Addresses
        assertEq(vault.governance(), governance, "Governance address mismatch");
        assertEq(vault.management(), management, "Management address mismatch");
        assertEq(vault.guardian(), guardian, "Guardian address mismatch");
        assertEq(vault.rewards(), rewards, "Rewards address mismatch");
        assertEq(address(vault.token()), address(token), "Token address mismatch");
        
        // UI Stuff
        assertEq(vault.name(), "TEST nVault", "Name mismatch");
        assertEq(vault.symbol(), "nVTEST", "Symbol mismatch");
        assertEq(vault.decimals(), 18, "Decimals mismatch");
        assertEq(vault.apiVersion(), "0.4.6", "API version mismatch");

        // Initial state
        assertEq(vault.debtRatio(), 0, "Initial debt ratio should be 0");
        assertEq(vault.depositLimit(), 0, "Initial deposit limit should be 0");
        assertEq(vault.totalAssets(), 0, "Initial total assets should be 0");
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Initial price per share should be 1");

        console.log("Vault deployment test passed");
    }

    function test_vault_name_symbol_override() public {
        console.log("Testing vault name/symbol override...");
        
        Vault newVault = new Vault();
        newVault.initialize(
            address(token),
            governance,
            rewards,
            "Custom Vault",
            "CUSTOM",
            guardian,
            management
        );

        assertEq(newVault.name(), "Custom Vault", "Custom name not set");
        assertEq(newVault.symbol(), "CUSTOM", "Custom symbol not set");
        
        console.log("Vault name/symbol override test passed");
    }

    function test_vault_reinitialization() public {
        console.log("Testing vault reinitialization protection...");
        
        vm.expectRevert("initialized");
        vault.initialize(
            address(token),
            governance,
            rewards,
            "",
            "",
            guardian,
            management
        );
        
        console.log("Vault reinitialization protection test passed");
    }

    function test_vault_setParams_governance() public {
        console.log("Testing governance parameter setting...");
        
        // Test setName
        vm.prank(governance);
        vault.setName("New Vault Name");
        assertEq(vault.name(), "New Vault Name", "Name not updated by governance");

        // Test setSymbol
        vm.prank(governance);
        vault.setSymbol("NEWSYM");
        assertEq(vault.symbol(), "NEWSYM", "Symbol not updated by governance");

        // Test setDepositLimit
        vm.prank(governance);
        vault.setDepositLimit(1000 ether);
        assertEq(vault.depositLimit(), 1000 ether, "Deposit limit not updated by governance");

        // Test setPerformanceFee
        vm.prank(governance);
        vault.setPerformanceFee(500); // 5%
        assertEq(vault.performanceFee(), 500, "Performance fee not updated by governance");

        // Test setManagementFee
        vm.prank(governance);
        vault.setManagementFee(100); // 1%
        assertEq(vault.managementFee(), 100, "Management fee not updated by governance");

        // Test setLockedProfitDegradation
        vm.prank(governance);
        vault.setLockedProfitDegradation(1e17); // 10% degradation
        assertEq(vault.lockedProfitDegradation(), 1e17, "Locked profit degradation not updated");

        console.log("Governance parameter setting test passed");
    }

    function test_vault_setParams_access_control() public {
        console.log("Testing access control for parameter setting...");
        
        // Random user cannot set parameters
        vm.prank(user);
        vm.expectRevert(bytes("gov"));
        vault.setName("Hacked Name");

        // Guardian cannot set most parameters
        vm.prank(guardian);
        vm.expectRevert(bytes("gov"));
        vault.setName("Guardian Name");

        // Management cannot set governance-only parameters
        vm.prank(management);
        vm.expectRevert(bytes("gov"));
        vault.setName("Management Name");

        console.log("Access control test passed");
    }

    function test_vault_setGovernance() public {
        console.log("Testing governance transfer...");
        
        address newGovernance = makeAddr("newGovernance");
        
        // Only current governance can set new governance
        vm.prank(governance);
        vault.setGovernance(newGovernance);
        assertEq(vault.pendingGovernance(), newGovernance, "Pending governance not set");
        
        // Current governance still in place until accepted
        assertEq(vault.governance(), governance, "Governance changed before acceptance");
        
        // Only pending governance can accept
        vm.prank(user);
        vm.expectRevert("not pending");
        vault.acceptGovernance();
        
        // New governance accepts
        vm.prank(newGovernance);
        vault.acceptGovernance();
        assertEq(vault.governance(), newGovernance, "Governance not transferred");
        
        console.log("Governance transfer test passed");
    }

    function test_vault_setEmergencyShutdown() public {
        console.log("Testing emergency shutdown...");
        
        // Guardian can activate emergency shutdown
        vm.prank(guardian);
        vault.setEmergencyShutdown(true);
        assertTrue(vault.emergencyShutdown(), "Emergency shutdown not activated by guardian");
        
        // Only governance can deactivate
        vm.prank(guardian);
        vm.expectRevert(bytes("gov"));
        vault.setEmergencyShutdown(false);
        
        // Governance can deactivate
        vm.prank(governance);
        vault.setEmergencyShutdown(false);
        assertFalse(vault.emergencyShutdown(), "Emergency shutdown not deactivated by governance");
        
        console.log("Emergency shutdown test passed");
    }

    function test_vault_setLockedProfitDegradation_range() public {
        console.log("Testing locked profit degradation range...");
        
        // Can set to 0
        vm.prank(governance);
        vault.setLockedProfitDegradation(0);
        assertEq(vault.lockedProfitDegradation(), 0, "Cannot set degradation to 0");
        
        // Can set to maximum
        vm.prank(governance);
        vault.setLockedProfitDegradation(vault.DEGRADATION_COEFFICIENT());
        assertEq(vault.lockedProfitDegradation(), vault.DEGRADATION_COEFFICIENT(), "Cannot set degradation to max");
        
        // Cannot exceed maximum
        vm.prank(governance);
        vm.expectRevert(bytes("deg"));
        vault.setLockedProfitDegradation(vault.DEGRADATION_COEFFICIENT() + 1);
        
        console.log("Locked profit degradation range test passed");
    }

    function test_vault_setRewards_validation() public {
        console.log("Testing rewards address validation...");
        
        // Cannot set to zero address
        vm.prank(governance);
        vm.expectRevert("rewards");
        vault.setRewards(address(0));
        
        // Cannot set to vault address
        vm.prank(governance);
        vm.expectRevert("rewards");
        vault.setRewards(address(vault));
        
        // Can set to valid address
        address newRewards = makeAddr("newRewards");
        vm.prank(governance);
        vault.setRewards(newRewards);
        assertEq(vault.rewards(), newRewards, "Rewards address not updated");
        
        console.log("Rewards address validation test passed");
    }
}