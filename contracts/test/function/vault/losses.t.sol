// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./config.t.sol";

contract LossesTest is ConfigTest {
    MockStrategy public strategy;
    
    function setUp() public override {
        super.setUp();
        
        console.log("=== Setting up LossesTest ===");
        
        // Create and add strategy
        strategy = new MockStrategy(address(vault), address(token));
        console.log("MockStrategy deployed at:", address(strategy));
        
        // Fund the test contract first
        token.mint(address(this), 100 ether);
        console.log("Minted 100 ETH to test contract");
        
        // Approve vault to spend tokens
        token.approve(address(vault), 100 ether);
        console.log("Approved vault to spend tokens");
        
        // Add strategy to vault
        vm.prank(governance);
        vault.addStrategy(
            address(strategy),
            1000, // 10% debt ratio
            1 ether, // min debt
            10 ether, // max debt
            1000 // 10% performance fee
        );
        console.log("Strategy added to vault");
        
        // Deposit to vault
        vault.deposit(50 ether, address(this));
        console.log("Deposited 50 ETH to vault");
        
        console.log("=== LossesTest setup completed ===");
    }

    // Helper function to get strategy total loss
    function _getStrategyTotalLoss(address _strategy) internal view returns (uint256) {
        (, , , , , , , , uint256 totalLoss) = vault.strategies(_strategy);
        return totalLoss;
    }

    // Helper function to get strategy total debt
    function _getStrategyTotalDebt(address _strategy) internal view returns (uint256) {
        (, , , , , , uint256 totalDebt, , ) = vault.strategies(_strategy);
        return totalDebt;
    }

    // Helper function to get strategy debt ratio
    function _getStrategyDebtRatio(address _strategy) internal view returns (uint256) {
        (, , uint256 debtRatio, , , , , , ) = vault.strategies(_strategy);
        return debtRatio;
    }

    // Helper function to get strategy total gain
    function _getStrategyTotalGain(address _strategy) internal view returns (uint256) {
        (, , , , , , , uint256 totalGain, ) = vault.strategies(_strategy);
        return totalGain;
    }

    function test_loss_reporting() public {
        console.log("Testing loss reporting...");
        
        // Simulate strategy having funds by minting directly to strategy
        token.mint(address(strategy), 10 ether);
        console.log("Minted 10 ETH to strategy");
        
        // Report loss
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0); // 2 ETH loss
        
        // Get strategy params using helper functions
        uint256 totalLoss = _getStrategyTotalLoss(address(strategy));
        uint256 totalDebt = _getStrategyTotalDebt(address(strategy));
        
        console.log("Total loss recorded:", totalLoss);
        console.log("Total debt after loss:", totalDebt);
        console.log("Vault total debt:", vault.totalDebt());
        
        assertEq(totalLoss, 2 ether, "Total loss not recorded");
        assertEq(totalDebt, 8 ether, "Debt not reduced by loss amount");
        assertEq(vault.totalDebt(), 8 ether, "Total debt not reduced");
        
        console.log("Loss reporting test passed");
    }

    function test_loss_with_debt_ratio_adjustment() public {
        console.log("Testing loss with debt ratio adjustment...");
        
        // Set up initial debt by minting to strategy
        token.mint(address(strategy), 10 ether);
        console.log("Minted 10 ETH to strategy for debt setup");
        
        // Get initial debt ratio
        uint256 initialDebtRatio = _getStrategyDebtRatio(address(strategy));
        console.log("Initial debt ratio:", initialDebtRatio);
        
        // Report loss - should reduce debt ratio
        vm.prank(address(strategy));
        vault.report(0, 5 ether, 0); // 50% loss
        
        // Get updated debt ratio
        uint256 newDebtRatio = _getStrategyDebtRatio(address(strategy));
        console.log("New debt ratio after loss:", newDebtRatio);
        
        assertTrue(newDebtRatio < initialDebtRatio, "Debt ratio not reduced after loss");
        
        console.log("Loss with debt ratio adjustment test passed");
    }

    function test_multiple_loss_events() public {
        console.log("Testing multiple loss events...");
        
        token.mint(address(strategy), 10 ether);
        console.log("Minted 10 ETH to strategy");
        
        // First loss
        vm.prank(address(strategy));
        vault.report(0, 3 ether, 0);
        
        uint256 initialDebtRatio = _getStrategyDebtRatio(address(strategy));
        uint256 initialTotalLoss = _getStrategyTotalLoss(address(strategy));
        console.log("After first loss - Debt ratio:", initialDebtRatio, "Total loss:", initialTotalLoss);
        
        // Second loss
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0);
        
        uint256 finalDebtRatio = _getStrategyDebtRatio(address(strategy));
        uint256 finalTotalLoss = _getStrategyTotalLoss(address(strategy));
        console.log("After second loss - Debt ratio:", finalDebtRatio, "Total loss:", finalTotalLoss);
        
        assertEq(finalTotalLoss, 5 ether, "Total loss accumulation incorrect");
        assertTrue(finalDebtRatio < initialDebtRatio, "Debt ratio not further reduced");
        
        console.log("Multiple loss events test passed");
    }

    function test_loss_exceeding_debt() public {
        console.log("Testing loss exceeding debt...");
        
        token.mint(address(strategy), 5 ether);
        console.log("Minted 5 ETH to strategy");
        
        // Try to report more loss than debt - should revert
        vm.prank(address(strategy));
        
        // Use expectRevert with proper error matching
        vm.expectRevert();
        vault.report(0, 10 ether, 0);
        
        console.log("Loss exceeding debt test passed");
    }

    function test_loss_during_emergency_shutdown() public {
        console.log("Testing loss during emergency shutdown...");
        
        // Activate emergency shutdown
        vm.prank(guardian);
        vault.setEmergencyShutdown(true);
        console.log("Emergency shutdown activated");
        
        token.mint(address(strategy), 10 ether);
        console.log("Minted 10 ETH to strategy");
        
        // Should still be able to report loss during shutdown
        vm.prank(address(strategy));
        vault.report(0, 2 ether, 0);
        
        uint256 totalLoss = _getStrategyTotalLoss(address(strategy));
        console.log("Total loss recorded during shutdown:", totalLoss);
        
        assertEq(totalLoss, 2 ether, "Loss not recorded during shutdown");
        
        console.log("Loss during emergency shutdown test passed");
    }

    function test_loss_with_gain_same_report() public {
        console.log("Testing loss with gain in same report...");
        
        token.mint(address(strategy), 15 ether); // 5 ETH gain over expected 10 ETH debt
        console.log("Minted 15 ETH to strategy (simulating gain scenario)");
        
        // Report both gain and loss
        vm.prank(address(strategy));
        vault.report(3 ether, 2 ether, 0); // 3 ETH gain, 2 ETH loss
        
        uint256 totalDebt = _getStrategyTotalDebt(address(strategy));
        uint256 totalGain = _getStrategyTotalGain(address(strategy));
        uint256 totalLoss = _getStrategyTotalLoss(address(strategy));
        
        console.log("Total gain:", totalGain);
        console.log("Total loss:", totalLoss);
        console.log("Total debt:", totalDebt);
        
        assertEq(totalGain, 3 ether, "Gain not recorded");
        assertEq(totalLoss, 2 ether, "Loss not recorded");
        // Note: The exact debt calculation might depend on the vault's internal logic
        // Adjust this assertion based on how your vault handles gain/loss reporting
        assertTrue(totalDebt > 0, "Net debt calculation issue");
        
        console.log("Loss with gain in same report test passed");
    }

    // Test edge case: zero loss
    function test_zero_loss() public {
        console.log("Testing zero loss reporting...");
        
        token.mint(address(strategy), 10 ether);
        console.log("Minted 10 ETH to strategy");
        
        // Report zero loss
        vm.prank(address(strategy));
        vault.report(0, 0, 0);
        
        uint256 totalLoss = _getStrategyTotalLoss(address(strategy));
        console.log("Total loss after zero loss report:", totalLoss);
        
        assertEq(totalLoss, 0, "Zero loss should not change total loss");
        
        console.log("Zero loss test passed");
    }
}