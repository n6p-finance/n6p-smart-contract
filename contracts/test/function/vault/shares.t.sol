// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./config.t.sol";

contract SharesTest is ConfigTest {
    function setUp() public override {
        super.setUp();
    }

    function test_share_issuance() public {
        console.log("Testing share issuance...");
        
        uint256 initialSupply = vault.totalSupply();
        uint256 initialBalance = vault.balanceOf(address(this));
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, address(this));
        
        // Shares increases
        assertEq(vault.totalSupply(), initialSupply + shares, "Total supply not increased");
        assertEq(vault.balanceOf(address(this)), initialBalance + shares, "Balance not increased");
        assertTrue(shares > 0, "No shares issued for deposit");
        
        console.log("Share issuance test passed");
    }

    function test_share_transfer() public {
        console.log("Testing share transfers...");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        uint256 initialBalance = vault.balanceOf(address(this));
        address recipient = makeAddr("recipient");
        
        // Transfer shares
        uint256 transferAmount = 50 ether;
        vault.transfer(recipient, transferAmount);
        
        assertEq(vault.balanceOf(address(this)), initialBalance - transferAmount, "Sender balance incorrect");
        assertEq(vault.balanceOf(recipient), transferAmount, "Recipient balance incorrect");
        
        console.log("Share transfer test passed");
    }

    function test_share_transferFrom() public {
        console.log("Testing transferFrom functionality...");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        address owner = address(this);
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 50 ether;
        
        // Approve spender
        vault.approve(spender, transferAmount);
        assertEq(vault.allowance(owner, spender), transferAmount, "Allowance not set");
        
        // Transfer from
        vm.prank(spender);
        vault.transferFrom(owner, recipient, transferAmount);
        
        assertEq(vault.balanceOf(recipient), transferAmount, "Recipient balance incorrect");
        assertEq(vault.allowance(owner, spender), 0, "Allowance not decreased");
        
        console.log("TransferFrom test passed");
    }

    function test_share_approval() public {
        console.log("Testing approval functionality...");
        
        address spender = makeAddr("spender");
        uint256 amount = 100 ether;
        
        vault.approve(spender, amount);
        assertEq(vault.allowance(address(this), spender), amount, "Allowance not set");
        
        // Test increase allowance
        vault.increaseAllowance(spender, 50 ether);
        assertEq(vault.allowance(address(this), spender), 150 ether, "Allowance not increased");
        
        // Test decrease allowance
        vault.decreaseAllowance(spender, 75 ether);
        assertEq(vault.allowance(address(this), spender), 75 ether, "Allowance not decreased");
        
        console.log("Approval functionality test passed");
    }

    function test_share_value_calculation() public {
        console.log("Testing share value calculation...");
        
        // Initial share value should be 1:1
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Initial share value should be 1");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, address(this));
        
        // Share value should still be 1:1
        assertEq(vault.pricePerShare(), 10 ** vault.decimals(), "Share value changed without gains");
        
        // Calculate share value manually
        uint256 calculatedValue = vault._shareValuePublic_(shares);
        assertEq(calculatedValue, 100 ether, "Share value calculation incorrect");
        
        console.log("Share value calculation test passed");
    }

    function test_shares_for_amount_calculation() public {
        console.log("Testing shares for amount calculation...");
        
        // Deposit initial funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        // Calculate shares for a specific amount
        uint256 testAmount = 50 ether;
        uint256 expectedShares = vault._sharesForAmountPublic_(testAmount);
        
        assertTrue(expectedShares > 0, "Should get shares for positive amount");
        
        console.log("Shares for amount calculation test passed");
    }

    function test_zero_share_issuance() public {
        console.log("Testing zero share issuance protection...");
        
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        
        // Should not issue zero shares
        vm.expectRevert("amount");
        vault.deposit(0, address(this));
        
        console.log("Zero share issuance protection test passed");
    }

    function test_transfer_to_zero_address() public {
        console.log("Testing transfer to zero address protection...");
        
        // Deposit funds
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        
        // Should not transfer to zero address
        vm.expectRevert("bad to");
        vault.transfer(address(0), 10 ether);
        
        // Should not transfer to vault address
        vm.expectRevert("bad to");
        vault.transfer(address(vault), 10 ether);
        
        console.log("Transfer to zero address protection test passed");
    }
}