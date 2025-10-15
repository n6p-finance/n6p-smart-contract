// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {VaultV2} from "../src/core/DeFi/VaultV2.sol";
import {Vault} from "../src/core/DeFi/VaultDeFi.sol";

contract UpgradeVaultScript is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Existing proxy address from previous deployment
        address proxyAddress = 0x11C577A3539A5B47C09Ab691b1e222D677b6F0FB;

        // 1. Deploy new implementation
        VaultV2 newImpl = new VaultV2();
        console.log("New implementation deployed at:", address(newImpl));

        // 2. Upgrade via proxy (onlyGov)
        Vault(proxyAddress).upgradeTo(address(newImpl));
        console.log("Vault upgraded to V2 successfully!");

        vm.stopBroadcast();
    }
}
