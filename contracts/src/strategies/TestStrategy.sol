// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategy.sol";
import "./MockERC20.sol"; // Assumes MockERC20 is in a separate file

/// @title MockStrategy
/// @notice A mock strategy contract for testing vault interactions.
/// @dev Implements IStrategy with deposit, withdraw, and yield generation functionality.
contract MockStrategy is IStrategy {
    MockERC20 public token;

    /// @notice Initializes the strategy with a token address.
    /// @param _token The ERC20 token to be used by the strategy.
    constructor(MockERC20 _token) {
        token = _token;
    }

    /// @notice Deposits tokens into the strategy.
    /// @dev Transfers tokens from the caller to the strategy.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        require(token.transferFrom(msg.sender, address(this), amount), "MockStrategy: transferFrom failed");
    }

    /// @notice Withdraws tokens from the strategy.
    /// @dev Transfers tokens from the strategy to the caller.
    /// @param amount The amount of tokens to withdraw (in wei).
    function withdraw(uint256 amount) external override {
        require(token.transfer(msg.sender, amount), "MockStrategy: transfer failed");
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Ignores the account parameter for simplicity.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Generates yield by minting additional tokens.
    /// @dev Mints 10% of the current balance as yield.
    function generateYield() external override {
        uint256 base = token.balanceOf(address(this));
        uint256 yieldAmount = base / 10;
        if (yieldAmount > 0) {
            token.mint(address(this), yieldAmount);
        }
    }

    /// @notice Returns a dummy APY value.
    /// @dev Returns a fixed value of 1000 for testing.
    /// @return A dummy APY value (1000).
    function apy() external view override returns (uint256) {
        return 1000;
    }
}

/// @title MaliciousStrategy
/// @notice A malicious strategy that steals deposited tokens by transferring them to an attacker.
/// @dev Used to test vault behavior with an untrusted strategy.
contract MaliciousStrategy is IStrategy {
    MockERC20 public token;
    address public attacker;

    /// @notice Initializes the strategy with a token and attacker address.
    /// @param _token The ERC20 token to be used by the strategy.
    /// @param _attacker The address to receive stolen tokens.
    constructor(MockERC20 _token, address _attacker) {
        token = _token;
        attacker = _attacker;
    }

    /// @notice Deposits tokens and immediately transfers them to the attacker.
    /// @dev Steals all deposited tokens, leaving the strategy empty.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        require(token.transferFrom(msg.sender, address(this), amount), "MaliciousStrategy: transferFrom failed");
        require(token.transfer(attacker, amount), "MaliciousStrategy: transfer failed");
    }

    /// @notice Disables withdrawals by reverting.
    /// @dev Always reverts to simulate a malicious strategy.
    function withdraw(uint256 /*amount*/) external pure override {
        revert("MaliciousStrategy: withdraw disabled");
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Typically returns 0 due to funds being stolen.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice No-op function for yield generation.
    /// @dev Does nothing, as the strategy is malicious.
    function generateYield() external override {}

    /// @notice Returns a zero APY.
    /// @dev Returns 0 to reflect the malicious nature.
    /// @return A zero APY value.
    function apy() external view override returns (uint256) {
        return 0;
    }
}

/// @title BrokenStrategy
/// @notice A strategy that allows deposits but reverts on withdrawals.
/// @dev Used to test vault behavior when withdrawals are blocked.
contract BrokenStrategy is IStrategy {
    MockERC20 public token;

    /// @notice Initializes the strategy with a token address.
    /// @param _token The ERC20 token to be used by the strategy.
    constructor(MockERC20 _token) {
        token = _token;
    }

    /// @notice Deposits tokens into the strategy.
    /// @dev Transfers tokens from the caller to the strategy.
    /// @param amount The amount of tokens to deposit (in wei).
    function deposit(uint256 amount) external override {
        require(token.transferFrom(msg.sender, address(this), amount), "BrokenStrategy: transferFrom failed");
    }

    /// @notice Reverts on withdrawal attempts.
    /// @dev Always reverts to simulate a broken strategy.
    function withdraw(uint256 /*amount*/) external pure override {
        revert("BrokenStrategy: cannot withdraw");
    }

    /// @notice Returns the strategy's token balance.
    /// @dev Returns the current balance, typically non-zero due to trapped funds.
    /// @return The strategy's current token balance (in wei).
    function getBalance(address /*account*/) external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice No-op function for yield generation.
    /// @dev Does nothing, as the strategy is broken.
    function generateYield() external override {}

    /// @notice Returns a zero APY.
    /// @dev Returns 0 to reflect the broken nature.
    /// @return A zero APY value.
    function apy() external view override returns (uint256) {
        return 0;
    }
}