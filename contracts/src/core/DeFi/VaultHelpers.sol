// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

library VaultHelpers {
    // Compute EIP-712 domain separator from pre-hashed name/version
    function domainSeparator(bytes32 domainTypeHash, bytes32 nameHash, bytes32 versionHash, uint256 chainId, address verifyingContract) external pure returns (bytes32) {
        return keccak256(abi.encode(domainTypeHash, nameHash, versionHash, chainId, verifyingContract));
    }

    // Compute permit digest (EIP-2612) using provided domain separator and permit type hash
    function permitDigest(bytes32 domainSeparator_, bytes32 permitTypeHash, address owner, address spender, uint256 value, uint256 nonce, uint256 deadline) external pure returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(permitTypeHash, owner, spender, value, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator_, structHash));
    }

    // Calculate locked profit given stored lockedProfit and degradation parameters
    function calculateLockedProfit(
        uint256 lockedProfit_,
        uint256 lockedProfitDegradation,
        uint256 lastReport,
        uint256 currentTime,
        uint256 DEGRADATION_COEFFICIENT
    ) external pure returns (uint256) {
        if (lockedProfit_ == 0 || lockedProfitDegradation == 0) return 0;
        uint256 lockedFundsRatio = (currentTime - lastReport) * lockedProfitDegradation;
        if (lockedFundsRatio < DEGRADATION_COEFFICIENT) {
            uint256 lp = lockedProfit_;
            return lp - ((lockedFundsRatio * lp) / DEGRADATION_COEFFICIENT);
        } else {
            return 0;
        }
    }

    // Free funds = totalAssets - lockedProfit
    function freeFunds(uint256 totalIdle, uint256 totalDebt, uint256 lockedProfit_) external pure returns (uint256) {
        uint256 total = totalIdle + totalDebt;
        if (total <= lockedProfit_) return 0;
        return total - lockedProfit_;
    }

    // Compute shares to issue for a given amount (preserves 1:1 initial behavior)
    function computeSharesForAmount(uint256 totalSupply, uint256 freeFunds_, uint256 amount) external pure returns (uint256) {
        if (totalSupply > 0 && freeFunds_ > 0) {
            return (amount * totalSupply) / freeFunds_;
        } else {
            return amount;
        }
    }

    // Compute value per shares
    function computeShareValue(uint256 totalSupply, uint256 freeFunds_, uint256 shares) external pure returns (uint256) {
        if (totalSupply == 0) return shares;
        if (freeFunds_ == 0) return 0;
        return (shares * freeFunds_) / totalSupply;
    }

    // Helper: compute shares for an amount (view variant)
    function computeSharesForAmountView(uint256 amount, uint256 freeFunds_, uint256 totalSupply) external pure returns (uint256) {
        if (totalSupply > 0 && freeFunds_ > 0) {
            return (amount * totalSupply) / freeFunds_;
        } else {
            return amount == 0 ? 0 : 0; // keep behavior: when totalSupply==0, view callers expect 0
        }
    }
}
