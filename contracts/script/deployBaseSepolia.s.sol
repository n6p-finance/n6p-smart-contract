// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/core/Registry.sol";
import "../src/core/DeFi/UnifiedVault.sol";

/**
 * @title Base Sepolia Deployment Script
 * @notice Comprehensive deployment script for all N6P Finance contracts
 * @dev Deploys Registry, Vault implementations, and supporting contracts
 */
contract DeployBaseSepolia is Script {
    // Deployment addresses
    address constant MANAGEMENT_ADDRESS = 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D;
    address constant DEPLOYMENT_ADDRESS = 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D;
    
    // Deployment configuration
    struct DeploymentConfig {
        address governance;
        address management;
        address guardian;
        address rewards;
        address deployer;
    }
    
    struct DeployedAddresses {
        address registry;
        address unifiedVaultImpl;
    }
    
    // State variables
    DeploymentConfig public config;
    DeployedAddresses public deployed;
    
    function run() external {
        // Initialize configuration
        config = DeploymentConfig({
            governance: msg.sender,
            management: MANAGEMENT_ADDRESS,
            guardian: DEPLOYMENT_ADDRESS,
            rewards: MANAGEMENT_ADDRESS,
            deployer: msg.sender
        });
        
        console2.log("=== Base Sepolia N6P Finance Deployment ===");
        console2.log("Governance:", config.governance);
        console2.log("Management:", config.management);
        console2.log("Guardian:", config.guardian);
        console2.log("Rewards:", config.rewards);
        console2.log("");
        
        vm.startBroadcast();
        
        // 1. Deploy Registry
        console2.log("1. Deploying Registry...");
        deployed.registry = deployRegistry();
        
        // 2. Deploy Unified Vault Implementation
        console2.log("2. Deploying UnifiedVault Implementation...");
        deployed.unifiedVaultImpl = deployUnifiedVault();
        
        vm.stopBroadcast();
        
        // 4. Export deployment addresses and ABIs
        console2.log("\n=== Deployment Complete ===");
        exportDeploymentData();
    }
    
    function deployRegistry() internal returns (address) {
        Registry registry = new Registry();
        console2.log("Registry deployed at:", address(registry));
        return address(registry);
    }
    
    function deployUnifiedVault() internal returns (address) {
        Vault vaultImpl = new Vault();
        console2.log("UnifiedVault Implementation deployed at:", address(vaultImpl));
        return address(vaultImpl);
    }
    
    function exportDeploymentData() internal view {
        console2.log("\n=== Deployment Addresses ===");
        console2.log("Registry:", deployed.registry);
        console2.log("UnifiedVault Implementation:", deployed.unifiedVaultImpl);
        console2.log("");
        console2.log("=== Configuration ===");
        console2.log("Governance:", config.governance);
        console2.log("Management:", config.management);
        console2.log("Guardian:", config.guardian);
        console2.log("Rewards:", config.rewards);
        console2.log("");
        console2.log("Export this data to environment file for frontend use.");
    }
}
