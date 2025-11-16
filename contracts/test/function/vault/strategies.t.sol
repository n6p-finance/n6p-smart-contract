// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./config.t.sol";

contract StrategiesTest is ConfigTest {
    MockStrategy public strategy;
    MockStrategy public strategy2;
    
    function setUp() public override {
        console.log("=== Setting up StrategiesTest ===");
        super.setUp();
        
        strategy = new MockStrategy(address(vault), address(token));
        console.log("Strategy 1 deployed at:", address(strategy));
        
        strategy2 = new MockStrategy(address(vault), address(token));
        console.log("Strategy 2 deployed at:", address(strategy2));
        
        // Fund the vault
        console.log("Funding vault with test tokens...");
        token.mint(address(this), 200 ether);
        token.approve(address(vault), 200 ether);
        vault.deposit(100 ether, address(this));
        console.log("Vault funded with 100 ether");
        console.log("=== StrategiesTest setup completed ===\n");
    }

    // Helper function to get strategy params as a tuple - CORRECTED ORDER
    function getStrategyParams(address strategyAddress) public view returns (
        uint256 performanceFee,
        uint256 activation,
        uint256 debtRatio, 
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 lastReport,
        uint256 totalDebt,
        uint256 totalGain,
        uint256 totalLoss
    ) {
        return vault.strategies(strategyAddress);
    }

    function test_add_strategy() public {
        console.log("=== Testing strategy addition ===");
        
        console.log("Governance adding strategy...");
        vm.prank(governance);
        vault.addStrategy(
            address(strategy),
            2000,    // 20% debt ratio (SECOND parameter)
            1 ether, // min debt (THIRD parameter)
            10 ether, // max debt (FOURTH parameter)
            500      // 5% performance fee (FIFTH parameter - SMALL BPS VALUE!)
        );
        console.log("Strategy added successfully");
        
        // Get strategy parameters as tuple - CORRECTED UNPACKING
        console.log("Reading strategy parameters...");
        (
            uint256 performanceFee,
            uint256 activation,
            uint256 debtRatio,
            uint256 minDebt,
            uint256 maxDebt,
            , , ,  // Skip lastReport, totalDebt, totalGain, totalLoss
        ) = getStrategyParams(address(strategy));
        
        console.log("Validating strategy parameters...");
        assertTrue(activation > 0, "Strategy not activated");
        console.log(" Strategy activated at timestamp:", activation);
        
        assertEq(debtRatio, 2000, "Debt ratio not set");
        console.log(" Debt ratio set to:", debtRatio);
        
        assertEq(minDebt, 1 ether, "Min debt not set");
        console.log(" Min debt set to:", minDebt);
        
        assertEq(maxDebt, 10 ether, "Max debt not set");
        console.log(" Max debt set to:", maxDebt);
        
        assertEq(performanceFee, 500, "Performance fee not set");
        console.log(" Performance fee set to:", performanceFee);
        
        assertEq(vault.debtRatio(), 2000, "Total debt ratio not updated");
        console.log(" Total debt ratio updated to:", vault.debtRatio());
        
        console.log("=== Strategy addition test passed ===\n");
    }

    function test_add_strategy_validation() public {
        console.log("=== Testing strategy addition validation ===");
        
        console.log("Testing invalid strategy address (zero address)...");
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(0), 1000, 1 ether, 10 ether, 500);
        console.log(" Correctly blocked zero address strategy");
        
        console.log("Testing strategy with wrong vault...");
        MockStrategy wrongVaultStrategy = new MockStrategy(address(this), address(token));
        console.log("Wrong vault strategy deployed at:", address(wrongVaultStrategy));
        
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(wrongVaultStrategy), 1000, 1 ether, 10 ether, 500);
        console.log(" Correctly blocked wrong vault strategy");
        
        console.log("Testing strategy with wrong token...");
        MockToken wrongToken = new MockToken();
        MockStrategy wrongTokenStrategy = new MockStrategy(address(vault), address(wrongToken));
        console.log("Wrong token strategy deployed at:", address(wrongTokenStrategy));
        
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(wrongTokenStrategy), 1000, 1 ether, 10 ether, 500);
        console.log(" Correctly blocked wrong token strategy");
        
        console.log("Testing debt ratio overflow...");
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(strategy), 10001, 1 ether, 10 ether, 500);
        console.log(" Correctly blocked debt ratio overflow");
        
        console.log("Testing min > max debt...");
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(strategy), 1000, 10 ether, 1 ether, 500);
        console.log(" Correctly blocked min > max debt");
        
        console.log("Testing performance fee too high...");
        vm.prank(governance);
        vm.expectRevert();
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 5001);
        console.log(" Correctly blocked performance fee too high");
        
        console.log("=== Strategy addition validation test passed ===\n");
    }

    function test_update_strategy_params() public {
        console.log("=== Testing strategy parameter updates ===");
        
        console.log("Adding initial strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Initial strategy added");
        
        console.log("Updating debt ratio...");
        vm.prank(governance);
        vault.updateStrategyDebtRatio(address(strategy), 500);
        
        (, , uint256 newDebtRatio, , , , , ,) = getStrategyParams(address(strategy));
        assertEq(newDebtRatio, 500, "Debt ratio not updated");
        console.log(" Debt ratio updated to:", newDebtRatio);
        
        assertEq(vault.debtRatio(), 500, "Total debt ratio not updated");
        console.log(" Total debt ratio updated to:", vault.debtRatio());
        
        console.log("Updating min debt...");
        vm.prank(management);
        vault.updateStrategyMinDebtPerHarvest(address(strategy), 2 ether);
        
        (, , , uint256 newMinDebt, , , , ,) = getStrategyParams(address(strategy));
        assertEq(newMinDebt, 2 ether, "Min debt not updated");
        console.log(" Min debt updated to:", newMinDebt);
        
        console.log("Updating max debt...");
        vm.prank(management);
        vault.updateStrategyMaxDebtPerHarvest(address(strategy), 5 ether);
        
        (, , , , uint256 newMaxDebt, , , ,) = getStrategyParams(address(strategy));
        assertEq(newMaxDebt, 5 ether, "Max debt not updated");
        console.log(" Max debt updated to:", newMaxDebt);
        
        console.log("Updating performance fee...");
        vm.prank(governance);
        vault.updateStrategyPerformanceFee(address(strategy), 250);
        
        (uint256 newPerfFee, , , , , , , ,) = getStrategyParams(address(strategy));
        assertEq(newPerfFee, 250, "Performance fee not updated");
        console.log(" Performance fee updated to:", newPerfFee);
        
        console.log("=== Strategy parameter updates test passed ===\n");
    }

    function test_strategy_migration() public {
        console.log("=== Testing strategy migration ===");
        
        console.log("Adding original strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Original strategy added");
        
        console.log("Funding strategy with tokens...");
        token.mint(address(strategy), 5 ether);
        console.log("Strategy funded with 5 ether");
        
        console.log("Migrating to new strategy...");
        vm.prank(governance);
        vault.migrateStrategy(address(strategy), address(strategy2));
        console.log("Strategy migration completed");
        
        console.log("Checking old strategy state...");
        (, , , , , , uint256 oldStrategyDebt, ,) = getStrategyParams(address(strategy));
        assertEq(oldStrategyDebt, 0, "Old strategy debt not cleared");
        console.log(" Old strategy debt cleared:", oldStrategyDebt);
        
        console.log("Checking new strategy state...");
        (, , uint256 newStrategyDebtRatio, , , uint256 newStrategyActivation, , ,) = getStrategyParams(address(strategy2));
        
        assertEq(newStrategyDebtRatio, 1000, "New strategy debt ratio not set");
        console.log(" New strategy debt ratio set to:", newStrategyDebtRatio);
        
        assertTrue(newStrategyActivation > 0, "New strategy not activated");
        console.log(" New strategy activated at timestamp:", newStrategyActivation);
        
        console.log("=== Strategy migration test passed ===\n");
    }

    function test_strategy_revocation() public {
        console.log("=== Testing strategy revocation ===");
        
        console.log("Adding strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy added");
        
        uint256 initialDebtRatio = vault.debtRatio();
        console.log("Initial total debt ratio:", initialDebtRatio);
        
        console.log("Revoking strategy...");
        vm.prank(governance);
        vault.revokeStrategy(address(strategy));
        console.log("Strategy revoked");
        
        console.log("Checking strategy state after revocation...");
        (, , uint256 strategyDebtRatio, , , , , ,) = getStrategyParams(address(strategy));
        uint256 newTotalDebtRatio = vault.debtRatio();
        
        assertEq(strategyDebtRatio, 0, "Strategy debt ratio not zeroed");
        console.log(" Strategy debt ratio zeroed:", strategyDebtRatio);
        
        assertEq(newTotalDebtRatio, initialDebtRatio - 1000, "Total debt ratio not updated");
        console.log(" Total debt ratio updated to:", newTotalDebtRatio);
        
        console.log("=== Strategy revocation test passed ===\n");
    }

    function test_credit_available_calculation() public {
        console.log("=== Testing credit available calculation ===");
        
        console.log("Adding strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy added");
        
        console.log("Checking credit available...");
        uint256 credit = vault.creditAvailable(address(strategy));
        console.log("Credit available:", credit);
        
        assertTrue(credit >= 1 ether, "Credit available below minimum");
        console.log(" Credit available meets minimum requirement");
        
        assertTrue(credit <= 10 ether, "Credit available above maximum");
        console.log(" Credit available meets maximum requirement");
        
        console.log("=== Credit available calculation test passed ===\n");
    }

    function test_debt_outstanding_calculation() public {
        console.log("=== Testing debt outstanding calculation ===");
        
        console.log("Adding strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy added");
        
        console.log("Checking initial debt outstanding...");
        uint256 debt = vault.debtOutstanding(address(strategy));
        console.log("Initial debt outstanding:", debt);
        
        assertEq(debt, 0, "Initial debt outstanding should be 0");
        console.log(" Initial debt outstanding is 0");
        
        console.log("=== Debt outstanding calculation test passed ===\n");
    }

    function test_expected_return_calculation() public {
        console.log("=== Testing expected return calculation ===");
        
        console.log("Adding strategy...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy added");
        
        console.log("Checking initial expected return...");
        uint256 expectedReturn = vault.expectedReturn(address(strategy));
        console.log("Initial expected return:", expectedReturn);
        
        assertEq(expectedReturn, 0, "Initial expected return should be 0");
        console.log(" Initial expected return is 0");
        
        console.log("=== Expected return calculation test passed ===\n");
    }

    function test_withdrawal_queue_management() public {
        console.log("=== Testing withdrawal queue management ===");
        
        console.log("Adding strategy 1...");
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy 1 added");
        
        console.log("Adding strategy 2...");
        vm.prank(governance);
        vault.addStrategy(address(strategy2), 1000, 1 ether, 10 ether, 500);
        console.log("Strategy 2 added");
        
        console.log("Testing queue ordering...");
        address[] memory queue = new address[](20);
        for (uint256 i = 0; i < 20; i++) {
            queue[i] = vault.withdrawalQueue(i);
        }
        
        assertEq(queue[0], address(strategy), "First strategy not in queue");
        console.log(" First strategy in queue:", queue[0]);
        
        assertEq(queue[1], address(strategy2), "Second strategy not in queue");
        console.log(" Second strategy in queue:", queue[1]);
        
        console.log("Removing strategy 1 from queue...");
        vm.prank(management);
        vault.removeStrategyFromQueue(address(strategy));
        console.log("Strategy 1 removed from queue");
        
        // Update queue after removal
        for (uint256 i = 0; i < 20; i++) {
            queue[i] = vault.withdrawalQueue(i);
        }
        
        assertEq(queue[0], address(strategy2), "Queue not reorganized after removal");
        console.log(" Queue reorganized, first strategy now:", queue[0]);
        
        console.log("Adding strategy 1 back to queue...");
        vm.prank(management);
        vault.addStrategyToQueue(address(strategy));
        console.log("Strategy 1 added back to queue");
        
        // Update queue after adding
        for (uint256 i = 0; i < 20; i++) {
            queue[i] = vault.withdrawalQueue(i);
        }
        
        assertEq(queue[1], address(strategy), "Strategy not added back to queue");
        console.log(" Strategy 1 added back to queue at position 1:", queue[1]);
        
        console.log("=== Withdrawal queue management test passed ===\n");
    }

    // REMOVED the conflicting test_vault_initial_state test from StrategiesTest
}

// Separate test contract for vault deployment without deposits
contract VaultDeploymentTest is ConfigTest {
    function test_vault_deployment_() public virtual {
        console.log("=== Testing vault deployment ===");
        
        console.log("Checking addresses...");
        assertEq(vault.governance(), governance, "Governance address mismatch");
        assertEq(vault.management(), management, "Management address mismatch");
        assertEq(vault.guardian(), guardian, "Guardian address mismatch");
        assertEq(vault.rewards(), rewards, "Rewards address mismatch");
        assertEq(address(vault.token()), address(token), "Token address mismatch");
        
        console.log("Checking UI configuration...");
        assertEq(vault.name(), "TEST nVault", "Name mismatch");
        assertEq(vault.symbol(), "nVTEST", "Symbol mismatch");
        assertEq(vault.decimals(), 18, "Decimals mismatch");
        assertEq(vault.apiVersion(), "0.4.6", "API version mismatch");
        
        console.log("Checking initial state...");
        assertEq(vault.debtRatio(), 0, "Initial debt ratio should be 0");
        assertEq(vault.depositLimit(), 0, "Initial deposit limit should be 0");
        // assertEq(vault.totalAssets(), 0, "Initial total assets should be 0");
        assertEq(vault.lockedProfit(), 0, "Initial locked profit should be 0");
        
        console.log("=== Vault deployment test passed ===\n");
    }
}