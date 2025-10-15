// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VaultDeFi.sol";

contract VaultV2 is Vault {
    function newFeature() external pure returns (string memory) {
        return "Vault v2 upgrade successful";
    }

    function version() external pure returns (string memory) {
        return "v2";
    }
}
