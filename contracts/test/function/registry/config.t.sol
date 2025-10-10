// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/core/Registry.sol";

contract ConfigTest is Test {
    Registry public registry;
    address public gov;
    address public rando;
    
    function setUp() public {
        gov = address(this);
        rando = address(0x123);
        registry = new Registry(); // No constructor arguments
    }
    
    function test_registry_deployment() public virtual {
        assertEq(registry.governance(), gov); // msg.sender in constructor
        assertEq(registry.numReleases(), 0);
    }
    
    function test_registry_setGovernance() public {
        address newGov = rando;
        
        // No one can set governance but governance
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.setGovernance(newGov);
        
        // Governance doesn't change until it's accepted
        registry.setGovernance(newGov);
        assertEq(registry.pendingGovernance(), newGov);
        assertEq(registry.governance(), gov);
        
        // Only new governance can accept a change of governance
        vm.expectRevert("unauthorized");
        registry.acceptGovernance();
        
        // Governance doesn't change until it's accepted
        vm.prank(newGov);
        registry.acceptGovernance();
        assertEq(registry.governance(), newGov);
        
        // No one can set governance but governance
        vm.expectRevert("unauthorized");
        registry.setGovernance(newGov);
        
        // Only new governance can accept a change of governance
        vm.expectRevert("unauthorized");
        registry.acceptGovernance();
    }
    
    function test_banksy() public {
        // Create a mock vault
        address vault = address(0x456);
        
        // Mock the vault's apiVersion function
        vm.mockCall(vault, abi.encodeWithSignature("apiVersion()"), abi.encode("1.0.0"));
        
        registry.newRelease(vault);
        assertEq(registry.tags(vault), "");
        
        // Not just anyone can tag a Vault, only a Banksy can!
        vm.prank(rando);
        vm.expectRevert("not banksy");
        registry.tagVault(vault, "Anything I want!");
        
        // Not just anyone can become a banksy either
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.setBanksy(rando, true);
        
        assertFalse(registry.banksy(rando));
        registry.setBanksy(rando, true);
        assertTrue(registry.banksy(rando));
        
        vm.prank(rando);
        registry.tagVault(vault, "Anything I want!");
        assertEq(registry.tags(vault), "Anything I want!");
        
        registry.setBanksy(rando, false);
        
        vm.prank(rando);
        vm.expectRevert("not banksy");
        registry.tagVault(vault, "");
        
        assertFalse(registry.banksy(gov));
        // Governance can always tag
        registry.tagVault(vault, "");
    }
}