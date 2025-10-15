// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/core/DeFi/VaultDeFi.sol";

contract DeployScript is Script {
    // =========================
    // Configuration
    // =========================
    address constant TOKEN = 0x917d4281AFAfb9d8965707A3EFa398dd4Be66dc6;
    address constant GOVERNANCE = 0x530b83Cb444c300b433bB35B60b94422C5030Be3;
    address constant REWARDS = 0x530b83Cb444c300b433bB35B60b94422C5030Be3;
    address constant GUARDIAN = 0x530b83Cb444c300b433bB35B60b94422C5030Be3;
    address constant MANAGEMENT = 0x530b83Cb444c300b433bB35B60b94422C5030Be3;

    string constant NAME = "Vault Token";
    string constant SYMBOL = "vTOKEN";

    // =========================
    // Helpers
    // =========================
    function DEFAULT_VAULT_NAME(address token) public view returns (string memory) {
        return string(abi.encodePacked(MockToken(token).symbol(), " yVault"));
    }

    function DEFAULT_VAULT_SYMBOL(address token) public view returns (string memory) {
        return string(abi.encodePacked("yv", MockToken(token).symbol()));
    }

    // =========================
    // Deploy UUPS Proxy Vault
    // =========================
    function deployUUPSProxyVault() public returns (address vault) {
        vm.startBroadcast();

        // Deploy Vault implementation
        Vault vaultImpl = new Vault();

        // Prepare initializer data
        bytes memory initData = abi.encodeWithSelector(
            Vault.initialize.selector,
            TOKEN,
            GOVERNANCE,
            REWARDS,
            NAME,
            SYMBOL,
            GUARDIAN,
            MANAGEMENT
        );

        // Deploy UUPS proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(vaultImpl), initData);
        vault = address(proxy);

        console.log("UUPS Proxy Vault deployed at:", vault);
        console.log("Implementation at:", address(vaultImpl));

        vm.stopBroadcast();
    }

    // =========================
    // Main entry
    // =========================
    function run() external {
        deployUUPSProxyVault();
    }
}

// Minimal interface for your token symbol
interface MockToken {
    function symbol() external view returns (string memory);
}
