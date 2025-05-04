# Frontend Environment Configuration

This guide explains how to configure the frontend application to connect to the deployed smart contracts.

## Environment Variables

Create a `.env.local` file in the `frontend-app` directory with the following content:

```
# Wallet Connect Project ID (required for RainbowKit)
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id

# Set to 'true' to use testnet contracts, 'false' for local development
NEXT_PUBLIC_USE_TESTNET=true

# Contract addresses
NEXT_PUBLIC_AI_DECISION_MODULE_ADDRESS=0xYourDeployedContractAddress
```

## Updating Contract Addresses

After deploying the AIDecisionModule contract to Mumbai testnet, update the following:

1. In `.env.local`, set the deployed contract address:
   ```
   NEXT_PUBLIC_AI_DECISION_MODULE_ADDRESS=0xYourDeployedContractAddress
   ```

2. In `src/config/web3.tsx`, update the Mumbai testnet address:
   ```typescript
   mumbai: {
     aiDecisionModule: '0xYourDeployedContractAddress',
   },
   ```

## Switching Between Environments

- For local development:
  ```
  NEXT_PUBLIC_USE_TESTNET=false
  ```

- For testnet deployment:
  ```
  NEXT_PUBLIC_USE_TESTNET=true
  ```

## Testing the Configuration

1. Start the development server:
   ```bash
   pnpm dev
   ```

2. Connect your wallet to Mumbai testnet

3. Navigate to the dashboard and verify that it's displaying data from the deployed contract

## Troubleshooting

- If you encounter connection issues, ensure your wallet is connected to the correct network
- Check the browser console for any contract-related errors
- Verify that the contract address in the configuration matches the deployed address
