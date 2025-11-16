// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title VaultReportingLib
 * @notice Heavy fee/loss reporting logic extracted to reduce Vault runtime size.
 *         This library computes fee breakdowns and loss accounting for strategy reports.
 */

library VaultReportingLib {
    /// @notice Compute fee assessment from strategy report gain
    /// @return totalFee total fees to assess
    /// @return management_fee management fee portion
    /// @return strategist_fee strategist fee portion
    /// @return performance_fee_ performance fee portion
    function computeReportFees(
        uint256 strategyTotalDebt,
        uint256 delegatedAssets,
        uint256 duration,
        uint256 managementFeeBps,
        uint256 strategyPerformanceFeeBps,
        uint256 performanceFeeBps,
        uint256 MAX_BPS,
        uint256 SECS_PER_YEAR,
        uint256 gain
    ) external pure returns (uint256 totalFee, uint256 management_fee, uint256 strategist_fee, uint256 performance_fee_) {
        if (gain == 0) return (0, 0, 0, 0);

        // management fee prorated by duration
        if (strategyTotalDebt > delegatedAssets) {
            management_fee = ((strategyTotalDebt - delegatedAssets) * duration * managementFeeBps) / MAX_BPS / SECS_PER_YEAR;
        } else {
            management_fee = 0;
        }

        strategist_fee = (gain * strategyPerformanceFeeBps) / MAX_BPS;
        performance_fee_ = (gain * performanceFeeBps) / MAX_BPS;

        totalFee = management_fee + strategist_fee + performance_fee_;
        if (totalFee > gain) totalFee = gain;

        return (totalFee, management_fee, strategist_fee, performance_fee_);
    }

    /// @notice Calculate loss impact on debt ratio
    /// @dev Reduces debt ratio when loss occurs
    function computeLossDebtRatioDelta(
        uint256 loss,
        uint256 strategyTotalDebt,
        uint256 vaultTotalDebt,
        uint256 strategyDebtRatio,
        uint256 debtRatio,
        uint256 MAX_BPS
    ) external pure returns (uint256 newStrategyDebtRatio, uint256 newDebtRatio) {
        require(strategyTotalDebt >= loss, "V:loss>debt");
        
        newStrategyDebtRatio = strategyDebtRatio;
        newDebtRatio = debtRatio;

        if (debtRatio != 0) {
            uint256 ratio_change = 0;
            if (vaultTotalDebt > 0) {
                ratio_change = (loss * debtRatio) / vaultTotalDebt;
                if (ratio_change > strategyDebtRatio) {
                    ratio_change = strategyDebtRatio;
                }
            }
            newStrategyDebtRatio = strategyDebtRatio - ratio_change;
            newDebtRatio = debtRatio - ratio_change;
        }
    }
}
