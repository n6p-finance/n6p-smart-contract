// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IStrategyAPI.sol";

/**
 * BaseStrategy.sol
 * Abstract base class for strategies (DeFi + RWA). Provide common lifecycle hooks.
 * TODO: implement authorization, accounting, and integration with the vault.
 */
abstract contract BaseStrategy is IStrategyAPI {
    address public vault;

    constructor(address _vault) {
        vault = _vault;
    }

    // Basic hooks for derived strategies
    function invest() external virtual override {
        // TODO: implement in concrete strategy
    }

    function divest(uint256 amount) external virtual override {
        // TODO: implement in concrete strategy
    }

    function totalAssets() external view virtual override returns (uint256) {
        return 0;
    }
}
