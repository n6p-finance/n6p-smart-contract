// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Mock cDAI for testing Compound V2 strategies on testnets like Sepolia.
contract MockcDAI is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public immutable dai;

    uint256 public exchangeRate; // scaled by 1e18

    constructor(address _dai)
        ERC20("Mock Compound DAI", "cDAI")
    {
        dai = IERC20(_dai);
        exchangeRate = 1e18; // initial 1:1
    }

    /// @notice Mints cDAI by depositing DAI
    function mint(uint256 daiAmount) external returns (uint256) {
        require(daiAmount > 0, "zero");

        dai.safeTransferFrom(msg.sender, address(this), daiAmount);

        uint256 cTokens = (daiAmount * 1e18) / exchangeRate;
        _mint(msg.sender, cTokens);

        return 0; // Compound V2 standard (always returns 0 on success)
    }

    /// @notice Redeems cDAI into DAI
    function redeem(uint256 cTokenAmount) external returns (uint256) {
        require(cTokenAmount > 0, "zero");

        uint256 daiAmount = (cTokenAmount * exchangeRate) / 1e18;
        _burn(msg.sender, cTokenAmount);

        dai.safeTransfer(msg.sender, daiAmount);

        return 0;
    }

    /// @notice Simulate yield by increasing exchange rate
    function simulateInterest(uint256 bpsIncrease) external {
        exchangeRate = exchangeRate + (exchangeRate * bpsIncrease / 10000);
    }

    function exchangeRateStored() external view returns (uint256) {
        return exchangeRate;
    }
}
