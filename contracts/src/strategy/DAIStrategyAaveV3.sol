// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract DAIStrategyAaveV3 {
    using SafeERC20 for IERC20;

    IERC20 public immutable want;               // DAI
    IAavePool public immutable pool;            // Aave pool
    address public immutable vault;             // VaultAggregator
    address public immutable aToken;            // aDAI token

    constructor(address _vault, address _dai, address _pool, address _aToken) {
        vault = _vault;
        want = IERC20(_dai);
        pool = IAavePool(_pool);
        aToken = _aToken;
    }

    // Vault sends DAI here and this strategy deposits to Aave
    function deposit(uint256 amt) external {
        require(msg.sender == vault, "only vault");

        want.approve(address(pool), 0);
        want.approve(address(pool), amt);

        pool.supply(address(want), amt, address(this), 0);
    }

    // Withdraw from Aave → return to vault
    function withdraw(uint256 amt) external returns (uint256) {
        require(msg.sender == vault, "only vault");

        uint256 received = pool.withdraw(address(want), amt, vault);
        return received;
    }

    // Total assets = aDAI balance
    function estimatedTotalAssets() external view returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    function isActive() external pure returns (bool) {
        return true;
    }
}
