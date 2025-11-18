// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * SafeERC20.sol
 * Minimal safe ERC20 wrappers. For production, import OpenZeppelin's SafeERC20.
 */
interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeERC20 {
    function safeTransfer(IERC20Minimal token, address to, uint256 amount) internal {
        bool ok = token.transfer(to, amount);
        require(ok, "SafeERC20: transfer failed");
    }

    function safeTransferFrom(IERC20Minimal token, address from, address to, uint256 amount) internal {
        bool ok = token.transferFrom(from, to, amount);
        require(ok, "SafeERC20: transferFrom failed");
    }
}
