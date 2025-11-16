// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/DeFi/VaultDeFi.sol";

contract MockStrategy is IStrategy {
    address public override want;
    address public override vault;
    bool public active = true;
    uint256 public override totalDebt;

    constructor(address _vault, address _want) {
        vault = _vault;
        want = _want;
    }

    function isActive() external view override returns (bool) {
        return active;
    }

    function delegatedAssets() external pure override returns (uint256) { return 0; }
    function estimatedTotalAssets() external pure override returns (uint256) { return 0; }

    function withdraw(uint256 _amount) external override returns (uint256 loss) {
        IERC20(want).transfer(vault, _amount);
        return 0;
    }

    function migrate(address _newStrategy) external override {}
    function emergencyExit() external pure override returns (bool) { return false; }
    function totalIdle() external pure override returns (uint256) { return 0; }
}
