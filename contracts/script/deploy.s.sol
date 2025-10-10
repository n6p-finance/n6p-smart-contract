// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

import {Vault} from "../src/core/DeFi/VaultDeFi.sol";

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

contract DeployScript {
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
        num_releases = IRegistry(registry).numReleases() - 1;
        target_release_index = num_releases; // default to latest
        release_delta = 0;
    }

    // Compute release delta from chosen target index
    function computeReleaseDelta(address registry, uint256 target_release_index) public view returns (uint256) {
        uint256 num_releases = IRegistry(registry).numReleases() - 1;
        require(target_release_index <= num_releases, "bad index");
        return num_releases - target_release_index;
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

        // Empty string means use default inside Vault.initialize (parity with deploy.py intent)
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
        Vault v = new Vault();
        // Empty string implies default naming inside the Vault
        string memory nameOrEmpty = keccak256(bytes(name)) == keccak256(bytes(DEFAULT_VAULT_NAME(token))) ? "" : name;
        string memory symbolOrEmpty = keccak256(bytes(symbol)) == keccak256(bytes(DEFAULT_VAULT_SYMBOL(token))) ? "" : symbol;
        v.initialize(token, gov, rewards, nameOrEmpty, symbolOrEmpty, guardian, management);
        vault = address(v);
    }
}


