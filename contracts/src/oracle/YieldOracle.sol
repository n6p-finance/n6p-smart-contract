// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @notice Minimal placeholder YieldOracle implementation
contract YieldOracle {
	/// @notice Returns APY for a vault (stub returns 0)
	function getAPY(address /*vault*/) external pure returns (uint256) {
		return 0;
	}
}
