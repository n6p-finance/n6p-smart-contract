// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/core/Vault/Vault.sol";
import "../src/core/Registry/Registry.sol";

/**
 * @title Advanced Base Sepolia Deployment
 * @notice Full deployment with registry integration and vault factory pattern
 */

interface IRegistry {
    function newRelease(address vault) external;
    function newVault(
        address token,
        address guardian,
        address rewards,
        string calldata name,
        string calldata symbol,
        uint256 releaseDelta
    ) external returns (address);
    function latestVault(address token) external view returns (address);
}

interface IVaultInit {
    function initialize(
        address token,
        address governance,
        address rewards,
        string calldata name,
        string calldata symbol,
        address guardian,
        address management
    ) external;
}

contract DeploymentHelper is Script {
    // ============ Configuration ============
    address public constant MANAGEMENT = 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D;
    address public constant GUARDIAN  = 0x005684aC7C737Bff821ECCb377cC46e5A7dcB60D;
    
    // Base Sepolia test tokens (if any exist, otherwise deploy mock)
    address public constant BASE_SEPOLIA_USDC = 0x0000000000000000000000000000000000000000; // Replace with actual
    
    // ============ Deployment Records ============
    struct DeploymentRecord {
        string name;
        address contractAddress;
        string contractType;
        uint256 timestamp;
    }
    
    DeploymentRecord[] public deployments;
    
    function recordDeployment(
        string memory name,
        address contractAddress,
        string memory contractType
    ) public {
        deployments.push(
            DeploymentRecord({
                name: name,
                contractAddress: contractAddress,
                contractType: contractType,
                timestamp: block.timestamp
            })
        );
    }
    
    // ============ Deployment Functions ============
    
    /**
     * @notice Deploy Registry contract
     */
    function deployRegistry() internal returns (address) {
        bytes memory bytecode = type(Registry).creationCode;
        address deployed;
        assembly {
            deployed := create(0, add(bytecode, 32), mload(bytecode))
        }
        require(deployed != address(0), "Registry deployment failed");
        recordDeployment("Registry", deployed, "Registry");
        return deployed;
    }
    
    /**
     * @notice Deploy Vault implementation
     */
    function deployVaultImplementation() internal returns (address) {
        bytes memory bytecode = type(Vault).creationCode;
        address deployed;
        assembly {
            deployed := create(0, add(bytecode, 32), mload(bytecode))
        }
        require(deployed != address(0), "Vault implementation deployment failed");
        recordDeployment("UnifiedVault", deployed, "VaultImplementation");
        return deployed;
    }
    
    /**
     * @notice Register vault implementation as release in registry
     */
    function registerVaultRelease(address registry, address vaultImpl) internal {
        IRegistry(registry).newRelease(vaultImpl);
        console2.log("Vault registered as release in Registry");
    }
    
    /**
     * @notice Deploy vault proxy for specific token
     */
    function deployVaultProxy(
        address registry,
        address token,
        string memory name,
        string memory symbol
    ) internal returns (address) {
        address vaultProxy = IRegistry(registry).newVault(
            token,
            GUARDIAN,
            MANAGEMENT,
            name,
            symbol,
            0 // releaseDelta: use latest release
        );
        recordDeployment(name, vaultProxy, "VaultProxy");
        return vaultProxy;
    }
    
    // ============ Utility Functions ============
    
    function getDeploymentsCount() external view returns (uint256) {
        return deployments.length;
    }
    
    function getDeployment(uint256 index) external view returns (DeploymentRecord memory) {
        return deployments[index];
    }
    
    function exportDeployments() external view returns (string memory) {
        string memory result = "DEPLOYMENT_ADDRESSES={\n";
        for (uint256 i = 0; i < deployments.length; i++) {
            result = string(abi.encodePacked(
                result,
                '  "',
                deployments[i].name,
                '": "',
                addressToString(deployments[i].contractAddress),
                '",\n'
            ));
        }
        result = string(abi.encodePacked(result, "}"));
        return result;
    }
    
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

// Import placeholders for actual contract interfaces
bytes memory bytecode = type(Registry).creationCode;


interface Vault {
    // Placeholder - actual interface from UnifiedVault.sol
}
