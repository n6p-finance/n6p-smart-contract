// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IStrategyAPI.sol
// Minimal lifecycle hooks and bookkeeping helpers expected from strategies
interface IStrategyAPI {
    function invest() external;
    function divest(uint256 amount) external;
    function totalAssets() external view returns (uint256);
}
