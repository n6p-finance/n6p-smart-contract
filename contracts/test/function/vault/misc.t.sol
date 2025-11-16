// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./config.t.sol";

contract MiscTest is ConfigTest {
    function setUp() public override {
        super.setUp();
        
        // Set a reasonable deposit limit for all tests that need deposits
        vm.prank(governance);
        vault.setDepositLimit(1000 ether);
    }

    function test_api_adherence() public virtual {
        console.log("Testing API adherence...");
        
        // Check that the vault implements the expected API version
        assertEq(vault.apiVersion(), "0.4.6", "API version mismatch");
        
        // Check that domain separator is properly set
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        assertTrue(domainSeparator != bytes32(0), "Domain separator not set");
        
        console.log("API adherence test passed");
    }

    function test_sweep_functionality() public {
        console.log("Testing token sweeping...");
        
        // Create a different token and send it to vault
        MockToken otherToken = new MockToken();
        otherToken.mint(address(vault), 10 ether);
        
        uint256 initialBalance = otherToken.balanceOf(governance);
        
        // Governance can sweep tokens
        vm.prank(governance);
        vault.sweep(address(otherToken), 10 ether);
        
        assertEq(otherToken.balanceOf(governance), initialBalance + 10 ether, "Swept tokens not transferred");
        assertEq(otherToken.balanceOf(address(vault)), 0, "Vault still has tokens after sweep");
        
        console.log("Token sweeping test passed");
    }

    function test_sweep_main_token_protection() public {
        console.log("Testing main token sweep protection...");
        
        // First deposit some funds to create shares and establish idle funds
        token.mint(address(this), 10 ether);
        token.approve(address(vault), 10 ether);
        vault.deposit(10 ether, address(this));
        
        // Then send additional tokens directly to vault (these should be sweepable)
        token.mint(address(vault), 5 ether);
        
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));
        uint256 governanceBalanceBefore = token.balanceOf(governance);
        
        // Try to sweep main token - should only sweep excess over idle
        vm.prank(governance);
        vault.sweep(address(token), type(uint256).max);
        
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
        uint256 governanceBalanceAfter = token.balanceOf(governance);
        
        // Vault should still have the original deposited amount (idle funds)
        // Only the excess 5 ether should be swept
        assertTrue(vaultBalanceAfter >= 10 ether, "Main token idle funds were swept");
        assertEq(governanceBalanceAfter, governanceBalanceBefore + 5 ether, "Swept amount incorrect");
        
        console.log("Main token sweep protection test passed");
    }

    function test_available_deposit_limit() public {
        console.log("Testing available deposit limit...");
        
        // Reset deposit limit for this specific test
        vm.prank(governance);
        vault.setDepositLimit(0);
        
        // Initially no deposit limit set
        assertEq(vault.availableDepositLimit(), 0, "Available limit should be 0 when no limit set");
        
        // Set deposit limit
        vm.prank(governance);
        vault.setDepositLimit(100 ether);
        
        assertEq(vault.availableDepositLimit(), 100 ether, "Available limit calculation incorrect");
        
        // Deposit some funds
        token.mint(address(this), 50 ether);
        token.approve(address(vault), 50 ether);
        vault.deposit(30 ether, address(this));
        
        assertEq(vault.availableDepositLimit(), 70 ether, "Available limit not updated after deposit");
        
        console.log("Available deposit limit test passed");
    }

    function test_max_available_shares() public {
        console.log("Testing max available shares calculation...");
        
        // Initially no shares available (no deposits yet)
        assertEq(vault.maxAvailableShares(), 0, "Max shares should be 0 with no funds");
        
        // Deposit funds
        token.mint(address(this), 50 ether);
        token.approve(address(vault), 50 ether);
        vault.deposit(50 ether, address(this));
        
        uint256 maxShares = vault.maxAvailableShares();
        assertTrue(maxShares > 0, "Max shares should be positive with funds");
        assertEq(maxShares, vault.balanceOf(address(this)), "Max shares should equal balance with no strategies");
        
        console.log("Max available shares test passed");
    }

    function test_price_per_share_calculation() public {
        console.log("Testing price per share calculation...");
        
        // Initial price should be 1:1
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Initial price per share should be 1");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        // Price should still be 1:1 with no gains/losses
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Price per share changed without gains/losses");
        
        console.log("Price per share calculation test passed");
    }

    function test_total_assets_calculation() public {
        console.log("Testing total assets calculation...");
        
        assertEq(vault.totalAssets(), 0, "Initial total assets should be 0");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        assertEq(vault.totalAssets(), 100 ether, "Total assets not updated after deposit");
        
        console.log("Total assets calculation test passed");
    }

    function test_locked_profit_calculation() public virtual {
        console.log("Testing locked profit calculation...");
        
        // Initially no locked profit
        assertEq(vault.lockedProfit(), 0, "Initial locked profit should be 0");
        
        console.log("Locked profit calculation test passed");
    }

    function test_emergency_shutdown_effects() public {
        console.log("Testing emergency shutdown effects...");
        
        // Fund vault
        token.mint(address(this), 50 ether);
        token.approve(address(vault), 50 ether);
        vault.deposit(50 ether, address(this));
        
        // Activate emergency shutdown
        vm.prank(guardian);
        vault.setEmergencyShutdown(true);
        
        // Should not be able to deposit during shutdown
        token.mint(address(this), 10 ether);
        token.approve(address(vault), 10 ether);
        vm.expectRevert("Vault: shutdown");
        vault.deposit(10 ether, address(this));
        
        // Should still be able to withdraw
        uint256 shares = vault.balanceOf(address(this));
        vault.withdraw(shares, address(this), 100); // 1% max loss
        
        console.log("Emergency shutdown effects test passed");
    }
}