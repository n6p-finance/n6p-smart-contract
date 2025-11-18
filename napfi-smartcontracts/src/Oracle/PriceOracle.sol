// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * PriceOracle.sol
 * Mock price oracle for dev/testing. Replace with an on-chain oracle adapter in production.
 */
contract PriceOracle {
    // TODO: wire to Chainlink /acles / other oracles
    mapping(address => uint256) public prices;

    function setPrice(address asset, uint256 price) external {
        // TODO: restrict to owner in real implementation
        prices[asset] = price;
    }

    function getPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }
}
