// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @notice Minimal placeholder PriceOracle implementation
/// This file existed but was empty; provide a minimal interface-compatible stub
contract PriceOracle {
	/// @notice Returns price for a token (stub returns 0)
	function getPrice(address /*token*/) external pure returns (uint256) {
		return 0;
	}
}
