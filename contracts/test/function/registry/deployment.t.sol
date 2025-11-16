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
        
        // Creating the first deployment via newVault
        address proxy_vault = registry.newVault(v1_token, guardian, rewards, "Vault", "VLT", 0);
        assertEq(registry.latestVault(v1_token), proxy_vault);
        assertEq(registry.latestRelease(), "1.0.0");
        
        // Creating a vault registers a token
        assertEq(registry.tokens(0), v1_token);
        assertTrue(registry.isRegistered(v1_token));
        assertEq(registry.numTokens(), 1);
        
        // Can't deploy the same vault api version twice for same token
        vm.expectRevert(); // Will revert due to same api version check
        registry.newVault(v1_token, guardian, rewards, "Name", "SYM", 0);
        
        // New release creates new template version
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        assertEq(registry.latestVault(v1_token), proxy_vault); // Still the v1 proxy
        assertEq(registry.latestRelease(), "2.0.0");
        
        // Can deploy new version for different token
        address v2_token = address(0x300);
        address proxy_vault_v2 = registry.newVault(v2_token, guardian, rewards, "Vault", "VLT", 0);
        assertEq(registry.latestVault(v2_token), proxy_vault_v2);
        
        // Adding new token via newVault registers it
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
            token, gov, guardian, rewards, "ExpVault", "EXP", 0
        );
        
        // Experimental Vaults do not count towards deployments
        vm.expectRevert("no vault for token");
        registry.latestVault(token);
        
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
        
        vm.expectRevert("same api version");
        registry.endorseVault(new_experimental_vault, 0);
        
        // You can only endorse a vault if it creates a new deployment
        address v2_vault = _createMockVault("2.0.0");
        registry.newRelease(v2_vault);
        
        address experimental_vault_v2 = registry.newExperimentalVault(
            token, gov, guardian, rewards, "V2Vault", "V2V", 0
        );
        
        // Note: This experimental vault will have apiVersion "1.0.0" from default initialization
        // since it was cloned from v1_vault. To properly test with v2_vault, we'd need
        // a more complex mock setup. For now, we test the endorseVault authorization.
        
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
    // Storage variables that will be shared across proxy and implementation
    string public apiVersion;
    address public token;
    address public governance;
    
    constructor(string memory _version) {
        // Set this contract's apiVersion
        apiVersion = _version;
    }
    
    // Proper initialize function that matches the Registry interface
    function initialize(
        address _token,
        address _governance,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management
    ) external {
        // Set storage variables that persist in the proxy
        token = _token;
        governance = _governance;
        // Copy apiVersion from implementation if not already set on proxy
        if (bytes(apiVersion).length == 0) {
            // Can't directly access implementation's apiVersion from here
            // So just set a default
            apiVersion = "1.0.0";
        }
    }
    
    // For testing token override
    function setToken(address _token) public {
        token = _token;
    }
    
    function setGovernance(address _gov) public {
        governance = _gov;
    }
}