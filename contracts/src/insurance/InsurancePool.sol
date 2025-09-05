// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract InsurancePool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token, address _initialOwner) Ownable(_initialOwner) {
        token = _token;
    }

    function depositFee(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function claimFee(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient pool balance");
        require(token.transfer(to, amount), "Transfer failed");
    }
}