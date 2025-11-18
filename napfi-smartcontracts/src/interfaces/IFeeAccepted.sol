// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IFeeAccepted.sol
// Minimal stub so strategies can expose fee configuration to the vault
interface IFeeAccepted {
    function performanceFee() external view returns (uint256);
    function managementFee() external view returns (uint256);
}
