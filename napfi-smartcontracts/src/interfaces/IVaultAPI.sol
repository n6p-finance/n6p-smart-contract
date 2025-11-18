// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IVaultAPI.sol
// Minimal external API a vault should expose for strategies and registries
interface IVaultAPI {
    function reportGain(uint256 amount) external;
    function reportLoss(uint256 amount) external;
}
