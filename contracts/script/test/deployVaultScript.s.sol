// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/core/DeFi/UnifiedVault.sol";
import "../../src/TokenTest/MockToken.sol";
import "../../src/TokenTest/MockStrategy.sol";

contract DeployVaultScript is Script {
    function run() external {
        // 1. Start broadcasting transactions
        vm.startBroadcast();

        // 2. Deploy mock token
        MockToken token = new MockToken(1000 ether);
        console.log("MockToken deployed at:", address(token));

        // 3. Deploy Vault
        Vault vault = new Vault();
        vault.initialize(
            address(token),    // underlying token
            msg.sender,        // governance
            msg.sender,        // guardian
            "Mock Vault",      // name
            "MVLT",            // symbol
            msg.sender,        // management
            msg.sender         // treasury
        );
        console.log("Vault deployed at:", address(vault));

        // 4. Deploy Mock Strategy
        MockStrategy strategy = new MockStrategy(address(vault), address(token));
        console.log("MockStrategy deployed at:", address(strategy));

        // 5. Add strategy to vault
        vault.addStrategy(address(strategy), 5000, 0, 1000 ether, 500);

        vm.stopBroadcast();
    }
}
