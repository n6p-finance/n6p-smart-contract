// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/core/Registry.sol";
import "../../../src/core/DeFi/VaultDeFi.sol";

contract DeploymentTest is Test {
    Registry public registry;
    address public gov;
    address public guardian;
    address public rewards;
    address public management;
    address public rando;
    
    function setUp() public {
        gov = address(this);
        guardian = address(0x1);
        rewards = address(0x2);
        management = address(0x3);
        rando = address(0x123);
        registry = new Registry(gov);
    }
    
    function test_deployment_management() public {
        address v1_token = address(0x100);
        
        // No deployments yet for token
        vm.expectRevert();
        registry.latestVault(v1_token);
        
        // Token tracking state variables should start off uninitialized
        assertEq(registry.tokens(0), address(0));
        assertFalse(registry.isRegistered(v1_token));
        assertEq(registry.numTokens(), 0);
        
        // New release does not add new token
        address v1_vault = _createMockVault("1.0.0");
        registry.newRelease(v1_vault);
        assertEq(registry.tokens(0), address(0));
        assertFalse(registry.isRegistered(v1_token));
        assertEq(registry.numTokens(), 0);
        
        // Creating the first deployment makes `latestVault()` work
        registry.endorseVault(v1_vault);
        assertEq(registry.latestVault(v1_token), v1_vault);
        assertEq(registry.latestRelease(), "1.0.0");
        
        // Endorsing a vault with a new token registers a new token
        assertEq(registry.tokens(0), v1_token);
        assertTrue(registry.isRegistered(v1_token));
        assertEq(registry.numTokens(), 1);
        
        // Can't deploy the same vault api version twice, proxy or not
        vm.expectRevert();
        registry.newVault(v1_token, guardian, rewards, "", "");
        
        // New release overrides previous release
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        assertEq(registry.latestVault(v1_token), v1_vault);
        assertEq(registry.latestRelease(), "2.0.0");
        
        // You can deploy proxy Vaults, linked to the latest release
        assertEq(registry.numTokens(), 1);
        
        // Mock the newVault call to return a new vault address
        address proxy_vault = address(0x200);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newVault.selector, v1_token, guardian, rewards, "", ""),
            abi.encode(proxy_vault)
        );
        
        address result = registry.newVault(v1_token, guardian, rewards, "", "");
        assertEq(result, proxy_vault);
        assertEq(registry.latestVault(v1_token), proxy_vault);
        
        // Tokens can only be registered one time (no duplicates)
        assertEq(registry.numTokens(), 1);
        
        // You can deploy proxy Vaults, linked to a previous release
        address v2_token = address(0x300);
        address proxy_vault_v1 = address(0x400);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newVault.selector, v2_token, guardian, rewards, "", "", 1),
            abi.encode(proxy_vault_v1)
        );
        
        result = registry.newVault(v2_token, guardian, rewards, "", "", 1);
        assertEq(result, proxy_vault_v1);
        assertEq(registry.latestVault(v2_token), proxy_vault_v1);
        
        // Adding a new endorsed vault with `newVault()` registers a new token
        assertEq(registry.tokens(0), v1_token);
        assertEq(registry.tokens(1), v2_token);
        assertTrue(registry.isRegistered(v1_token));
        assertTrue(registry.isRegistered(v2_token));
        assertEq(registry.numTokens(), 2);
        
        // Not just anyone can create a new endorsed Vault, only governance can!
        vm.prank(rando);
        vm.expectRevert();
        registry.newVault(address(0x500), guardian, rewards, "", "");
    }
    
    function test_experimental_deployments() public {
        address v1_vault = _createMockVault("1.0.0");
        registry.newRelease(v1_vault);
        
        // Anyone can make an experiment
        address token = address(0x600);
        
        // Mock the newExperimentalVault call
        address experimental_vault = address(0x700);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newExperimentalVault.selector, token, rando, rando, rando, "", ""),
            abi.encode(experimental_vault)
        );
        
        vm.prank(rando);
        address result = registry.newExperimentalVault(token, rando, rando, rando, "", "");
        assertEq(result, experimental_vault);
        
        // You can make as many experiments as you want with same api version
        vm.prank(rando);
        registry.newExperimentalVault(token, rando, rando, rando, "", "");
        
        // Experimental Vaults do not count towards deployments
        vm.expectRevert();
        registry.latestVault(token);
        
        // You can't endorse a vault if governance isn't set properly
        vm.expectRevert();
        registry.endorseVault(experimental_vault);
        
        // Mock governance acceptance
        vm.mockCall(
            experimental_vault,
            abi.encodeWithSignature("setGovernance(address)", gov),
            abi.encode()
        );
        vm.mockCall(
            experimental_vault,
            abi.encodeWithSignature("acceptGovernance()"),
            abi.encode()
        );
        
        // New experimental (unendorsed) vaults should not register tokens
        assertEq(registry.tokens(0), address(0));
        assertFalse(registry.isRegistered(token));
        assertEq(registry.numTokens(), 0);
        
        // You can only endorse a vault if it creates an new deployment
        registry.endorseVault(experimental_vault);
        assertEq(registry.latestVault(token), experimental_vault);
        
        // Endorsing experimental vaults should register a token
        assertEq(registry.tokens(0), token);
        assertTrue(registry.isRegistered(token));
        assertEq(registry.numTokens(), 1);
        
        // You can't endorse a vault if it would overwrite a current deployment
        address new_experimental_vault = address(0x800);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newExperimentalVault.selector, token, gov, gov, gov, "", ""),
            abi.encode(new_experimental_vault)
        );
        
        vm.prank(rando);
        registry.newExperimentalVault(token, gov, gov, gov, "", "");
        
        vm.expectRevert();
        registry.endorseVault(new_experimental_vault);
        
        // You can only endorse a vault if it creates a new deployment
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        
        address experimental_vault_v2 = address(0x900);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newExperimentalVault.selector, token, gov, gov, gov, "", ""),
            abi.encode(experimental_vault_v2)
        );
        
        vm.prank(rando);
        registry.newExperimentalVault(token, gov, gov, gov, "", "");
        
        registry.endorseVault(experimental_vault_v2);
        assertEq(registry.latestVault(token), experimental_vault_v2);
        
        // Can create an experiment and endorse it targeting a previous version
        address new_token = address(0xA00);
        address experimental_vault_v1 = address(0xB00);
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(registry.newExperimentalVault.selector, new_token, gov, gov, gov, "", "", 1),
            abi.encode(experimental_vault_v1)
        );
        
        vm.prank(rando);
        registry.newExperimentalVault(new_token, gov, gov, gov, "", "", 1);
        
        registry.endorseVault(experimental_vault_v1, 1);
        assertEq(registry.latestVault(new_token), experimental_vault_v1);
        
        // Only governance can endorse a Vault
        address vault = _createMockVault("3.0.0");
        vm.prank(rando);
        vm.expectRevert();
        registry.endorseVault(vault);
    }
    
    function _createMockVault(string memory version) internal returns (address) {
        address vault = address(new MockVault(version));
        return vault;
    }
}

contract MockVault {
    string public apiVersion;
    
    constructor(string memory _version) {
        apiVersion = _version;
    }
}