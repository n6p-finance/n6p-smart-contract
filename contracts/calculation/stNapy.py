import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
import seaborn as sns

class RestakeStrategySimulator:
    def __init__(self):
        self.strategies = {
            'RestakeETH': {
                'debt_ratio': 0.50,
                'mean_return': 0.085,
                'std_dev': 0.03,
                'perf_fee': 0.10,
                'description': 'Main EigenLayer yield + base staking'
            },
            'LRTBoost': {
                'debt_ratio': 0.30,
                'mean_return': 0.045,
                'std_dev': 0.02,
                'perf_fee': 0.12,
                'description': 'Rewards and restake points yield layer'
            },
            'PendleYield': {
                'debt_ratio': 0.15,
                'mean_return': 0.035,
                'std_dev': 0.05,
                'perf_fee': 0.15,
                'description': 'Yield swap / Pendle market neutral returns'
            },
            'Idle': {
                'debt_ratio': 0.05,
                'mean_return': 0.00,
                'std_dev': 0.00,
                'perf_fee': 0.00,
                'description': 'Vault idle balance'
            }
        }
        
        # Validate debt ratios sum to 100%
        total_ratio = sum(strategy['debt_ratio'] for strategy in self.strategies.values())
        assert abs(total_ratio - 1.0) < 0.001, f"Debt ratios must sum to 100%, got {total_ratio*100}%"
    
    def simulate_returns(self, days=365, simulations=10000, correlation_matrix=None):
        """
        Simulate daily returns for the portfolio
        """
        n_strategies = len(self.strategies) - 1  # Exclude Idle
        strategy_names = [name for name in self.strategies.keys() if name != 'Idle']
        
        # Default correlation matrix (assuming low correlation between strategies)
        if correlation_matrix is None:
            correlation_matrix = np.array([
                [1.0, 0.3, 0.2],  # RestakeETH correlations
                [0.3, 1.0, 0.1],  # LRTBoost correlations
                [0.2, 0.1, 1.0]   # PendleYield correlations
            ])
        
        # Convert annual to daily parameters
        daily_means = []
        daily_volatilities = []
        weights = []
        
        for name in strategy_names:
            strategy = self.strategies[name]
            daily_mean = (1 + strategy['mean_return']) ** (1/365) - 1
            daily_vol = strategy['std_dev'] / np.sqrt(365)
            daily_means.append(daily_mean)
            daily_volatilities.append(daily_vol)
            weights.append(strategy['debt_ratio'])
        
        weights = np.array(weights)
        
        # Generate correlated returns
        cov_matrix = np.outer(daily_volatilities, daily_volatilities) * correlation_matrix
        L = np.linalg.cholesky(cov_matrix)
        
        portfolio_returns = np.zeros((simulations, days))
        strategy_returns_detailed = {}
        
        for i in range(simulations):
            # Generate uncorrelated random shocks
            Z = np.random.normal(0, 1, (n_strategies, days))
            # Transform to correlated returns
            correlated_returns = daily_means[:, None] + L @ Z
            
            # Calculate portfolio returns (weighted sum)
            for day in range(days):
                daily_portfolio_return = np.sum(weights * correlated_returns[:, day])
                portfolio_returns[i, day] = daily_portfolio_return
            
            # Store detailed returns for one simulation for analysis
            if i == 0:
                for j, name in enumerate(strategy_names):
                    strategy_returns_detailed[name] = correlated_returns[j]
        
        return portfolio_returns, strategy_returns_detailed
    
    def apply_performance_fees(self, gross_returns):
        """
        Apply performance fees to gross returns
        """
        net_returns = gross_returns.copy()
        strategy_names = [name for name in self.strategies.keys() if name != 'Idle']
        
        for name in strategy_names:
            strategy = self.strategies[name]
            perf_fee = strategy['perf_fee']
            # Only apply fee to positive returns
            positive_returns = np.maximum(gross_returns, 0)
            fee_impact = positive_returns * perf_fee * self.strategies[name]['debt_ratio']
            net_returns -= fee_impact
        
        return net_returns
    
    def calculate_portfolio_metrics(self, portfolio_returns):
        """
        Calculate key portfolio metrics
        """
        # Convert daily returns to annualized
        annual_returns = (1 + portfolio_returns).prod(axis=1) - 1
        
        metrics = {
            'mean_apy': np.mean(annual_returns) * 100,
            'median_apy': np.median(annual_returns) * 100,
            'std_apy': np.std(annual_returns) * 100,
            'min_apy': np.min(annual_returns) * 100,
            'max_apy': np.max(annual_returns) * 100,
            'sharpe_ratio': np.mean(annual_returns) / np.std(annual_returns) if np.std(annual_returns) > 0 else 0,
            'var_95': np.percentile(annual_returns, 5) * 100,  # 5% VaR
            'cvar_95': annual_returns[annual_returns <= np.percentile(annual_returns, 5)].mean() * 100
        }
        
        # Probability of achieving target APYs
        metrics['prob_above_8'] = (annual_returns > 0.08).mean() * 100
        metrics['prob_above_10'] = (annual_returns > 0.10).mean() * 100
        metrics['prob_above_12'] = (annual_returns > 0.12).mean() * 100
        
        return metrics, annual_returns
    
    def run_monte_carlo_analysis(self, simulations=50000, days=365):
        """
        Run comprehensive Monte Carlo simulation
        """
        print("🚀 Running Restake Aggregator Vault Simulation...")
        print("=" * 60)
        
        # Simulate returns
        gross_returns, detailed_returns = self.simulate_returns(days=days, simulations=simulations)
        
        # Apply fees
        net_returns = self.apply_performance_fees(gross_returns)
        
        # Calculate metrics
        gross_metrics, gross_annual = self.calculate_portfolio_metrics(gross_returns)
        net_metrics, net_annual = self.calculate_portfolio_metrics(net_returns)
        
        return {
            'gross': gross_metrics,
            'net': net_metrics,
            'gross_annual_returns': gross_annual,
            'net_annual_returns': net_annual,
            'detailed_returns': detailed_returns
        }
    
    def plot_results(self, results):
        """
        Create comprehensive visualization of results
        """
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Plot 1: APY Distribution
        axes[0,0].hist(results['net_annual_returns'] * 100, bins=50, alpha=0.7, color='skyblue', edgecolor='black')
        axes[0,0].axvline(results['net']['mean_apy'], color='red', linestyle='--', label=f"Mean: {results['net']['mean_apy']:.2f}%")
        axes[0,0].axvline(results['net']['median_apy'], color='green', linestyle='--', label=f"Median: {results['net']['median_apy']:.2f}%")
        axes[0,0].set_xlabel('APY (%)')
        axes[0,0].set_ylabel('Frequency')
        axes[0,0].set_title('Distribution of Net APY After Fees')
        axes[0,0].legend()
        axes[0,0].grid(True, alpha=0.3)
        
        # Plot 2: Strategy Contribution
        strategy_data = []
        for name, strategy in self.strategies.items():
            if name != 'Idle':
                contribution = strategy['debt_ratio'] * strategy['mean_return'] * 100
                strategy_data.append([name, contribution, strategy['debt_ratio'] * 100])
        
        df_strategy = pd.DataFrame(strategy_data, columns=['Strategy', 'APY_Contribution', 'Allocation'])
        
        axes[0,1].bar(df_strategy['Strategy'], df_strategy['APY_Contribution'], color=['#FF6B6B', '#4ECDC4', '#45B7D1'])
        axes[0,1].set_ylabel('APY Contribution (%)')
        axes[0,1].set_title('Strategy APY Contribution by Allocation')
        axes[0,1].tick_params(axis='x', rotation=45)
        
        for i, v in enumerate(df_strategy['APY_Contribution']):
            axes[0,1].text(i, v + 0.1, f'{v:.2f}%', ha='center', va='bottom')
        
        # Plot 3: Risk-Return Scatter
        simulations_to_plot = min(1000, len(results['net_annual_returns']))
        sample_returns = np.random.choice(results['net_annual_returns'], simulations_to_plot) * 100
        
        axes[1,0].scatter([results['net']['std_apy']] * simulations_to_plot, sample_returns, 
                         alpha=0.6, color='purple')
        axes[1,0].axhline(y=results['net']['mean_apy'], color='red', linestyle='--', label='Mean APY')
        axes[1,0].set_xlabel('Volatility (Standard Deviation)')
        axes[1,0].set_ylabel('APY (%)')
        axes[1,0].set_title('Risk-Return Profile')
        axes[1,0].legend()
        axes[1,0].grid(True, alpha=0.3)
        
        # Plot 4: Probability Analysis
        probability_data = {
            'Target APY': ['>8%', '>10%', '>12%'],
            'Probability (%)': [
                results['net']['prob_above_8'],
                results['net']['prob_above_10'], 
                results['net']['prob_above_12']
            ]
        }
        df_prob = pd.DataFrame(probability_data)
        
        bars = axes[1,1].bar(df_prob['Target APY'], df_prob['Probability (%)'], color=['#96CEB4', '#FFEAA7', '#DDA0DD'])
        axes[1,1].set_ylabel('Probability (%)')
        axes[1,1].set_title('Probability of Exceeding Target APYs')
        
        for bar, prob in zip(bars, df_prob['Probability (%)']):
            axes[1,1].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
                          f'{prob:.1f}%', ha='center', va='bottom')
        
        plt.tight_layout()
        plt.show()
        
        # Print detailed metrics table
        self.print_metrics_table(results)
    
    def print_metrics_table(self, results):
        """
        Print detailed metrics comparison
        """
        print("\n📊 STRATEGY PERFORMANCE METRICS")
        print("=" * 80)
        
        metrics_data = []
        for name, strategy in self.strategies.items():
            metrics_data.append([
                name,
                f"{strategy['debt_ratio'] * 100:.1f}%",
                f"{strategy['mean_return'] * 100:.2f}%",
                f"{strategy['std_dev'] * 100:.2f}%",
                f"{strategy['perf_fee'] * 100:.1f}%",
                strategy['description']
            ])
        
        df_strategies = pd.DataFrame(metrics_data, 
                                   columns=['Strategy', 'Allocation', 'Mean Return', 'Volatility', 'Perf Fee', 'Description'])
        print(df_strategies.to_string(index=False))
        
        print("\n🎯 PORTFOLIO-LEVEL RESULTS")
        print("=" * 80)
        
        portfolio_metrics = [
            ["Metric", "Gross APY (No Fees)", "Net APY (After Fees)", "Impact"],
            ["Mean APY", f"{results['gross']['mean_apy']:.2f}%", f"{results['net']['mean_apy']:.2f}%", 
             f"{- (results['gross']['mean_apy'] - results['net']['mean_apy']):.2f}%"],
            ["Median APY", f"{results['gross']['median_apy']:.2f}%", f"{results['net']['median_apy']:.2f}%", 
             f"{- (results['gross']['median_apy'] - results['net']['median_apy']):.2f}%"],
            ["Volatility", f"{results['gross']['std_apy']:.2f}%", f"{results['net']['std_apy']:.2f}%", "—"],
            ["Sharpe Ratio", f"{results['gross']['sharpe_ratio']:.2f}", f"{results['net']['sharpe_ratio']:.2f}", "—"],
            ["5% VaR", f"{results['gross']['var_95']:.2f}%", f"{results['net']['var_95']:.2f}%", "—"],
            ["5% CVaR", f"{results['gross']['cvar_95']:.2f}%", f"{results['net']['cvar_95']:.2f}%", "—"]
        ]
        
        for row in portfolio_metrics:
            print(f"{row[0]:<15} {row[1]:<20} {row[2]:<20} {row[3]:<10}")
        
        print(f"\n📈 PROBABILITY ANALYSIS (After Fees)")
        print(f"Probability of APY > 8%:  {results['net']['prob_above_8']:.1f}%")
        print(f"Probability of APY > 10%: {results['net']['prob_above_10']:.1f}%")
        print(f"Probability of APY > 12%: {results['net']['prob_above_12']:.1f}%")
        
        print(f"\n💡 INTERPRETATION")
        print(f"Expected Net APY Range: {max(0, results['net']['mean_apy'] - results['net']['std_apy']):.1f}% - {results['net']['mean_apy'] + results['net']['std_apy']:.1f}%")
        print(f"Risk-Adjusted Performance (Sharpe): {results['net']['sharpe_ratio']:.2f}")
        if results['net']['sharpe_ratio'] > 1.2:
            print("✅ Excellent risk-adjusted returns")
        elif results['net']['sharpe_ratio'] > 0.8:
            print("🟡 Good risk-adjusted returns")
        else:
            print("🔴 Moderate risk-adjusted returns")

# Run the simulation
if __name__ == "__main__":
    # Initialize simulator
    simulator = RestakeStrategySimulator()
    
    # Run Monte Carlo analysis
    results = simulator.run_monte_carlo_analysis(simulations=50000, days=365)
    
    # Plot results
    simulator.plot_results(results)
    
    # Additional sensitivity analysis
    print("\n" + "="*60)
    print("🔍 SENSITIVITY ANALYSIS")
    print("="*60)
    
    # Test different correlation scenarios
    correlation_scenarios = {
        'Low Correlation (Diversified)': np.array([[1.0, 0.2, 0.1], [0.2, 1.0, 0.1], [0.1, 0.1, 1.0]]),
        'Medium Correlation': np.array([[1.0, 0.5, 0.3], [0.5, 1.0, 0.4], [0.3, 0.4, 1.0]]),
        'High Correlation (Risky)': np.array([[1.0, 0.8, 0.7], [0.8, 1.0, 0.6], [0.7, 0.6, 1.0]])
    }
    
    for scenario_name, corr_matrix in correlation_scenarios.items():
        temp_returns, _ = simulator.simulate_returns(simulations=10000, correlation_matrix=corr_matrix)
        net_temp_returns = simulator.apply_performance_fees(temp_returns)
        metrics, _ = simulator.calculate_portfolio_metrics(net_temp_returns)
        print(f"{scenario_name}: {metrics['mean_apy']:.2f}% APY, Sharpe: {metrics['sharpe_ratio']:.2f}")