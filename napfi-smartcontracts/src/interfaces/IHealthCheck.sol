// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IHealthCheck.sol
// A simple interface to allow checking if strategy state is healthy
interface IHealthCheck {
    function check() external view returns (bool);
}
