// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStrategy {
    function getBalance(address account) external view returns (uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function apy() external view returns (uint256);
    function generateYield() external;
}
