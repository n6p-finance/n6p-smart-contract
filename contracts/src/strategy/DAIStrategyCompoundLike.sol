// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IcDAI {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 amount) external returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
}

contract DAIStrategyCompoundLike {
    using SafeERC20 for IERC20;

    IERC20 public immutable want;
    IcDAI public immutable cDai;
    address public immutable vault;

    constructor(address _vault, address _dai, address _cDai) {
        vault = _vault;
        want = IERC20(_dai);
        cDai = IcDAI(_cDai);
    }

    function deposit(uint256 amount) external {
        require(msg.sender == vault, "only vault");

        want.approve(address(cDai), 0);
        want.approve(address(cDai), amount);
        cDai.mint(amount);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == vault, "only vault");

        cDai.redeemUnderlying(amount);
        want.safeTransfer(vault, amount);
        return amount;
    }

    // cDAI * exchangeRate = underlying value
    function estimatedTotalAssets() external view returns (uint256) {
        uint256 bal = cDai.balanceOf(address(this));
        uint256 ex = cDai.exchangeRateStored();  
        return (bal * ex) / 1e18;
    }

    function isActive() external pure returns (bool) {
        return true;
    }
}
