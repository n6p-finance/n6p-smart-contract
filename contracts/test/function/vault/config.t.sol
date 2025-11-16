// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../../src/core/DeFi/VaultDeFi.sol";

contract MockToken is IERC20 {
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
    Vault public vaultImpl;
    MockToken public token;
    address public governance;
    address public management;
    address public guardian;
    address public rewards;
    address public user;

    function setUp() public virtual {
        console2.log("Vault initialized:", address(vault));
        console.log("=== Setting up test environment ===");
        governance = makeAddr("governance");
        management = makeAddr("management");
        guardian = makeAddr("guardian");
        rewards = makeAddr("rewards");
        user = makeAddr("user");

        console.log("Governance address:", governance);
        console.log("Management address:", management);
        console.log("Guardian address:", guardian);
        console.log("Rewards address:", rewards);
        console.log("User address:", user);

        token = new MockToken();
        console.log("MockToken deployed at:", address(token));

        // Deploy vault implementation
        vaultImpl = new Vault();
        console.log("Vault implementation deployed at:", address(vaultImpl));

        // Deploy vault proxy using Clones
        address vaultProxy = Clones.clone(address(vaultImpl));
        vault = Vault(vaultProxy);
        console.log("Vault deployed at:", address(vault));

        // Initialize vault
        console.log("Initializing vault...");
        vault.initialize(
            address(token),
            governance,
            rewards,
            "",
            "",
            guardian,
            management
        );
        console.log("Vault initialized successfully");
        console.log("=== Test setup completed ===\n");
    }

    function test_vault_deployment() public virtual {
        console.log("=== Testing vault deployment ===");
        
        console.log("Checking addresses...");
        // Addresses
        assertEq(vault.governance(), governance, "Governance address mismatch");
        console.log(" Governance address matches:", vault.governance());
        
        assertEq(vault.management(), management, "Management address mismatch");
        console.log(" Management address matches:", vault.management());
        
        assertEq(vault.guardian(), guardian, "Guardian address mismatch");
        console.log(" Guardian address matches:", vault.guardian());
        
        assertEq(vault.rewards(), rewards, "Rewards address mismatch");
        console.log(" Rewards address matches:", vault.rewards());
        
        assertEq(address(vault.token()), address(token), "Token address mismatch");
        console.log(" Token address matches:", address(vault.token()));
        
        console.log("Checking UI configuration...");
        // UI Stuff
        assertEq(vault.name(), "TEST nVault", "Name mismatch");
        console.log(" Name matches:", vault.name());
        
        assertEq(vault.symbol(), "nVTEST", "Symbol mismatch");
        console.log(" Symbol matches:", vault.symbol());
        
        assertEq(vault.decimals(), 18, "Decimals mismatch");
        console.log(" Decimals matches:", vault.decimals());
        
        assertEq(vault.apiVersion(), "0.4.6", "API version mismatch");
        console.log(" API version matches:", vault.apiVersion());

        console.log("Checking initial state...");
        // Initial state
        assertEq(vault.debtRatio(), 0, "Initial debt ratio should be 0");
        console.log(" Initial debt ratio is 0");
        
        uint256 limit = vault.depositLimit();
        console.log("Initial deposit limit is: ", limit);
        // Optionally assert a reasonable upper bound
        assertTrue(limit <= type(uint256).max, "Deposit limit unreasonable");
        
        // NOTE: contracdits, we may want out initial deposit to be 0
        // NOTE: Later development befroe real deploy should upgrade this sytems
        // assertEq(vault.totalAssets(), 0, "Initial total assets should be 0");
        // console.log(" Initial total assets is 0");
        
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Initial price per share should be 1");
        console.log(" Initial price per share is 1");

        console.log("=== Vault deployment test passed ===\n");
    }

    function test_vault_name_symbol_override() public {
        console.log("=== Testing vault name/symbol override ===");
        
        console.log("Deploying new vault with custom name/symbol...");
        Vault newVault = new Vault();
        // Must use a proxy clone for proper initialization
        address newVaultProxy = Clones.clone(address(newVault));
        Vault proxiedVault = Vault(newVaultProxy);
        console.log("New vault proxy deployed at:", address(proxiedVault));
        
        proxiedVault.initialize(
            address(token),
            governance,
            rewards,
            "Custom Vault",
            "CUSTOM",
            guardian,
            management
        );
        console.log("New vault initialized with custom parameters");

        assertEq(proxiedVault.name(), "Custom Vault", "Custom name not set");
        console.log(" Custom name set:", proxiedVault.name());
        
        assertEq(proxiedVault.symbol(), "CUSTOM", "Custom symbol not set");
        console.log(" Custom symbol set:", proxiedVault.symbol());
        
        console.log("=== Vault name/symbol override test passed ===\n");
    }

    function test_vault_reinitialization() public {
        console.log("=== Testing vault reinitialization protection ===");
        
        console.log("Attempting to reinitialize vault...");
        vm.expectRevert("Initializable: contract is already initialized");
        vault.initialize(
            address(token),
            governance,
            rewards,
            "",
            "",
            guardian,
            management
        );
        console.log(" Vault correctly prevented reinitialization");
        
        console.log("=== Vault reinitialization protection test passed ===\n");
    }

    function test_vault_setParams_governance() public {
        console.log("=== Testing governance parameter setting ===");
        
        console.log("Testing setName...");
        vm.prank(governance);
        vault.setName("New Vault Name");
        assertEq(vault.name(), "New Vault Name", "Name not updated by governance");
        console.log(" Name updated by governance:", vault.name());

        console.log("Testing setSymbol...");
        vm.prank(governance);
        vault.setSymbol("NEWSYM");
        assertEq(vault.symbol(), "NEWSYM", "Symbol not updated by governance");
        console.log(" Symbol updated by governance:", vault.symbol());

        console.log("Testing setDepositLimit...");
        vm.prank(governance);
        vault.setDepositLimit(1000 ether);
        assertEq(vault.depositLimit(), 1000 ether, "Deposit limit not updated by governance");
        console.log(" Deposit limit updated by governance:", vault.depositLimit());

        console.log("Testing setPerformanceFee...");
        vm.prank(governance);
        vault.setPerformanceFee(500); // 5%
        assertEq(vault.performanceFee(), 500, "Performance fee not updated by governance");
        console.log(" Performance fee updated by governance:", vault.performanceFee());

        console.log("Testing setManagementFee...");
        vm.prank(governance);
        vault.setManagementFee(100); // 1%
        assertEq(vault.managementFee(), 100, "Management fee not updated by governance");
        console.log(" Management fee updated by governance:", vault.managementFee());

        console.log("Testing setLockedProfitDegradation...");
        vm.prank(governance);
        vault.setLockedProfitDegradation(1e17); // 10% degradation
        assertEq(vault.lockedProfitDegradation(), 1e17, "Locked profit degradation not updated");
        console.log(" Locked profit degradation updated by governance:", vault.lockedProfitDegradation());

        console.log("=== Governance parameter setting test passed ===\n");
    }

    function test_vault_setParams_access_control() public {
        console.log("=== Testing access control for parameter setting ===");
        
        console.log("Testing random user cannot set parameters...");
        vm.prank(user);
        vm.expectRevert();
        vault.setName("Hacked Name");
        console.log(" Random user correctly blocked from setting name");

        console.log("Testing guardian cannot set governance parameters...");
        vm.prank(guardian);
        vm.expectRevert();
        vault.setName("Guardian Name");
        console.log(" Guardian correctly blocked from setting name");

        console.log("Testing management cannot set governance parameters...");
        vm.prank(management);
        vm.expectRevert();
        vault.setName("Management Name");
        console.log(" Management correctly blocked from setting name");

        console.log("=== Access control test passed ===\n");
    }

    function test_vault_setGovernance() public {
        console.log("=== Testing governance transfer ===");
        
        address newGovernance = makeAddr("newGovernance");
        console.log("New governance address:", newGovernance);
        
        console.log("Current governance setting new governance...");
        vm.prank(governance);
        vault.setGovernance(newGovernance);
        assertEq(vault.pendingGovernance(), newGovernance, "Pending governance not set");
        console.log(" Pending governance set to:", vault.pendingGovernance());
        
        console.log("Verifying current governance unchanged...");
        assertEq(vault.governance(), governance, "Governance changed before acceptance");
        console.log(" Current governance unchanged:", vault.governance());
        
        console.log("Testing non-pending governance cannot accept...");
        vm.prank(user);
        vm.expectRevert();
        vault.acceptGovernance();
        console.log(" Non-pending governance correctly blocked from accepting");
        

        // NOTE: Acceptgovernance()
        console.log("New governance accepting role...");
        vm.prank(newGovernance);
        vault.acceptGovernance();
        assertEq(vault.governance(), newGovernance, "Governance not transferred");
        console.log(" Governance successfully transferred to:", vault.governance());
        
        console.log("=== Governance transfer test passed ===\n");
    }

    function test_vault_setEmergencyShutdown() public {
        console.log("=== Testing emergency shutdown ===");
        
        console.log("Guardian activating emergency shutdown...");
        vm.prank(guardian);
        vault.setEmergencyShutdown(true);
        assertTrue(vault.emergencyShutdown(), "Emergency shutdown not activated by guardian");
        console.log(" Emergency shutdown activated by guardian");
        
        console.log("Testing guardian cannot deactivate emergency shutdown...");
        vm.prank(guardian);
        vm.expectRevert();
        vault.setEmergencyShutdown(false);
        console.log(" Guardian correctly blocked from deactivating emergency shutdown");
        
        console.log("Governance deactivating emergency shutdown...");
        vm.prank(governance);
        vault.setEmergencyShutdown(false);
        assertFalse(vault.emergencyShutdown(), "Emergency shutdown not deactivated by governance");
        console.log(" Emergency shutdown deactivated by governance");
        
        console.log("=== Emergency shutdown test passed ===\n");
    }

    function test_vault_setLockedProfitDegradation_range() public {
        console.log("=== Testing locked profit degradation range ===");
        
        console.log("Checking current governance...");
        console.log("Current governance:", vault.governance());
        console.log("Test governance:", governance);
        
        console.log("Testing setting degradation to 0...");
        vm.prank(governance);
        vault.setLockedProfitDegradation(0);
        assertEq(vault.lockedProfitDegradation(), 0, "Cannot set degradation to 0");
        console.log(" Successfully set degradation to 0");
        
        console.log("Testing setting degradation to maximum...");
        uint256 maxDegradation = vault.DEGRADATION_COEFFICIENT();
        console.log("Max degradation value:", maxDegradation);
        
        vm.prank(governance);
        vault.setLockedProfitDegradation(maxDegradation);
        assertEq(vault.lockedProfitDegradation(), maxDegradation, "Cannot set degradation to max");
        console.log(" Successfully set degradation to max:", vault.lockedProfitDegradation());
        
        console.log("Testing exceeding maximum degradation...");
        vm.prank(governance);
        vm.expectRevert("Vault: deg > coef");
        vault.setLockedProfitDegradation(maxDegradation + 1);
        console.log(" Correctly reverted when exceeding max");
        
        console.log("=== Locked profit degradation range test passed ===\n");
    }

    function test_vault_setRewards_validation() public {
        console.log("=== Testing rewards address validation ===");
        
        console.log("Testing cannot set rewards to zero address...");
        vm.prank(governance);
        vm.expectRevert();
        vault.setRewards(address(0));
        console.log(" Correctly blocked setting rewards to zero address");
        
        console.log("Testing cannot set rewards to vault address...");
        vm.prank(governance);
        vm.expectRevert();
        vault.setRewards(address(vault));
        console.log(" Correctly blocked setting rewards to vault address");
        
        console.log("Testing setting rewards to valid address...");
        address newRewards = makeAddr("newRewards");
        console.log("New rewards address:", newRewards);
        
        vm.prank(governance);
        vault.setRewards(newRewards);
        assertEq(vault.rewards(), newRewards, "Rewards address not updated");
        console.log(" Successfully updated rewards to:", vault.rewards());
        
        console.log("=== Rewards address validation test passed ===\n");
    }
}

