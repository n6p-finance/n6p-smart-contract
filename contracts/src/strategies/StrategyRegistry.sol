// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IStrategy.sol";
import "./YieldOracle.sol";

/// @title StrategyRegistry
/// @notice Manages the registration and deregistration of investment strategies.
/// @dev Inherits from Ownable and ReentrancyGuard for access control and security.
contract StrategyRegistry is Ownable, ReentrancyGuard {
    // Strategy address => is approved
    mapping(address => bool) public approvedStrategies;
    // Strategy address => performance metrics (e.g., APY, TVL)
    mapping(address => StrategyMetrics) public strategyMetrics;
    // List of all registered strategies
    address[] public strategyList;
    // Yield oracle contract to fetch yield data
    YieldOracle public yieldOracle;

    // NOTE: add more metrics as needed
    struct StrategyMetrics {
        uint256 apy; // Annual Percentage Yield
        uint256 tvl; // Total Value Locked
        uint256 lastUpdated; // Timestamp of the last update
    }

    event StrategyApproved(address indexed strategy);
    event StrategyRemoved(address indexed strategy);
    event StrategyMetricsUpdated(address indexed strategy, uint256 apy, uint256 tvl);
    event YieldOracleUpdated(address indexed newOracle);
    event StrategyRegistered(address indexed strategy);
    event StrategyDeregistered(address indexed strategy);
    event StrategyApprovalRevoked(address indexed strategy);
    event StrategyApprovalGranted(address indexed strategy);

    /// @notice Initializes the contract with the owner and yield oracle address.
    /// @param _owner The address of the contract owner.
    /// @param _yieldOracle The address of the yield oracle contract.
    constructor(address _yieldOracle, address _initialOwner) Ownable(_initialOwner) {
        require(_yieldOracle != address(0), "Invalid oracle address");
        yieldOracle = YieldOracle(_yieldOracle);
    }

    function approveStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "Invalid strategy address");
        require(!approvedStrategies[_strategy], "Strategy already approved");
        require(IStrategy(_strategy).apy() > 0, "Strategy must have positive APY");
        require(IStrategy(_strategy).getBalance(address(this)) >= 0, "Strategy must be valid");
        require(yieldOracle.isTrustedSource(_strategy), "Strategy not trusted by oracle");
        require(!isStrategyRegistered(_strategy), "Strategy already registered");
        require(!approvedStrategies[_strategy], "Strategy already approved");
        require(IStrategy(_strategy).supportInterface(type(IStrategy).interfaceId), "Does not implement IStrategy");

        // approve and register the strategy
        approvedStrategies[_strategy] = true;

        // Add to strategy list
        strategyList.push(_strategy);
        emit StrategyApproved(_strategy);
        emit StrategyRegistered(_strategy);
        emit StrategyApprovalGranted(_strategy);
    }

    function removeStrategy(address _strategy) external onlyOwner {
        require(approvedStrategies[_strategy], "Strategy not approved");
        require(isStrategyRegistered(_strategy), "Strategy not registered");
        require(IStrategy(_strategy).getBalance(address(this)) == 0, "Strategy balance must be zero");
        
        approvedStrategies[_strategy] = false;
        // Remove from strategy list
        for (uint i = 0; i < strategyList.length; i++) {
            if (strategyList[i] == _strategy) {
                strategyList[i] = strategyList[strategyList.length - 1];
                strategyList.pop();
                break;
            }
        }

        approvedStrategies[_strategy] = false;
        emit StrategyRemoved(_strategy);
        emit StrategyDeregistered(_strategy);
        emit StrategyApprovalRevoked(_strategy);
    }

    function updateStrategyMetrics(address _strategy) external nonReentrant {
        require(approvedStrategies[_strategy], "Strategy not approved");
        uint256 apy = IStrategy(_strategy).apy();
        uint256 tvl = IStrategy(_strategy).getBalance(address(this));
        strategyMetrics[_strategy] = StrategyMetrics({
            apy: apy,
            tvl: tvl,
            lastUpdated: block.timestamp
        });
        emit StrategyMetricsUpdated(_strategy, apy, tvl);
    }

    function getStrategyCount() external view returns (uint256) {
        return strategyList.length;
    }

    function isStrategyRegistered(address _strategy) public view returns (bool) {
        for (uint i = 0; i < strategyList.length; i++) {
            if (strategyList[i] == _strategy) {
                return true;
            }
        }
        return false;
    }


    function getStrategyInfo(address index) external view returns (address, uint256, uint256) {
        require(index < strategyList.length, "Index out of bounds");
        address strategy = strategyList[index];
        StrategyMetrics memory metrics = strategyMetrics[strategy];
        return (strategy, metrics.apy, metrics.tvl);
    }
}