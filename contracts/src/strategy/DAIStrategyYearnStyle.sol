// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DAIStrategyYearnStyle {
    using SafeERC20 for IERC20;

    IERC20 public immutable want;
    address public immutable vault;

    uint256 public totalDeposited;
    uint256 public yieldFactor = 100e16; // 1.00 = 0% yield baseline

    constructor(address _vault, address _dai) {
        vault = _vault;
        want = IERC20(_dai);
    }

    function deposit(uint256 amount) external {
        require(msg.sender == vault, "only vault");
        want.safeTransferFrom(vault, address(this), amount);
        totalDeposited += amount;
    }

    // Yearn-like harvest to increase yield
    function harvest(uint256 profitBps) external {
        // e.g. profitBps = 500 = 5% yield
        yieldFactor = yieldFactor + ((yieldFactor * profitBps) / 10000);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == vault, "only vault");

        uint256 bal = want.balanceOf(address(this));
        uint256 actual = bal >= amount ? amount : bal;
        want.safeTransfer(vault, actual);

        totalDeposited -= actual;
        return actual;
    }

    function estimatedTotalAssets() external view returns (uint256) {
        return (totalDeposited * yieldFactor) / 100e16;
    }

    function isActive() external pure returns (bool) {
        return true;
    }
}
