// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./config.t.sol";

contract PermitTest is ConfigTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp(); // from config.t.sol
    }

    function test_permit_functionality() public {
        console.log("Testing EIP-2612 permit functionality...");
        
        // Create test accounts
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = makeAddr("spender");
        
        // Fund the owner with vault shares
        token.mint(owner, 100 ether);
        vm.prank(owner);
        token.approve(address(vault), 100 ether);
        vm.prank(owner);
        vault.deposit(50 ether, owner);
        
        uint256 value = 50 ether;
        uint256 deadline = block.timestamp + 1 days; // before deadline 
        
        // Get current nonce
        uint256 nonce = vault.nonces(owner);
        
        // Build permit digest
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 permitHash = keccak256(
            abi.encode(
                vault.PERMIT_TYPE_HASH(),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, permitHash)
        );
        
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Execute permit
        vault.permit(owner, spender, value, deadline, signature);
        
        // Check that allowance was set
        assertEq(vault.allowance(owner, spender), value, "Allowance not set by permit");
        assertEq(vault.nonces(owner), nonce + 1, "Nonce not incremented");
        
        console.log("Permit functionality test passed");
    }

    function test_permit_expired_deadline() public {
        console.log("Testing permit with expired deadline...");
        
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);
        address spender = makeAddr("spender");
        
        uint256 value = 50 ether;
        uint256 deadline = block.timestamp - 1; // Expired deadline
        // this will return block.timestamp > deadline which it will fail
        bytes memory signature = new bytes(65);
        
        vm.expectRevert();
        vault.permit(owner, spender, value, deadline, signature);
        
        console.log("Expired permit test passed");
    }

    function test_permit_invalid_signature() public {
        console.log("Testing permit with invalid signature...");
        
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
        
        uint256 value = 50 ether;
        uint256 deadline = block.timestamp + 1 days;
        
        // Invalid signature
        bytes memory signature = hex"1234";
        
        vm.expectRevert();
        vault.permit(owner, spender, value, deadline, signature);
        
        console.log("Invalid signature test passed");
    }

    function test_permit_zero_owner() public {
        console.log("Testing permit with zero owner...");
        
        address spender = makeAddr("spender");
        uint256 value = 50 ether;
        uint256 deadline = block.timestamp + 1 days;
        bytes memory signature = new bytes(65);
        
        vm.expectRevert();
        vault.permit(address(0), spender, value, deadline, signature);
        
        console.log("Zero owner permit test passed");
    }

    function test_domain_separator() public virtual {
        console.log("Testing domain separator calculation...");
        
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        
        // Should match expected manual calculation - vault name is "TEST nVault"
        bytes32 expectedSeparator = keccak256(
            abi.encode(
                vault.DOMAIN_TYPE_HASH(),
                keccak256(bytes("TEST nVault")),
                keccak256(bytes("0.4.6")),
                block.chainid,
                address(vault)
            )
        );
        
        assertEq(domainSeparator, expectedSeparator, "Domain separator calculation incorrect");
        
        console.log("Domain separator test passed");
    }

    function test_permit_type_hash() public virtual {
        console.log("Testing permit type hash...");
        
        bytes32 expectedTypeHash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        
        assertEq(vault.PERMIT_TYPE_HASH(), expectedTypeHash, "Permit type hash incorrect");
        
        console.log("Permit type hash test passed");
    }
}