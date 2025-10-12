// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/core/DeFi/VaultDeFi.sol";

interface ITokenView {
    function symbol() external view returns (string memory);
}

interface IRegistry {
    function latestRelease() external view returns (string memory);
    function numReleases() external view returns (uint256);
    function releases(uint256) external view returns (address);
    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        address rewards,
        string calldata name,
        string calldata symbol,
        uint256 releaseDelta
    ) external returns (address);
}

interface IVaultViewLite {
    function apiVersion() external view returns (string memory);
}

contract DeployScript is Script {
    // Mirrors variable names/intents from scripts/deploy.py
    // These are convenience view helpers for frontends or off-chain scripts

    function DEFAULT_VAULT_NAME(address token) public view returns (string memory) {
        return string(abi.encodePacked(ITokenView(token).symbol(), " yVault"));
    }

    function DEFAULT_VAULT_SYMBOL(address token) public view returns (string memory) {
        return string(abi.encodePacked("yv", ITokenView(token).symbol()));
    }

    function previewReleaseInfo(address registry)
        external
        view
        returns (
            string memory latest_release,
            uint256 num_releases,
            uint256 target_release_index,
            uint256 release_delta
        )
    {
        latest_release = IRegistry(registry).latestRelease();
        num_releases = IRegistry(registry).numReleases();
        target_release_index = num_releases > 0 ? num_releases - 1 : 0; // Default to latest
        release_delta = 0;
    }

    // Compute release delta from chosen target index
    function computeReleaseDelta(address registry, uint256 target_release_index) public view returns (uint256) {
        uint256 num_releases = IRegistry(registry).numReleases();
        require(target_release_index < num_releases, "bad index");
        return num_releases - 1 - target_release_index;
    }

    // Read target release api version (for display)
    function targetReleaseVersion(address registry, uint256 target_release_index) external view returns (string memory) {
        address tmpl = IRegistry(registry).releases(target_release_index);
        return IVaultViewLite(tmpl).apiVersion();
    }

    // Experimental (proxy) deployment via Registry
    function deployExperimental(
        address registry,
        address token,
        address gov,
        address rewards,
        address guardian,
        string calldata name,
        string calldata symbol,
        uint256 target_release_index
    ) external returns (address vault) {
        uint256 release_delta = computeReleaseDelta(registry, target_release_index);

        // Empty string means use default inside Vault.initialize
        string memory nameOrEmpty = keccak256(bytes(name)) == keccak256(bytes(DEFAULT_VAULT_NAME(token))) ? "" : name;
        string memory symbolOrEmpty = keccak256(bytes(symbol)) == keccak256(bytes(DEFAULT_VAULT_SYMBOL(token))) ? "" : symbol;

        vault = IRegistry(registry).newExperimentalVault(
            token,
            gov,
            guardian,
            rewards,
            nameOrEmpty,
            symbolOrEmpty,
            release_delta
        );
        console.log("Experimental Vault deployed at:", vault);
    }

    // Direct new release deployment (non-proxy), deploy implementation and initialize
    function deployNewRelease(
        address token,
        address gov,
        address rewards,
        address guardian,
        address management,
        string calldata name,
        string calldata symbol
    ) external returns (address vault) {
        vm.startBroadcast();

        Vault v = new Vault();
        // Empty string implies default naming inside the Vault
        string memory nameOrEmpty = keccak256(bytes(name)) == keccak256(bytes(DEFAULT_VAULT_NAME(token))) ? "" : name;
        string memory symbolOrEmpty = keccak256(bytes(symbol)) == keccak256(bytes(DEFAULT_VAULT_SYMBOL(token))) ? "" : symbol;
        v.initialize(token, gov, rewards, nameOrEmpty, symbolOrEmpty, guardian, management);
        vault = address(v);

        console.log("Non-proxy Vault deployed at:", vault);
        vm.stopBroadcast();
    }

    // UUPS proxy deployment
    function deployUUPSProxy(
        address token,
        address gov,
        address rewards,
        address guardian,
        address management,
        string calldata name,
        string calldata symbol
    ) external returns (address vault) {
        vm.startBroadcast();

        // Deploy implementation
        Vault vaultImpl = new Vault();

        // Prepare initializer data
        string memory nameOrEmpty = keccak256(bytes(name)) == keccak256(bytes(DEFAULT_VAULT_NAME(token))) ? "" : name;
        string memory symbolOrEmpty = keccak256(bytes(symbol)) == keccak256(bytes(DEFAULT_VAULT_SYMBOL(token))) ? "" : symbol;
        bytes memory initData = abi.encodeWithSelector(
            Vault.initialize.selector,
            token,
            gov,
            rewards,
            nameOrEmpty,
            symbolOrEmpty,
            guardian,
            management
        );

        // Deploy UUPS proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(vaultImpl), initData);
        vault = address(proxy);

        console.log("UUPS Proxy Vault deployed at:", vault);
        console.log("Implementation at:", address(vaultImpl));
        vm.stopBroadcast();
    }
}