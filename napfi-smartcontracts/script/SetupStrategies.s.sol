// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/**
 * SetupStrategies.s.sol
 * Script to register strategy implementations in the registry after deployment.
 */
contract SetupStrategies is Script {
    function run() external {
        vm.startBroadcast();
        // TODO: call registry.registerStrategy for deployed implementations
        vm.stopBroadcast();
    }
}
