// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IStrategy.sol";

contract AIDecisionModule {
    address[] public strategies;
    mapping(address => uint256) public lastAllocation;

    event AllocationDecided(address indexed strategy, uint256 amount);

    function addStrategy(address _strategy) external {
        strategies.push(_strategy);
    }

    function decideAllocation(uint256 totalAmount) external returns (address[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](strategies.length);
        for (uint i = 0; i < strategies.length; i++) {
            amounts[i] = totalAmount / strategies.length; // Equal distribution (simplified)
            emit AllocationDecided(strategies[i], amounts[i]);
        }
        return (strategies, amounts);
    }
}