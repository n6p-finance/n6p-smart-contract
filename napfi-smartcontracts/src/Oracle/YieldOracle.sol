// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * YieldOracle.sol
 * Returns mock APY info or strategy yield estimates.
 */
contract YieldOracle {
    mapping(address => uint256) public apyBasisPoints;

    function setAPY(address strategy, uint256 apyBps) external {
        // TODO: restrict in real implementation
        apyBasisPoints[strategy] = apyBps;
    }

    function getAPY(address strategy) external view returns (uint256) {
        return apyBasisPoints[strategy];
    }
}
