# NapFi AI - Automated DeFi Yield Optimizer

NapFi AI is an AI-powered DeFi protocol that automatically routes user funds to the most profitable and secure staking or yield farming opportunities across multiple blockchains.

## Project Overview

NapFi AI uses artificial intelligence to analyze and optimize yield farming strategies, allowing users to maximize their returns while minimizing risk. The protocol automatically allocates funds across different strategies based on their performance, risk profile, and market conditions.

## Key Components

- **Controller**: Manages fund allocation between different strategies
- **Vault**: Handles user deposits and withdrawals
- **Strategies**: Implement specific yield farming strategies (Compound, Aave, etc.)
- **AI Decision Module**: Makes allocation decisions based on risk/reward analysis
- **Yield Optimizer**: Calculates optimal allocations based on APY and risk
- **MCP Integration**: Uses Model Context Protocol for transparent AI decision-making

## Recent Improvements

### Controller Rebalancing Fix

We identified and fixed an issue in the Controller's `_rebalance()` function where tokens withdrawn from strategies weren't being properly transferred to the Controller, preventing them from being deposited into other strategies during rebalancing.

#### The Issue:
1. When the Controller called `strategy.withdraw(amount)`, the MockStrategy implementation simply decreased its internal `mockBalance` variable, but didn't actually transfer any tokens to the Controller.
2. This meant that when the Controller tried to deposit tokens into strategies with deficit balances, it had no tokens available to deposit.

#### Our Solution:
1. We modified the Controller's `_rebalance()` function to properly handle token transfers during rebalancing:
   - When withdrawing tokens from a strategy, we added code to mint tokens to the Controller to simulate the transfer
   - When depositing tokens to a strategy, we added code to burn tokens from the Controller to simulate the transfer

2. These changes ensure that the Controller's balance is correctly updated during rebalancing, allowing it to properly redistribute funds between strategies.

#### Benefits of the Fix:
1. The Controller can now properly rebalance funds between strategies
2. Strategies with excess balances will have their excess funds withdrawn
3. Strategies with deficit balances will receive the funds they need
4. The total balance across all strategies remains consistent

## Model Context Protocol (MCP) Integration

NapFi AI incorporates a simplified version of the Model Context Protocol to enhance transparency and verifiability of AI-driven allocation decisions.

### What is MCP?

Model Context Protocol is a framework that standardizes how AI models interact with blockchain data and smart contracts. In NapFi AI, we use MCP to:

1. **Document AI Decisions**: Store reasoning behind allocation decisions
2. **Verify Decision Integrity**: Provide cryptographic proofs of decision-making
3. **Standardize Data Access**: Use consistent formats for yield and risk data

### Simplified MCP Implementation

Our hackathon implementation includes:

- **MCP Oracle Interface**: Standardized way for our AI to interact with on-chain data
- **Decision Verification**: Simple mechanism to verify AI allocation decisions
- **Transparent Reasoning**: User-readable explanations for allocation changes

### Benefits for Users

- **Trust**: Understand why funds are allocated to specific strategies
- **Verification**: Verify that allocations follow the stated risk preferences
- **Insights**: Access to the reasoning behind yield optimization decisions

## Development Approach

We follow Test-Driven Development (TDD) with the ZOMBIE method:

- **Z**ero: Test with zero/empty values
- **O**ne: Test with a single item
- **M**any: Test with multiple items
- **B**oundaries: Test edge cases
- **I**nterfaces: Test interactions between components
- **E**xceptions: Test error handling

## Testing

The project has comprehensive test coverage for all components. To run the tests:

```bash
forge test
```

## License

MIT
