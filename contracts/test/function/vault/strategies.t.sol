// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./config.t.sol";

contract StrategiesTest is ConfigTest {
    MockStrategy public strategy;
    MockStrategy public strategy2;
    
    function setUp() public override {
        super.setUp();
        
        strategy = new MockStrategy(address(vault), address(token));
        strategy2 = new MockStrategy(address(vault), address(token));
        
        // Fund the vault
        token.mint(address(this), 200 ether);
        token.approve(address(vault), 200 ether);
        vault.deposit(100 ether, address(this));
    }

    function test_add_strategy() public {
        console.log("Testing strategy addition...");
        
        vm.prank(governance);
        vault.addStrategy(
            address(strategy),
            2000, // 20% debt ratio
            1 ether, // min debt
            10 ether, // max debt
            1000 // 10% performance fee
        );
        
        Vault.StrategyParams memory params = vault.strategies(address(strategy));
        assertTrue(params.activation > 0, "Strategy not activated");
        assertEq(params.debtRatio, 2000, "Debt ratio not set");
        assertEq(params.minDebtPerHarvest, 1 ether, "Min debt not set");
        assertEq(params.maxDebtPerHarvest, 10 ether, "Max debt not set");
        assertEq(params.performanceFee, 1000, "Performance fee not set");
        assertEq(vault.debtRatio(), 2000, "Total debt ratio not updated");
        
        console.log("Strategy addition test passed");
    }

    function test_add_strategy_validation() public {
        console.log("Testing strategy addition validation...");
        
        // Test invalid strategy address
        vm.prank(governance);
        vm.expectRevert("addr");
        vault.addStrategy(address(0), 1000, 1 ether, 10 ether, 1000);
        
        // Test wrong vault
        MockStrategy wrongVaultStrategy = new MockStrategy(address(this), address(token));
        vm.prank(governance);
        vm.expectRevert("vault");
        vault.addStrategy(address(wrongVaultStrategy), 1000, 1 ether, 10 ether, 1000);
        
        // Test wrong token
        MockToken wrongToken = new MockToken();
        MockStrategy wrongTokenStrategy = new MockStrategy(address(vault), address(wrongToken));
        vm.prank(governance);
        vm.expectRevert("want");
        vault.addStrategy(address(wrongTokenStrategy), 1000, 1 ether, 10 ether, 1000);
        
        // Test debt ratio overflow
        vm.prank(governance);
        vm.expectRevert("ratio");
        vault.addStrategy(address(strategy), 10001, 1 ether, 10 ether, 1000);
        
        // Test min > max
        vm.prank(governance);
        vm.expectRevert("range");
        vault.addStrategy(address(strategy), 1000, 10 ether, 1 ether, 1000);
        
        // Test performance fee too high
        vm.prank(governance);
        vm.expectRevert("pf");
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 5001);
        
        console.log("Strategy addition validation test passed");
    }

    function test_update_strategy_params() public {
        console.log("Testing strategy parameter updates...");
        
        // Add strategy first
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        // Update debt ratio
        vm.prank(governance);
        vault.updateStrategyDebtRatio(address(strategy), 500);
        
        Vault.StrategyParams memory params = vault.strategies(address(strategy));
        assertEq(params.debtRatio, 500, "Debt ratio not updated");
        assertEq(vault.debtRatio(), 500, "Total debt ratio not updated");
        
        // Update min debt
        vm.prank(management);
        vault.updateStrategyMinDebtPerHarvest(address(strategy), 2 ether);
        params = vault.strategies(address(strategy));
        assertEq(params.minDebtPerHarvest, 2 ether, "Min debt not updated");
        
        // Update max debt
        vm.prank(management);
        vault.updateStrategyMaxDebtPerHarvest(address(strategy), 5 ether);
        params = vault.strategies(address(strategy));
        assertEq(params.maxDebtPerHarvest, 5 ether, "Max debt not updated");
        
        // Update performance fee
        vm.prank(governance);
        vault.updateStrategyPerformanceFee(address(strategy), 500);
        params = vault.strategies(address(strategy));
        assertEq(params.performanceFee, 500, "Performance fee not updated");
        
        console.log("Strategy parameter updates test passed");
    }

    function test_strategy_migration() public {
        console.log("Testing strategy migration...");
        
        // Add original strategy
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        // Fund strategy
        token.mint(address(strategy), 5 ether);
        
        // Migrate to new strategy
        vm.prank(governance);
        vault.migrateStrategy(address(strategy), address(strategy2));
        
        Vault.StrategyParams memory oldParams = vault.strategies(address(strategy));
        Vault.StrategyParams memory newParams = vault.strategies(address(strategy2));
        
        assertEq(oldParams.totalDebt, 0, "Old strategy debt not cleared");
        assertEq(newParams.debtRatio, 1000, "New strategy debt ratio not set");
        assertTrue(newParams.activation > 0, "New strategy not activated");
        
        console.log("Strategy migration test passed");
    }

    function test_strategy_revocation() public {
        console.log("Testing strategy revocation...");
        
        // Add strategy
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        uint256 initialDebtRatio = vault.debtRatio();
        
        // Revoke strategy
        vm.prank(governance);
        vault.revokeStrategy(address(strategy));
        
        Vault.StrategyParams memory params = vault.strategies(address(strategy));
        assertEq(params.debtRatio, 0, "Strategy debt ratio not zeroed");
        assertEq(vault.debtRatio(), initialDebtRatio - 1000, "Total debt ratio not updated");
        
        console.log("Strategy revocation test passed");
    }

    function test_credit_available_calculation() public {
        console.log("Testing credit available calculation...");
        
        // Add strategy
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        // Check credit available
        uint256 credit = vault.creditAvailable(address(strategy));
        assertTrue(credit >= 1 ether, "Credit available below minimum");
        assertTrue(credit <= 10 ether, "Credit available above maximum");
        
        console.log("Credit available calculation test passed");
    }

    function test_debt_outstanding_calculation() public {
        console.log("Testing debt outstanding calculation...");
        
        // Add strategy
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        // Initially no debt outstanding
        uint256 debt = vault.debtOutstanding(address(strategy));
        assertEq(debt, 0, "Initial debt outstanding should be 0");
        
        console.log("Debt outstanding calculation test passed");
    }

    function test_expected_return_calculation() public {
        console.log("Testing expected return calculation...");
        
        // Add strategy
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        // Initially no expected return
        uint256 expectedReturn = vault.expectedReturn(address(strategy));
        assertEq(expectedReturn, 0, "Initial expected return should be 0");
        
        console.log("Expected return calculation test passed");
    }

    function test_withdrawal_queue_management() public {
        console.log("Testing withdrawal queue management...");
        
        // Add strategies
        vm.prank(governance);
        vault.addStrategy(address(strategy), 1000, 1 ether, 10 ether, 1000);
        
        vm.prank(governance);
        vault.addStrategy(address(strategy2), 1000, 1 ether, 10 ether, 1000);
        
        // Test queue ordering
        address[20] memory queue = vault.withdrawalQueue();
        assertEq(queue[0], address(strategy), "First strategy not in queue");
        assertEq(queue[1], address(strategy2), "Second strategy not in queue");
        
        // Remove from queue
        vm.prank(management);
        vault.removeStrategyFromQueue(address(strategy));
        
        queue = vault.withdrawalQueue();
        assertEq(queue[0], address(strategy2), "Queue not reorganized after removal");
        
        // Add back to queue
        vm.prank(management);
        vault.addStrategyToQueue(address(strategy));
        
        queue = vault.withdrawalQueue();
        assertEq(queue[1], address(strategy), "Strategy not added back to queue");
        
        console.log("Withdrawal queue management test passed");
    }
}