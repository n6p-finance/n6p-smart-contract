# =====================================================
# Napy Token Vault — Enhanced Analytics & Visualization
# Data Analyst Edition (Seaborn dark theme + 20yr compounding)
# =====================================================
from matplotlib.backends.backend_pdf import PdfPages
from datetime import datetime
import io
import math
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from dataclasses import dataclass
from typing import Dict, List

# ---------------------------
# Visual style
# ---------------------------
sns.set_theme(context="notebook", style="darkgrid", palette="muted")
plt.rcParams["figure.figsize"] = (12, 6)
plt.rcParams["figure.dpi"] = 100

# ---------------------------
# Vault constants (same semantics)
# ---------------------------
class VaultConstants:
    MAX_BPS = 10_000
    MAXIMUM_STRATEGIES = 20
    DEGRADATION_COEFFICIENT = 10**18
    SECS_PER_YEAR = 31_556_952

    PERFORMANCE_FEE_BPS = 1_000  # 10%
    MANAGEMENT_FEE_BPS = 200     # 2%

# ---------------------------
# Core data classes (lightweight)
# ---------------------------
@dataclass
class StrategySpec:
    name: str
    perf_fee_bps: int
    debt_ratio_bps: int
    mean_annual_return: float
    std_annual_return: float
    min_debt_per_harvest: int = 0
    max_debt_per_harvest: int = 10_000_000

@dataclass
class VaultSimResult:
    timeline: pd.DataFrame  # rows: period steps with columns for metrics
    summary: Dict[str, float] # aggregated metrics


# ---------------------------
# Fee logic (keeps same behavior)
# ---------------------------
class FeeCalculator:
    @staticmethod
    def calculate_management_fee(strategy_debt, delegated_assets, duration_seconds, management_fee_bps):
        effective_debt = max(strategy_debt - delegated_assets, 0)
        return (effective_debt * duration_seconds * management_fee_bps) // (VaultConstants.MAX_BPS * VaultConstants.SECS_PER_YEAR)

    @staticmethod
    def calculate_performance_fee(gain, performance_fee_bps):
        return (gain * performance_fee_bps) // VaultConstants.MAX_BPS

    @staticmethod
    def assess_fees(gain, strategy_debt, delegated_assets, duration_seconds,
                    strategy_performance_fee_bps, vault_performance_fee_bps, vault_management_fee_bps):
        """
        Returns fee breakdown (ints). Gains <= 0 -> zero fees.
        This mirrors the Vault logic: management fee based on debt/time + strategy perf + vault perf.
        """
        if gain <= 0:
            return {'management_fee': 0, 'strategist_fee': 0, 'performance_fee': 0, 'total_fee': 0}

        management_fee = FeeCalculator.calculate_management_fee(strategy_debt, delegated_assets, duration_seconds, vault_management_fee_bps)
        strategist_fee = FeeCalculator.calculate_performance_fee(gain, strategy_performance_fee_bps)
        performance_fee = FeeCalculator.calculate_performance_fee(gain, vault_performance_fee_bps)
        total_fee = min(management_fee + strategist_fee + performance_fee, gain)
        return {
            'management_fee': int(management_fee),
            'strategist_fee': int(strategist_fee),
            'performance_fee': int(performance_fee),
            'total_fee': int(total_fee)
        }

# ---------------------------
# Simulation functions
# ---------------------------
def simulate_strategies_compounding(
    strategies: List[StrategySpec],
    initial_vault_assets: float = 10_000_000,
    initial_idle_ratio: float = 0.30,
    years: int = 20,
    periods_per_year: int = 12,
    vault_performance_fee_bps: int = VaultConstants.PERFORMANCE_FEE_BPS,
    vault_management_fee_bps: int = VaultConstants.MANAGEMENT_FEE_BPS,
    seed: int = 42,
):
    """
    Simulate multiple strategies and the vault over time.
    Returns per-period DataFrame with columns:
    - period_idx, year_step, total_assets_gross, total_assets_net,
      total_fees_paid, per-strategy balances/gains/fees, idle, deployed
    """
    np.random.seed(seed)

    periods = years * periods_per_year
    dt_year_fraction = 1.0 / periods_per_year
    dt_seconds = int(VaultConstants.SECS_PER_YEAR / periods_per_year)

    # initial allocation by debt ratios
    total_debt_ratio = sum(s.debt_ratio_bps for s in strategies)
    if total_debt_ratio == 0:
        raise ValueError("At least one strategy must have non-zero debt ratio")

    # initial values
    total_assets = initial_vault_assets
    locked_profit = 0
    idle = initial_vault_assets * initial_idle_ratio
    deployed = initial_vault_assets - idle
    shares_total = initial_vault_assets  # treat shares ~ token units for simpler sim

    # Prepare DataFrame rows
    rows = []
    # track per-strategy principal
    strat_balances = {s.name: deployed * (s.debt_ratio_bps / total_debt_ratio) for s in strategies}

    for step in range(periods + 1):
        year = step / periods_per_year
        # record state at beginning of period
        row = {
            'period': step,
            'year': year,
            'total_assets_gross': total_assets,
            'idle': idle,
            'deployed': deployed,
            'locked_profit': locked_profit,
        }
        # initialize per-strategy columns
        for s in strategies:
            row[f'{s.name}_balance'] = strat_balances[s.name]
            row[f'{s.name}_gain'] = 0.0
            row[f'{s.name}_fee'] = 0.0
            row[f'{s.name}_net_gain'] = 0.0

        row['total_fees'] = 0.0
        rows.append(row)

        if step == periods:
            break  # final snapshot only; don't simulate beyond last recording

        # Simulate one period of returns for each strategy (annualized mean/std -> period random draw)
        gross_period_gains = {}
        fee_periods = {}
        net_period_gains = {}

        for s in strategies:
            balance = strat_balances[s.name]
            # convert annual mean/std to period mean/std (geometric approx)
            # we simulate simple lognormal-ish returns via normal on return rate
            mu = s.mean_annual_return
            sigma = s.std_annual_return
            period_return = np.random.normal(loc=mu * dt_year_fraction, scale=sigma * math.sqrt(dt_year_fraction))
            gross_gain = balance * period_return
            # ensure realistic lower bound (can't lose more than balance in this period in our simple model)
            gross_gain = max(gross_gain, -0.99 * balance)

            # compute fees using provided FeeCalculator
            fee_map = FeeCalculator.assess_fees(
                gain=int(gross_gain) if gross_gain >= 0 else 0,  # Vault only charges fees on positive gains
                strategy_debt=int(balance),
                delegated_assets=0,
                duration_seconds=dt_seconds,
                strategy_performance_fee_bps=s.perf_fee_bps,
                vault_performance_fee_bps=vault_performance_fee_bps,
                vault_management_fee_bps=vault_management_fee_bps
            )
            total_fee = fee_map['total_fee']
            net_gain = gross_gain - total_fee  # apply fee if any

            gross_period_gains[s.name] = gross_gain
            fee_periods[s.name] = total_fee
            net_period_gains[s.name] = net_gain

        # aggregate gross/net across strategies
        total_gross_gain = sum(gross_period_gains.values())
        total_fees = sum(fee_periods.values())

        # update balances: add net gains into each strategy's balance (compounding)
        for s in strategies:
            strat_balances[s.name] += net_period_gains[s.name]
            # floor balances to zero minimum
            strat_balances[s.name] = max(strat_balances[s.name], 0.0)

        # Recompute deployed and idle (we assume idle remains a fraction unless gains push overall assets)
        deployed = sum(strat_balances.values())
        total_assets = deployed + idle
        # locked profit: for simplicity, set to fraction of last period gains (mirroring vault lock)
        locked_profit = max(0.0, 0.0 + total_gross_gain * 0.5)  # simple model: 50% initially locked and decays each period in view
        # total fees are removed from vault (i.e., reduce assets net)
        total_assets -= total_fees

        # update variables for next iteration
        total_assets = max(total_assets, 0.0)
        # distribute idle proportionally if vault grew large (keep idle ratio constant for simplicity)
        target_idle = initial_vault_assets * initial_idle_ratio
        # keep idle stable (you could also model flows)
        idle = target_idle
        deployed = total_assets - idle
        deployed = max(deployed, 0.0)

        # update total_assets for next step
        total_assets = idle + deployed

        # update row values for this step (the next iteration will record the new state)
        # but also update the rows[-1] (current row) with actual gain/fee numbers for the period we just simulated
        rows[-1].update({
            'total_gross_gain': total_gross_gain,
            'total_fees': total_fees,
            'total_net_gain': total_gross_gain - total_fees,
        })
        for s in strategies:
            rows[-1][f'{s.name}_gain'] = gross_period_gains[s.name]
            rows[-1][f'{s.name}_fee'] = fee_periods[s.name]
            rows[-1][f'{s.name}_net_gain'] = net_period_gains[s.name]

    # Build DataFrame
    df = pd.DataFrame(rows).fillna(0.0)

    # Derived metrics
    df['cumulative_gross_gain'] = df[[f'{s.name}_gain' for s in strategies]].sum(axis=1).cumsum()
    df['cumulative_fees'] = df[[f'{s.name}_fee' for s in strategies]].sum(axis=1).cumsum()
    df['cumulative_net_gain'] = df['cumulative_gross_gain'] - df['cumulative_fees']
    df['vault_value'] = df['total_assets_gross'] + df['cumulative_net_gain']  # approximation of value over time

    # Summary metrics
    total_fees_paid = df['cumulative_fees'].iloc[-1]
    final_value_gross = df['total_assets_gross'].iloc[-1] + df['cumulative_gross_gain'].iloc[-1]
    final_value_net = df['vault_value'].iloc[-1]
    period_returns = df['total_net_gain'].replace(0, np.nan).dropna()  # per period net gains
    avg_period_return = period_returns.mean() if not period_returns.empty else 0.0
    std_period_return = period_returns.std(ddof=0) if not period_returns.empty else 0.0
    # Sharpe-like ratio (per period) — for demonstration use period mean / std
    sharpe_period = (avg_period_return / std_period_return) if std_period_return > 0 else np.nan
    # Annualized Sharpe approx:
    sharpe_annual = sharpe_period * math.sqrt(periods_per_year) if not math.isnan(sharpe_period) else np.nan

    # Loss probability (percentage of periods with negative gross gain)
    loss_prob = (df[[f'{s.name}_gain' for s in strategies]].sum(axis=1) < 0).mean()

    # Fee efficiency: total fees / total gross gain (avoid div-by-zero)
    total_gross = df['cumulative_gross_gain'].iloc[-1]
    fee_efficiency = (total_fees_paid / total_gross) if total_gross != 0 else np.nan

    summary = {
        'final_value_gross': float(final_value_gross),
        'final_value_net': float(final_value_net),
        'total_fees_paid': float(total_fees_paid),
        'loss_probability': float(loss_prob),
        'fee_efficiency': float(fee_efficiency),
        'avg_period_return': float(avg_period_return),
        'std_period_return': float(std_period_return),
        'sharpe_annual_est': float(sharpe_annual) if not np.isnan(sharpe_annual) else None
    }

    return VaultSimResult(timeline=df, summary=summary)

# ---------------------------
# Analytics helpers
# ---------------------------
def compute_sharpe(series, periods_per_year):
    """Simple annualized Sharpe: mean(series)/std(series)*sqrt(periods_per_year)"""
    s = series.dropna()
    if s.std() == 0:
        return np.nan
    return (s.mean() / s.std()) * math.sqrt(periods_per_year)

def visualize_simulation_to_pdf(result: VaultSimResult, strategies: List[StrategySpec], years: int = 20, periods_per_year: int = 12):
    df = result.timeline.copy()
    periods = years * periods_per_year
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"vault_report_{timestamp}.pdf"

    with PdfPages(filename) as pdf:
        # 1) Cumulative gains
        plt.figure(figsize=(14, 6))
        sns.lineplot(x='year', y='cumulative_gross_gain', data=df, label='Cumulative Gross Gain', linestyle='--')
        sns.lineplot(x='year', y='cumulative_net_gain', data=df, label='Cumulative Net Gain', linewidth=2)
        plt.fill_between(df['year'], df['cumulative_net_gain'], color='tab:blue', alpha=0.08)
        plt.title('Cumulative Gross vs Net Gain (Vault)')
        plt.xlabel('Years')
        plt.ylabel('Amount (token units)')
        plt.legend()
        plt.grid(True)
        pdf.savefig(); plt.close()

        # 2) Strategy balances area
        plt.figure(figsize=(14, 6))
        strat_bal_cols = [f'{s.name}_balance' for s in strategies]
        df_area = df[strat_bal_cols].copy()
        df_area.index = df['year']
        df_area.plot.area(alpha=0.7)
        plt.title('Strategy Balances Over Time (Stacked Area)')
        plt.xlabel('Years')
        plt.ylabel('Strategy Balance (token units)')
        plt.legend(loc='upper left')
        pdf.savefig(); plt.close()

        # 3) Regression gross vs fees
        plt.figure(figsize=(10, 6))
        df_plot = df.copy()
        df_plot['period_gross'] = df_plot[[f'{s.name}_gain' for s in strategies]].sum(axis=1)
        df_plot['period_fees'] = df_plot[[f'{s.name}_fee' for s in strategies]].sum(axis=1)
        sns.regplot(x='period_gross', y='period_fees', data=df_plot, scatter_kws={'alpha':0.6}, line_kws={'color':'orange'})
        plt.title('Per-Period Gross Gain vs Fees (regression)')
        plt.xlabel('Gross Gain (period)')
        plt.ylabel('Fees (period)')
        pdf.savefig(); plt.close()

        # 4) Correlation heatmap
        corr_cols = ['total_gross_gain', 'total_fees', 'total_net_gain', 'deployed', 'idle']
        for c in corr_cols:
            if c not in df.columns:
                df[c] = 0.0
        cor = df[corr_cols].corr()
        plt.figure(figsize=(8,6))
        sns.heatmap(cor, annot=True, fmt='.2f', cmap='vlag', center=0)
        plt.title('Correlation Heatmap (key vault metrics)')
        pdf.savefig(); plt.close()

        # 5) Boxplot fees
        plt.figure(figsize=(10,6))
        fees_df = pd.DataFrame({s.name: df[f'{s.name}_fee'] for s in strategies})
        sns.boxplot(data=fees_df, palette='Set2')
        plt.title('Distribution of Fees per Strategy (per period)')
        plt.ylabel('Fees (token units)')
        pdf.savefig(); plt.close()

        # 6) Pie chart fees
        cum_fees = df[[f'{s.name}_fee' for s in strategies]].sum()
        plt.figure(figsize=(8,8))
        plt.pie(cum_fees, labels=cum_fees.index, autopct='%1.1f%%', startangle=140)
        plt.title('Fee Composition by Strategy (Cumulative)')
        pdf.savefig(); plt.close()

        # 7) Efficiency ratio over time
        df_plot['period_fee_to_gross'] = df_plot['period_fees'] / (df_plot['period_gross'].replace({0: np.nan}))
        plt.figure(figsize=(12,5))
        sns.lineplot(x='year', y='period_fee_to_gross', data=df_plot)
        plt.title('Fee-to-Gross Ratio Over Time')
        plt.xlabel('Years')
        plt.ylabel('Fee / Gross Gain (ratio)')
        plt.ylim(0, df_plot['period_fee_to_gross'].median(skipna=True)*4 if df_plot['period_fee_to_gross'].median(skipna=True) > 0 else 1)
        pdf.savefig(); plt.close()

        # 8) Text summary page
        s = result.summary
        text_buffer = io.StringIO()
        text_buffer.write("====== Vault Simulation Summary ======\n")
        text_buffer.write(f"Simulation horizon: {years} years ({years * periods_per_year} periods)\n")
        text_buffer.write(f"Final Gross Value: {s['final_value_gross']:,.2f}\n")
        text_buffer.write(f"Final Net Value: {s['final_value_net']:,.2f}\n")
        text_buffer.write(f"Total Fees Paid: {s['total_fees_paid']:,.2f}\n")
        text_buffer.write(f"Loss Probability: {s['loss_probability']*100:.2f}%\n")
        text_buffer.write(f"Fee Efficiency: {s['fee_efficiency']:.3f}\n")
        text_buffer.write(f"Avg period return: {s['avg_period_return']:.2f}, Std: {s['std_period_return']:.2f}\n")
        if s['sharpe_annual_est'] is not None:
            text_buffer.write(f"Estimated Annual Sharpe: {s['sharpe_annual_est']:.2f}\n\n")
        text_buffer.write("Per-strategy configuration:\n")
        for st in strategies:
            text_buffer.write(f" - {st.name}: {st.debt_ratio_bps/100:.1f}% debt, {st.perf_fee_bps/100:.1f}% perf fee, "
                              f"{st.mean_annual_return*100:.2f}% mean return, {st.std_annual_return*100:.2f}% vol\n")

        plt.figure(figsize=(8.5,11))
        plt.axis('off')
        plt.text(0.05, 0.95, text_buffer.getvalue(), fontsize=10, va='top', family='monospace')
        pdf.savefig(); plt.close()

    print(f"✅ PDF report generated: {filename}")

    # ---------------------------
# Visualization (multi-panel) — 2
# ---------------------------
def visualize_simulation_local(result: VaultSimResult, strategies: List[StrategySpec], years: int = 20, periods_per_year: int = 12):
    df = result.timeline.copy()
    periods = years * periods_per_year

    # --- ensure derived columns exist ---
    df['period_gross'] = df[[f'{s.name}_gain' for s in strategies]].sum(axis=1)
    df['period_fees'] = df[[f'{s.name}_fee' for s in strategies]].sum(axis=1)
    df['period_fee_to_gross'] = np.where(df['period_gross'] != 0,
                                         df['period_fees'] / df['period_gross'],
                                         0.0)

    # 1) Line chart: cumulative gross vs net gain (area)
    plt.figure(figsize=(14, 6))
    sns.lineplot(x='year', y='cumulative_gross_gain', data=df, label='Cumulative Gross Gain', linestyle='--')
    sns.lineplot(x='year', y='cumulative_net_gain', data=df, label='Cumulative Net Gain', linewidth=2)
    plt.fill_between(df['year'], df['cumulative_net_gain'], color='tab:blue', alpha=0.08)
    plt.title('Cumulative Gross vs Net Gain (Vault)')
    plt.xlabel('Years')
    plt.ylabel('Amount (token units)')
    plt.legend()
    plt.grid(True)
    plt.show()

    # 2) Stacked area: per-strategy balance evolution
    plt.figure(figsize=(14, 6))
    strat_bal_cols = [f'{s.name}_balance' for s in strategies]
    df_area = df[strat_bal_cols].copy()
    df_area.index = df['year']
    df_area.plot.area(alpha=0.7)
    plt.title('Strategy Balances Over Time (Stacked Area)')
    plt.xlabel('Years')
    plt.ylabel('Strategy Balance (token units)')
    plt.legend(loc='upper left')
    plt.show()

    # 3) Scatter + regression: per-period total gross gain vs total fees
    plt.figure(figsize=(10, 6))
    sns.regplot(x='period_gross', y='period_fees', data=df,
                scatter_kws={'alpha':0.6}, line_kws={'color':'orange'})
    plt.title('Per-Period Gross Gain vs Fees (Regression)')
    plt.xlabel('Gross Gain (per period)')
    plt.ylabel('Fees (per period)')
    plt.grid(True)
    plt.show()

    # 4) Correlation heatmap
    corr_cols = ['total_gross_gain', 'total_fees', 'total_net_gain', 'deployed', 'idle']
    for c in corr_cols:
        if c not in df.columns:
            df[c] = 0.0
    cor = df[corr_cols].corr()
    plt.figure(figsize=(8,6))
    sns.heatmap(cor, annot=True, fmt='.2f', cmap='vlag', center=0)
    plt.title('Correlation Heatmap (Vault Metrics)')
    plt.show()

    # 5) Boxplot: fee distribution per strategy
    plt.figure(figsize=(10,6))
    fees_df = pd.DataFrame({s.name: df[f'{s.name}_fee'] for s in strategies})
    sns.boxplot(data=fees_df, palette='Set2')
    plt.title('Distribution of Fees per Strategy (per period)')
    plt.ylabel('Fees (token units)')
    plt.show()

    # 6) Pie chart: cumulative fee composition
    cum_fees = df[[f'{s.name}_fee' for s in strategies]].sum()
    plt.figure(figsize=(8,8))
    plt.pie(cum_fees, labels=cum_fees.index, autopct='%1.1f%%', startangle=140)
    plt.title('Fee Composition by Strategy (Cumulative)')
    plt.show()

    # 7) Efficiency over time: Fee-to-Gross ratio
    plt.figure(figsize=(12,5))
    sns.lineplot(x='year', y='period_fee_to_gross', data=df)
    plt.title('Fee-to-Gross Ratio Over Time')
    plt.xlabel('Years')
    plt.ylabel('Fee / Gross Gain')
    upper_lim = df['period_fee_to_gross'].replace([np.inf, -np.inf], np.nan).median(skipna=True)
    if np.isnan(upper_lim) or upper_lim <= 0:
        upper_lim = 1
    plt.ylim(0, upper_lim * 4)
    plt.show()


# ---------------------------
# Textual summary generator
# ---------------------------
def generate_summary(result: VaultSimResult, strategies: List[StrategySpec], years=20, periods_per_year=12):
    s = result.summary
    print("\n====== Vault Simulation Summary ======")
    print(f"Simulation horizon: {years} years ({years * periods_per_year} periods)")
    print(f"Final Gross Value (approx): {s['final_value_gross']:,.2f}")
    print(f"Final Net Value (approx): {s['final_value_net']:,.2f}")
    print(f"Total Fees Paid: {s['total_fees_paid']:,.2f}")
    print(f"Loss Probability (periods with negative gross): {s['loss_probability']*100:.2f}%")
    print(f"Fee Efficiency (total fees / total gross gain): {s['fee_efficiency']:.3f}")
    print(f"Avg period return: {s['avg_period_return']:.2f}, Std period return: {s['std_period_return']:.2f}")
    if s['sharpe_annual_est'] is not None:
        print(f"Estimated annualized Sharpe (approx): {s['sharpe_annual_est']:.2f}")
    print("\nPer-strategy configuration:")
    for st in strategies:
        print(f" - {st.name}: target debt ratio {st.debt_ratio_bps/100:.1f}%, perf fee {st.perf_fee_bps/100:.1f}%, mean ann ret {st.mean_annual_return*100:.2f}%, vol {st.std_annual_return*100:.2f}%")

# ---------------------------
# Main: configure strategies and run
# ---------------------------
if __name__ == "__main__":
    # Define three strategies with plausible return profiles
    strategies = [
        StrategySpec(name="Compound", perf_fee_bps=1000, debt_ratio_bps=4000, mean_annual_return=0.06, std_annual_return=0.10),
        StrategySpec(name="Aave",     perf_fee_bps=1000, debt_ratio_bps=3000, mean_annual_return=0.08, std_annual_return=0.12),
        StrategySpec(name="Curve",    perf_fee_bps=1500, debt_ratio_bps=2000, mean_annual_return=0.04, std_annual_return=0.06),
    ]

    # Run simulation
    sim_result = simulate_strategies_compounding(
        strategies=strategies,
        initial_vault_assets=10_000_000,
        initial_idle_ratio=0.30,
        years=20,
        periods_per_year=12,
        vault_performance_fee_bps=VaultConstants.PERFORMANCE_FEE_BPS,
        vault_management_fee_bps=VaultConstants.MANAGEMENT_FEE_BPS,
        seed=2025
    )

    # Visualize
    visualize_simulation_to_pdf(sim_result, strategies, years=20, periods_per_year=12)
    visualize_simulation_local(sim_result, strategies, years=20, periods_per_year=12)
    # Print summary
    generate_summary(sim_result, strategies, years=20, periods_per_year=12)

    # Optionally show a small DataFrame snapshot (first 12 periods)
    print("\n=== Snapshot (first 12 periods) ===")
    print(sim_result.timeline.head(12).T[[0,1,2,3,4,5]].T)  # wide but illustrative

# 🔽 Add these lines 🔽
import glob
latest_pdf = sorted(glob.glob("vault_report_*.pdf"))[-1]
files.download(latest_pdf)
