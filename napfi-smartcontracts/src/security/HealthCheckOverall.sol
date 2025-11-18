// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * HealthCheckOverall.sol
 * Yearn-inspired safety overlay: aggregate checks across strategies.
 * TODO: implement thresholds, emergency shutdown, and governance hooks.
 */
contract HealthCheckOverall {
    function isHealthy(address[] calldata strategies) external view returns (bool) {
        // TODO: implement composite checks
        return true;
    }
}
