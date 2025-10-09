// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./config.t.sol";

contract LossesTest is ConfigTest {
    MockStrategy public strategy;
    
    function setUp() public override {
        super.setUp();
        
        // Create and add strategy
        strategy = new MockStrategy(address(vault), address(token));
        
        vm.prank(governance);
        vault.addStrategy(
            address(strategy),
            1000, // 10% debt ratio
            1 ether, // min debt
            10 ether, // max debt
            1000 // 10% performance fee
        );
        
        // Fund the vault
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(50 ether, address(this));
    }

    function test_loss_reporting() public {
        console.log("Testing loss reporting...");
        
        // Simulate strategy having funds
        token.mint(address(strategy), 10 ether);
        
        // Report loss
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0); // 2 ETH loss
        
        // Get strategy params individually since the mapping returns separate values
        (
            uint256 performanceFee,
            uint256 activation, 
            uint256 debtRatio,
            uint256 minDebtPerHarvest,
            uint256 maxDebtPerHarvest,
            uint256 lastReport,
            uint256 totalDebt,
            uint256 totalGain,
            uint256 totalLoss
        ) = vault.strategies(address(strategy));
        
        assertEq(totalLoss, 2 ether, "Total loss not recorded");
        assertEq(totalDebt, 8 ether, "Debt not reduced by loss amount");
        assertEq(vault.totalDebt(), 8 ether, "Total debt not reduced");
        
        console.log("Loss reporting test passed");
    }

    function test_loss_with_debt_ratio_adjustment() public {
        console.log("Testing loss with debt ratio adjustment...");
        
        // Set up initial debt
        token.mint(address(strategy), 10 ether);
        
        // Report loss - should reduce debt ratio
        vm.prank(address(strategy));
        vault.report(0, 5 ether, 0); // 50% loss
        
        // Get just the debtRatio from strategy params
        (, , uint256 debtRatio, , , , , , ) = vault.strategies(address(strategy));
        assertTrue(debtRatio < 1000, "Debt ratio not reduced after loss");
        
        console.log("Loss with debt ratio adjustment test passed");
    }

    function test_multiple_loss_events() public {
        console.log("Testing multiple loss events...");
        
        token.mint(address(strategy), 10 ether);
        
        // First loss
        vm.prank(address(strategy));
        vault.report(0, 3 ether, 0);
        
        (, , uint256 initialDebtRatio, , , , , , ) = vault.strategies(address(strategy));
        
        // Second loss
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0);
        
        (, , uint256 finalDebtRatio, , , , , uint256 finalTotalLoss, ) = vault.strategies(address(strategy));
        assertEq(finalTotalLoss, 5 ether, "Total loss accumulation incorrect");
        assertTrue(finalDebtRatio < initialDebtRatio, "Debt ratio not further reduced");
        
        console.log("Multiple loss events test passed");
    }

    function test_loss_exceeding_debt() public {
        console.log("Testing loss exceeding debt...");
        
        token.mint(address(strategy), 5 ether);
        
        // Try to report more loss than debt
        vm.prank(address(strategy));
        vm.expectRevert(); // Remove the string argument
        vault.report(0, 10 ether, 0);
        
        console.log("Loss exceeding debt test passed");
    }

    function test_loss_during_emergency_shutdown() public {
        console.log("Testing loss during emergency shutdown...");
        
        // Activate emergency shutdown
        vm.prank(guardian);
        vault.setEmergencyShutdown(true);
        
        token.mint(address(strategy), 10 ether);
        
        // Should still be able to report loss
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0);
        
        (, , , , , , , uint256 totalLoss, ) = vault.strategies(address(strategy));
        assertEq(totalLoss, 2 ether, "Loss not recorded during shutdown");
        
        console.log("Loss during emergency shutdown test passed");
    }

    function test_loss_with_gain_same_report() public {
        console.log("Testing loss with gain in same report...");
        
        token.mint(address(strategy), 15 ether); // 5 ETH gain over 10 ETH debt
        
        // Report both gain and loss
        vm.prank(address(strategy));
        vault.report(3 ether, 2 ether, 0); // 3 ETH gain, 2 ETH loss
        
        (
            , , , , , , 
            uint256 totalDebt,
            uint256 totalGain, 
            uint256 totalLoss
        ) = vault.strategies(address(strategy));
        
        assertEq(totalGain, 3 ether, "Gain not recorded");
        assertEq(totalLoss, 2 ether, "Loss not recorded");
        assertEq(totalDebt, 13 ether, "Net debt calculation incorrect");
        
        console.log("Loss with gain in same report test passed");
    }
}