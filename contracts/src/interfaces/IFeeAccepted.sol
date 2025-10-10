// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

/**
 * This interface is here for the Fee Accepted to interact with different strategies.
 * Each strategy should implement this interface to ensure compatibility.
 */

interface IFeeAccepted {
    function isFeeAccepted() external view returns (bool);
}