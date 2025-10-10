// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/core/Registry.sol";

contract ConfigTest is Test {
    Registry public registry;
    address public gov;
    address public rando;

    function setUp() public {
        console.log("=== Setting up ConfigTest ===");
        gov = address(this);
        rando = address(0x123);

        console.log("Deploying Registry...");
        registry = new Registry(); // No constructor arguments
        console.log("Registry deployed at:", address(registry));
        console.log("=== Setup completed ===\n");
    }

    function test_registry_deployment() public virtual {
        console.log("=== Testing registry deployment ===");
        console.log("Checking governance address...");
        assertEq(registry.governance(), gov);
        console.log("Governance address verified:", registry.governance());

        console.log("Checking number of releases...");
        assertEq(registry.numReleases(), 0);
        console.log("Number of releases verified:", registry.numReleases());
        console.log("=== Registry deployment test passed ===\n");
    }

    function test_registry_setGovernance() public {
        console.log("=== Testing governance changes ===");
        address newGov = rando;

        console.log("Testing unauthorized governance change...");
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.setGovernance(newGov);
        console.log("Unauthorized governance change correctly blocked");

        console.log("Setting governance from current governance...");
        registry.setGovernance(newGov);
        assertEq(registry.pendingGovernance(), newGov);
        assertEq(registry.governance(), gov);
        console.log("Pending governance set to:", newGov);
        console.log("Current governance still:", registry.governance());

        console.log("Testing unauthorized acceptGovernance call...");
        vm.expectRevert("unauthorized");
        registry.acceptGovernance();
        console.log("Unauthorized acceptGovernance correctly blocked");

        console.log("New governance accepting change...");
        vm.prank(newGov);
        registry.acceptGovernance();
        assertEq(registry.governance(), newGov);
        console.log("Governance successfully changed to:", registry.governance());

        console.log("Testing unauthorized governance changes after switch...");
        vm.expectRevert("unauthorized");
        registry.setGovernance(newGov);

        vm.expectRevert("unauthorized");
        registry.acceptGovernance();
        console.log("Unauthorized actions correctly blocked after governance change");
        console.log("=== Governance change tests passed ===\n");
    }

    function test_banksy() public {
        console.log("=== Testing Banksy tagging system ===");

        // Create a mock vault
        address vault = address(0x456);
        console.log("Mock vault created at:", vault);

        // Mock the vault's apiVersion function
        vm.mockCall(vault, abi.encodeWithSignature("apiVersion()"), abi.encode("1.0.0"));
        console.log("Mocked vault apiVersion() call to return 1.0.0");

        console.log("Adding new release...");
        registry.newRelease(vault);
        assertEq(registry.tags(vault), "");
        console.log("New release added for vault:", vault);

        console.log("Testing unauthorized tagging...");
        vm.prank(rando);
        vm.expectRevert("not banksy");
        registry.tagVault(vault, "Anything I want!");
        console.log("Unauthorized tagging correctly blocked");

        console.log("Testing unauthorized setBanksy call...");
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.setBanksy(rando, true);
        console.log("Unauthorized setBanksy call correctly blocked");

        console.log("Granting Banksy role...");
        registry.setBanksy(rando, true);
        assertTrue(registry.banksy(rando));
        console.log("Banksy role granted to:", rando);

        console.log("Banksy tagging the vault...");
        vm.prank(rando);
        registry.tagVault(vault, "Anything I want!");
        assertEq(registry.tags(vault), "Anything I want!");
        console.log("Vault tagged successfully:", registry.tags(vault));

        console.log("Revoking Banksy role...");
        registry.setBanksy(rando, false);
        assertFalse(registry.banksy(rando));
        console.log("Banksy role revoked for:", rando);

        console.log("Testing unauthorized tagging after revocation...");
        vm.prank(rando);
        vm.expectRevert("not banksy");
        registry.tagVault(vault, "");
        console.log("Unauthorized tagging correctly blocked after revocation");

        console.log("Checking governance can always tag...");
        assertFalse(registry.banksy(gov));
        registry.tagVault(vault, "");
        console.log("Governance successfully tagged the vault:", registry.tags(vault));

        console.log("=== Banksy tagging system tests passed ===\n");
    }
}
