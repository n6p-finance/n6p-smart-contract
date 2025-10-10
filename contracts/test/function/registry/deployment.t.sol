// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/core/Registry.sol";

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
        registry = new Registry(); // No constructor arguments
    }
    
    function test_deployment_management() public {
        address v1_token = address(0x100);
        
        // No deployments yet for token
        vm.expectRevert("no vault for token");
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
        registry.endorseVault(v1_vault, 0); // Add releaseDelta parameter
        assertEq(registry.latestVault(v1_token), v1_vault);
        assertEq(registry.latestRelease(), "1.0.0");
        
        // Endorsing a vault with a new token registers a new token
        assertEq(registry.tokens(0), v1_token);
        assertTrue(registry.isRegistered(v1_token));
        assertEq(registry.numTokens(), 1);
        
        // Can't deploy the same vault api version twice, proxy or not
        vm.expectRevert(); // Will revert due to same api version check
        registry.newVault(v1_token, guardian, rewards, "Name", "SYM", 0);
        
        // New release overrides previous release
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        assertEq(registry.latestVault(v1_token), v1_vault);
        assertEq(registry.latestRelease(), "2.0.0");
        
        // You can deploy proxy Vaults, linked to the latest release
        assertEq(registry.numTokens(), 1);
        
        // Create a new vault with latest release (releaseDelta = 0)
        address proxy_vault = registry.newVault(v1_token, guardian, rewards, "Vault", "VLT", 0);
        assertEq(registry.latestVault(v1_token), proxy_vault);
        
        // Tokens can only be registered one time (no duplicates)
        assertEq(registry.numTokens(), 1);
        
        // You can deploy proxy Vaults, linked to a previous release
        address v2_token = address(0x300);
        address proxy_vault_v1 = registry.newVault(v2_token, guardian, rewards, "Vault", "VLT", 1); // releaseDelta = 1 for previous version
        assertEq(registry.latestVault(v2_token), proxy_vault_v1);
        
        // Adding a new endorsed vault with `newVault()` registers a new token
        assertEq(registry.tokens(0), v1_token);
        assertEq(registry.tokens(1), v2_token);
        assertTrue(registry.isRegistered(v1_token));
        assertTrue(registry.isRegistered(v2_token));
        assertEq(registry.numTokens(), 2);
        
        // Not just anyone can create a new endorsed Vault, only governance can!
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.newVault(address(0x500), guardian, rewards, "Name", "SYM", 0);
    }
    
    function test_experimental_deployments() public {
        address v1_vault = _createMockVault("1.0.0");
        registry.newRelease(v1_vault);
        
        // Anyone can make an experiment
        address token = address(0x600);
        address experimental_vault = registry.newExperimentalVault(
            token, rando, guardian, rewards, "ExpVault", "EXP", 0
        );
        
        // You can make as many experiments as you want with same api version
        address experimental_vault2 = registry.newExperimentalVault(
            token, rando, guardian, rewards, "ExpVault2", "EXP2", 0
        );
        
        // Experimental Vaults do not count towards deployments
        vm.expectRevert("no vault for token");
        registry.latestVault(token);
        
        // You can't endorse a vault if governance isn't set properly
        vm.expectRevert("not governed");
        registry.endorseVault(experimental_vault, 0);
        
        // Mock governance acceptance for the vault
        vm.mockCall(
            experimental_vault,
            abi.encodeWithSignature("governance()"),
            abi.encode(gov)
        );
        
        // New experimental (unendorsed) vaults should not register tokens
        assertEq(registry.tokens(0), address(0));
        assertFalse(registry.isRegistered(token));
        assertEq(registry.numTokens(), 0);
        
        // You can only endorse a vault if it creates an new deployment
        registry.endorseVault(experimental_vault, 0);
        assertEq(registry.latestVault(token), experimental_vault);
        
        // Endorsing experimental vaults should register a token
        assertEq(registry.tokens(0), token);
        assertTrue(registry.isRegistered(token));
        assertEq(registry.numTokens(), 1);
        
        // You can't endorse a vault if it would overwrite a current deployment
        address new_experimental_vault = registry.newExperimentalVault(
            token, gov, guardian, rewards, "NewExp", "NEXP", 0
        );
        
        // Mock governance for the new experimental vault
        vm.mockCall(
            new_experimental_vault,
            abi.encodeWithSignature("governance()"),
            abi.encode(gov)
        );
        
        vm.expectRevert("same api version");
        registry.endorseVault(new_experimental_vault, 0);
        
        // You can only endorse a vault if it creates a new deployment
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        
        address experimental_vault_v2 = registry.newExperimentalVault(
            token, gov, guardian, rewards, "V2Vault", "V2V", 0
        );
        
        // Mock governance for v2 vault
        vm.mockCall(
            experimental_vault_v2,
            abi.encodeWithSignature("governance()"),
            abi.encode(gov)
        );
        
        registry.endorseVault(experimental_vault_v2, 0);
        assertEq(registry.latestVault(token), experimental_vault_v2);
        
        // Can create an experiment and endorse it targeting a previous version
        address new_token = address(0xA00);
        address experimental_vault_v1 = registry.newExperimentalVault(
            new_token, gov, guardian, rewards, "V1Vault", "V1V", 1
        );
        
        // Mock governance and token for v1 vault
        vm.mockCall(
            experimental_vault_v1,
            abi.encodeWithSignature("governance()"),
            abi.encode(gov)
        );
        vm.mockCall(
            experimental_vault_v1,
            abi.encodeWithSignature("token()"),
            abi.encode(new_token)
        );
        
        registry.endorseVault(experimental_vault_v1, 1);
        assertEq(registry.latestVault(new_token), experimental_vault_v1);
        
        // Only governance can endorse a Vault
        address vault = _createMockVault("3.0.0");
        vm.prank(rando);
        vm.expectRevert("unauthorized");
        registry.endorseVault(vault, 0);
    }
    
    function _createMockVault(string memory version) internal returns (address) {
        // Create a mock vault contract that implements the required interfaces
        MockVault vault = new MockVault(version);
        return address(vault);
    }
}

contract MockVault {
    string public apiVersion;
    address public token;
    address public governance;
    
    constructor(string memory _version) {
        apiVersion = _version;
        governance = msg.sender; // Set governance to deployer for testing
        token = address(0x100); // Default token for testing
    }
    
    // For testing token override
    function setToken(address _token) public {
        token = _token;
    }
    
    function setGovernance(address _gov) public {
        governance = _gov;
    }
}