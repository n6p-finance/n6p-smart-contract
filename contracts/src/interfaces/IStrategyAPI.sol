// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * This interface is here for the Lunar bot to interact with different strategies.
 * Each strategy should implement this interface to ensure compatibility.
 */
interface IStrategyAPI {
    // Basic strategy information
    // - name: The name of the strategy
    function name() external view returns (string memory);
    // - vault: The address of the vault this strategy is linked to
    function vault() external view returns (address);
    // - wantToken: The token that this strategy is managing
    function wantToken() external view returns (address);
    // - APIVersion: The version of the strategy API implemented
    function APIVersion() external view returns (string memory);
    // - LunarBot: The address of the Lunar bot authorized to call tend and harvest
    function LunarBot() external view returns (address);
    // - isActive: Whether the strategy is currently active
    function isActive() external view returns (bool);
    // - delegatedAssets: The amount of assets currently delegated to this strategy
    function delegatedAssets() external view returns (uint256);
    // - estimatedTotalAssets: The total assets managed by the strategy, including those not in the vault
    function estimatedTotalAssets() external view returns (uint256);
    // - tendTrigger: Function to check if tending is needed based on call cost
    function tendTrigger(uint256 callCostInWei) external view returns (bool);
    // - tend: Function to perform maintenance tasks to optimize yield
    function tend() external;
    // - harvestTrigger: Function to check if harvesting is needed based on call cost
    function harvestTrigger(uint256 callCostInWei) external view returns (bool);
    // - harvest: Function to realize profits/losses and report to the vault
    function harvest() external;
    // - setLunarBot: Function to set the Lunar bot address (only callable by owner)
    function setLunarBot(address _lunarBot) external;
    // - setIsActive: Function to activate/deactivate the strategy (only callable by owner)
    function setIsActive(bool _isActive) external;

    // event emitted when the strategy is tended
    event Tended(uint256 totalAssets);
    // event emitted when the strategy is harvested
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}
