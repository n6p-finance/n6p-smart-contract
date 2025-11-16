// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title VaultWithdrawalLib
 * @notice Heavy withdrawal/redemption logic extracted to reduce Vault runtime size.
 *         Provides functions for computing withdrawal amounts and strategy debt adjustments.
 */

library VaultWithdrawalLib {
    /// @notice Process a strategy withdrawal during redemption/withdrawal flow
    /// @dev Returns the amount to deduct from value and updated vaultBalance
    function processStrategyWithdrawal(
        uint256 currentVaultBalance,
        uint256 requestedValue,
        uint256 strategyTotalDebt,
        uint256 lossFromWithdraw,
        uint256 withdrawnAmount
    ) external pure returns (uint256 newVaultBalance, uint256 valueDeducted, uint256 newStrategyDebt) {
        // Add withdrawn amount to vault balance
        newVaultBalance = currentVaultBalance + withdrawnAmount;
        
        // If loss occurred, reduce value and update strategy debt
        if (lossFromWithdraw > 0) {
            valueDeducted = lossFromWithdraw;
        }
        
        // Update strategy total debt (reduce by withdrawn amount)
        newStrategyDebt = strategyTotalDebt - withdrawnAmount;
    }

    /// @notice Compute final withdrawal share/asset amounts after loss
    function computeFinalWithdrawal(
        uint256 requestedValue,
        uint256 currentVaultBalance,
        uint256 totalLoss,
        uint256 maxLossAllowedBps,
        uint256 MAX_BPS,
        uint256 totalSupply
    ) external pure returns (uint256 finalValue, uint256 finalShares, bool isValid) {
        finalValue = requestedValue;
        finalShares = 0;

        // If more value withdrawn than available, cap at vault balance
        if (finalValue > currentVaultBalance) {
            finalValue = currentVaultBalance;
        }

        // Check loss threshold
        if (totalLoss > 0) {
            uint256 allowedLoss = (maxLossAllowedBps * finalValue) / MAX_BPS;
            if (totalLoss > allowedLoss) {
                return (finalValue, finalShares, false);
            }
        }

        // Compute shares for the final value
        if (totalSupply > 0 && finalValue > 0) {
            finalShares = (finalValue * totalSupply) / (totalSupply > 0 ? (totalSupply) : 1);
        }

        isValid = true;
    }

    /// @notice Min helper function
    function min(uint256 a, uint256 b) external pure returns (uint256) {
        return a < b ? a : b;
    }
}
