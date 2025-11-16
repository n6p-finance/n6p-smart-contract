// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./config.t.sol";

contract SharesTest is ConfigTest {
    function setUp() public override {
        console.log("Setting up SharesTest...");
        super.setUp();
        console.log("Setup complete.");
    }

    function test_share_issuance() public {
        console.log("Starting test_share_issuance...");
        
        uint256 initialSupply = vault.totalSupply();
        console.log("Initial total supply:", initialSupply);
        uint256 initialBalance = vault.balanceOf(address(this));
        console.log("Initial balance:", initialBalance);

        console.log("Minting and approving token for deposit...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        console.log("Depositing 100 ether...");
        uint256 shares = vault.deposit(100 ether, address(this));
        console.log("Shares issued:", shares);

        console.log("Asserting supply and balance after deposit...");
        assertEq(vault.totalSupply(), initialSupply + shares, "Total supply not increased");
        assertEq(vault.balanceOf(address(this)), initialBalance + shares, "Balance not increased");
        assertTrue(shares > 0, "No shares issued for deposit");

        console.log("test_share_issuance passed.");
    }

    function test_share_transfer() public {
        console.log("Starting test_share_transfer...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));

        uint256 initialBalance = vault.balanceOf(address(this));
        console.log("Initial vault balance:", initialBalance);
        address recipient = makeAddr("recipient");
        console.log("Recipient address:", recipient);

        uint256 transferAmount = 50 ether;
        console.log("Transferring shares:", transferAmount);
        vault.transfer(recipient, transferAmount);

        console.log("Checking balances after transfer...");
        assertEq(vault.balanceOf(address(this)), initialBalance - transferAmount, "Sender balance incorrect");
        assertEq(vault.balanceOf(recipient), transferAmount, "Recipient balance incorrect");

        console.log("test_share_transfer passed.");
    }

    function test_share_transferFrom() public {
        console.log("Starting test_share_transferFrom...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));

        address owner = address(this);
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 50 ether;

        console.log("Approving spender:", spender, "for amount:", transferAmount);
        vault.approve(spender, transferAmount);
        assertEq(vault.allowance(owner, spender), transferAmount, "Allowance not set");

        console.log("Executing transferFrom via spender...");
        vm.prank(spender);
        vault.transferFrom(owner, recipient, transferAmount);

        console.log("Validating balances and allowance...");
        assertEq(vault.balanceOf(recipient), transferAmount, "Recipient balance incorrect");
        assertEq(vault.allowance(owner, spender), 0, "Allowance not decreased");

        console.log("test_share_transferFrom passed.");
    }

    function test_share_approval() public {
        console.log("Starting test_share_approval...");
        address spender = makeAddr("spender");
        uint256 amount = 100 ether;

        console.log("Approving spender:", spender, "for amount:", amount);
        vault.approve(spender, amount);
        assertEq(vault.allowance(address(this), spender), amount, "Allowance not set");

        console.log("Increasing allowance...");
        vault.increaseAllowance(spender, 50 ether);
        assertEq(vault.allowance(address(this), spender), 150 ether, "Allowance not increased");

        console.log("Decreasing allowance...");
        vault.decreaseAllowance(spender, 75 ether);
        assertEq(vault.allowance(address(this), spender), 75 ether, "Allowance not decreased");

        console.log("test_share_approval passed.");
    }

    function test_share_value_calculation() public {
        console.log("Starting test_share_value_calculation...");
        uint256 decimals = vault.decimals();
        console.log("Vault decimals:", decimals);

        console.log("Checking initial price per share...");
        assertEq(vault.pricePerShare(), 10 ** decimals, "Initial share value should be 1");

        console.log("Depositing 100 ether...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, address(this));
        console.log("Shares minted:", shares);

        console.log("Validating price per share after deposit...");
        assertEq(vault.pricePerShare(), 10 ** decimals, "Share value changed without gains");

        console.log("Calculating share value manually...");
        uint256 calculatedValue = vault._shareValuePublic_(shares);
        assertEq(calculatedValue, 100 ether, "Share value calculation incorrect");

        console.log("test_share_value_calculation passed.");
    }

    function test_shares_for_amount_calculation() public {
        console.log("Starting test_shares_for_amount_calculation...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        console.log("Initial deposit complete.");

        uint256 testAmount = 50 ether;
        console.log("Calculating shares for amount:", testAmount);
        uint256 expectedShares = vault._sharesForAmountPublic_(testAmount);
        console.log("Calculated shares:", expectedShares);

        assertTrue(expectedShares > 0, "Should get shares for positive amount");

        console.log("test_shares_for_amount_calculation passed.");
    }

    function test_zero_share_issuance() public {
        console.log("Starting test_zero_share_issuance...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        console.log("Attempting deposit with zero amount...");
        vm.expectRevert("Vault: zero amount");
        vault.deposit(0, address(this));
        console.log("test_zero_share_issuance passed.");
    }

    function test_transfer_to_zero_address() public {
        console.log("Starting test_transfer_to_zero_address...");
        token.mint(address(this), 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether, address(this));
        console.log("Initial deposit complete.");

        console.log("Testing transfer to zero address...");
        vm.expectRevert("Vault: bad to");
        vault.transfer(address(0), 10 ether);

        console.log("Testing transfer to vault address...");
        vm.expectRevert("Vault: bad to");
        vault.transfer(address(vault), 10 ether);

        console.log("test_transfer_to_zero_address passed.");
    }
}
