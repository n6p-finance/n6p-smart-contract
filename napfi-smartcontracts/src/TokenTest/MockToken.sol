// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * MockToken.sol
 * Minimal ERC20 token for local testing. NOT for production.
 */
contract MockToken {
    string public name = "MockToken";
    string public symbol = "MCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(uint256 _supply) {
        totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address, uint256) external returns (bool) { return true; }
}
