// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Math.sol
 * Minimal math helpers for fixed-point operations. Consider using PRBMath or ABDK in production.
 */
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
