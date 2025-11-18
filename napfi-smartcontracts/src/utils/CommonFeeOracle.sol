// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * CommonFeeOracle.sol
 * Computes management/performance fees on strategy returns.
 * TODO: implement fee logic and proper accounting.
 */
contract CommonFeeOracle {
    function computeManagementFee(uint256 assets, uint256 feeBps) external pure returns (uint256) {
        return (assets * feeBps) / 10000;
    }

    function computePerformanceFee(uint256 profit, uint256 feeBps) external pure returns (uint256) {
        return (profit * feeBps) / 10000;
    }
}
