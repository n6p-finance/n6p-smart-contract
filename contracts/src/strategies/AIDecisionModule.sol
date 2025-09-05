// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./StrategyRegistry.sol";

contract AIDecisionModule is Ownable {
    StrategyRegistry public strategyRegistry;
    // Risk profile => Strategy allocation weights
    mapping(uint256 => mapping(address => uint256)) public riskProfileWeights;
    // Risk profile => Total weight
    mapping(uint256 => uint256) public totalWeights;

    event AllocationUpdated(uint256 riskProfile, address indexed strategy, uint256 weight);

    constructor(address _strategyRegistry, address _initialOwner) Ownable(_initialOwner) {
        require(_strategyRegistry != address(0), "StrategyRegistry zero");
        strategyRegistry = StrategyRegistry(_strategyRegistry);
    }

    function setAllocationWeights(uint256 _riskProfile, address[] calldata _strategies, uint256[] calldata _weights) external onlyOwner {
        require(_strategies.length == _weights.length, "Mismatched arrays");
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(strategyRegistry.approvedStrategies(_strategies[i]), "Invalid strategy");
            riskProfileWeights[_riskProfile][_strategies[i]] = _weights[i];
            totalWeight += _weights[i];
            emit AllocationUpdated(_riskProfile, _strategies[i], _weights[i]);
        }
        totalWeights[_riskProfile] = totalWeight;
    }

    function allocateFunds(uint256 _amount, uint256 _riskProfile) external view returns (address[] memory strategies, uint256[] memory amounts) {
        uint256 strategyCount = strategyRegistry.getStrategyCount();
        strategies = new address[](strategyCount);
        amounts = new uint256[](strategyCount);
        uint256 totalWeight = totalWeights[_riskProfile];

        if (totalWeight == 0) {
            // Default: equal allocation to all approved strategies
            uint256 amountPerStrategy = _amount / strategyCount;
            for (uint256 i = 0; i < strategyCount; i++) {
                (address strategy,,) = strategyRegistry.getStrategyInfo(i);
                strategies[i] = strategy;
                amounts[i] = amountPerStrategy;
            }
        } else {
            // Allocate based on weights
            for (uint256 i = 0; i < strategyCount; i++) {
                (address strategy,,) = strategyRegistry.getStrategyInfo(i);
                strategies[i] = strategy;
                amounts[i] = (_amount * riskProfileWeights[_riskProfile][strategy]) / totalWeight;
            }
        }
    }
}