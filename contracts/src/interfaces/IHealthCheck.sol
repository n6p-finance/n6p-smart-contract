// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

/**
 * This interface is here for the HealthCheck to interact with different strategies.
 * Each strategy should implement this interface to ensure compatibility.
 */
interface IHealthCheck {
    // Basic health check information
    // - check: The function to perform the health check
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}