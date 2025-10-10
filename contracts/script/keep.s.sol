// SPDX-License-Identifier: MIT OR AGPL-3.0
pragma solidity ^0.8.20;

// Solidity analogue of scripts/keep.py. It executes harvest/tend for a set of strategies
// based on their trigger functions and a provided gas price and gas estimates.

interface IStrategyKeep {
    function keeper() external view returns (address);
    function vault() external view returns (address);
    function harvest() external;
    function tend() external;
    function harvestTrigger(uint256 callCost) external view returns (bool);
    function tendTrigger(uint256 callCost) external view returns (bool);
}

interface IVaultKeepView {
    function token() external view returns (address);
    function creditAvailable(address strategy) external view returns (uint256);
    function debtOutstanding(address strategy) external view returns (uint256);
    function decimals() external view returns (uint256);
}

contract KeepScript {
    // GAS_BUFFER as in keep.py (1.2x) but using bps to avoid floats: default 12000 (1.2x)
    uint256 public constant DEFAULT_GAS_BUFFER_BPS = 12000; // 120%

    // Validates that msg.sender is the configured keeper for all strategies and same vault
    function validateStrategies(address[] calldata strategies, address expectedKeeper)
        external
        view
        returns (bool ok, address vault, address mismatch)
    {
        vault = IStrategyKeep(strategies[0]).vault();
        for (uint256 i = 0; i < strategies.length; i++) {
            if (IStrategyKeep(strategies[i]).keeper() != expectedKeeper) {
                mismatch = strategies[i];
                return (false, vault, mismatch);
            }
            if (IStrategyKeep(strategies[i]).vault() != vault) {
                mismatch = strategies[i];
                return (false, vault, mismatch);
            }
        }
        return (true, vault, address(0));
    }

    // One-shot execution over provided strategies.
    // gasPrice is in wei. gasBufferBps scales estimates (e.g., 12000 for 1.2x). If 0, defaults to DEFAULT_GAS_BUFFER_BPS.
    // If per-strategy estimates arrays are empty, use the shared harvest/tend estimates for all.
    function run(
        address[] calldata strategies,
        uint256 gasPrice,
        uint256 harvestGasEstimate,
        uint256 tendGasEstimate,
        uint256 gasBufferBps
    ) external returns (uint256 callsMade)
    {
        uint256 buffer = gasBufferBps == 0 ? DEFAULT_GAS_BUFFER_BPS : gasBufferBps;
        for (uint256 i = 0; i < strategies.length; i++) {
            address strat = strategies[i];
            uint256 hCost = (harvestGasEstimate * gasPrice * buffer) / 10_000;
            uint256 tCost = (tendGasEstimate * gasPrice * buffer) / 10_000;

            bool didCall = false;
            // Prefer harvest when both are true, like keep.py
            if (harvestGasEstimate > 0 && IStrategyKeep(strat).harvestTrigger(hCost)) {
                // best-effort call with try/catch so one failure doesn't stop others
                try IStrategyKeep(strat).harvest() { didCall = true; } catch {}
            } else if (tendGasEstimate > 0 && IStrategyKeep(strat).tendTrigger(tCost)) {
                try IStrategyKeep(strat).tend() { didCall = true; } catch {}
            }
            if (didCall) { callsMade += 1; }
        }
    }

    // Convenience view to fetch basic per-strategy stats similarly displayed in keep.py
    function getStats(address strategy)
        external
        view
        returns (
            address vault,
            uint256 creditAvailable,
            uint256 debtOutstanding,
            uint256 vaultDecimals
        )
    {
        vault = IStrategyKeep(strategy).vault();
        creditAvailable = IVaultKeepView(vault).creditAvailable(strategy);
        debtOutstanding = IVaultKeepView(vault).debtOutstanding(strategy);
        vaultDecimals = IVaultKeepView(vault).decimals();
    }
}


