# N6P Finance - Base Sepolia Deployment Guide

## Overview

This guide walks you through deploying N6P Finance contracts to Base Sepolia testnet using Foundry's `forge script` command pattern from the Davis Kelvin workshop.

## Prerequisites

### 1. Install Foundry (if not already installed)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version  # Verify installation
```

### 2. Prepare Your Wallet

You have two options:

#### Option A: Using Cast Wallet Management (Recommended for Security)

```bash
# Import your private key into Cast
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY_HERE

# List saved wallets
cast wallet list

# Check your wallet address
cast wallet address --account n6p-deployer

# Check your balance
cast balance $(cast wallet address --account n6p-deployer) --rpc-url https://sepolia.base.org
```

#### Option B: Using Environment Variable

```bash
# Export your private key directly (less secure)
export PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE
```

### 3. Get Base Sepolia ETH

Get testnet ETH from one of these faucets:
- [Alchemy Faucet](https://www.alchemy.com/faucets/base-sepolia)
- [Superchain Faucet](https://console.optimism.io/faucet)
- [Sepoliafaucet.com](https://sepoliafaucet.com/)

## Project Structure

Your deployment scripts should be in:

```
contracts/
├── script/
│   ├── deployBaseSepolia.s.sol       # Main deployment orchestrator
│   ├── DeploymentHelper.s.sol         # Helper utilities (optional)
│   └── deploy.s.sol                   # (existing)
├── src/
│   ├── core/
│   │   ├── Registry.sol
│   │   ├── DeFi/UnifiedVault.sol
│   │   └── RWA/VaultRWA.sol
│   ├── BaseStrategy.sol
│   ├── CommonFeeOracle.sol
│   └── HealthCheckOverall.sol
└── foundry.toml
```

## Deployment Steps

### Step 1: Configure foundry.toml

Update `contracts/foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.20"

# Base Sepolia Configuration
[rpc_endpoints]
base_sepolia = "https://sepolia.base.org"
base_mainnet = "https://mainnet.base.org"

# Optional: Set default chain
[env.base_sepolia]
eth_rpc_url = "https://sepolia.base.org"
chain_id = 84532
```

### Step 2: Build Your Contracts

```bash
cd contracts
forge build
```

Expected output:
```
[⠒] Compiling...
[⠢] Compiling 8 files with 0.8.20
[⠆] Solc 0.8.20 finished in 234.56ms
Compiler run successful!
```

### Step 3: Deploy Using forge script

#### Using Cast Wallet (Recommended - Most Secure)

```bash
cd contracts

forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  --sender $(cast wallet address --account n6p-deployer)
```

You'll be prompted for your wallet password:
```
Enter password for 'n6p-deployer':
```

#### Using Private Key Environment Variable

```bash
cd contracts

export PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE

forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --private-key $PRIVATE_KEY
```

#### Using forge create (Simple Alternative - Single Contract)

If you want to deploy individual contracts:

```bash
forge create src/core/Registry.sol:Registry \
  --rpc-url https://sepolia.base.org \
  --account n6p-deployer
```

### Step 4: Verify Output

After successful deployment, you should see:

```
==== DEPLOYMENT SUCCESSFUL ====

Chain: Base Sepolia (84532)
RPC: https://sepolia.base.org

Transactions:
  [1] Registry deployed at: 0x...
  [2] UnifiedVault deployed at: 0x...
  [3] VaultRWA deployed at: 0x...
  [4] CommonFeeOracle deployed at: 0x...
  [5] HealthCheckOverall deployed at: 0x...
  [6] BaseStrategy deployed at: 0x...

Deployer: 0x...
Balance before: X.XX ETH
Balance after: Y.YY ETH
Gas spent: Z.ZZ ETH
```

## Understanding the Deployment Script

The `deployBaseSepolia.s.sol` script follows the Foundry pattern:

```solidity
contract DeployBaseSepolia is Script {
    function run() external {
        // 1. Setup config
        config = DeploymentConfig({...});
        
        // 2. Start broadcast (on-chain transactions)
        vm.startBroadcast();
        
        // 3. Deploy contracts
        deployed.registry = deployRegistry();
        deployed.unifiedVaultImpl = deployUnifiedVault();
        // ... more deployments
        
        // 4. Stop broadcast
        vm.stopBroadcast();
        
        // 5. Export results (no on-chain transaction)
        exportDeploymentData();
    }
}
```

### Key Components

- **vm.startBroadcast()**: Starts recording transactions that will be broadcast to the network
- **vm.stopBroadcast()**: Stops recording - anything after this only runs locally
- **@notice**: DeploymentHelper.s.sol can be imported if you need helper functions
- **console2.log()**: Logs to console during script execution

## Complete Deployment Example

Here's what happens when you run the deployment:

```bash
# 1. Go to contracts directory
cd /home/asyam321/Startup/smart_contract/n6p-smart-contract/contracts

# 2. Build first (important!)
forge build

# 3. Deploy
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  --sender 0x005684ac7c737bff821eccb377cc46e5a7dcb60d

# 4. You'll see:
# ==== SIMULATION ====
# [Contract deployments and calls...]
# 
# ==== BROADCASTING TRANSACTIONS ====
# [Sending transaction 1...]
# [Transaction confirmed at 0x...]
# ...
# ==== DEPLOYMENT SUMMARY ====
```

## Saving Deployment Results

After deployment, save the addresses:

```bash
# Option 1: Copy from console output to deployment-config.ts
# Manually update the addresses in deployment-config.ts

# Option 2: Export to file
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  > deployment_output.txt

# Then extract addresses from deployment_output.txt
```

Update `deployment-config.ts`:

```typescript
export const BASE_SEPOLIA_CONFIG = {
  addresses: {
    registry: "0x...",  // From deployment output
    unifiedVaultImplementation: "0x...",
    vaultRWAImplementation: "0x...",
    feeOracle: "0x...",
    healthCheck: "0x...",
    baseStrategy: "0x...",
  },
  // ... rest of config
};
```

## Contract Verification

After deployment, verify your contracts on Basescan:

### Using Forge Verify

```bash
# Get Etherscan API key from https://basescan.org/apis

export BASESCAN_API_KEY=YOUR_API_KEY

forge verify-contract \
  0x... \
  src/core/Registry.sol:Registry \
  --chain 84532 \
  --verifier-url https://api.basescan.org/api \
  --etherscan-api-key $BASESCAN_API_KEY
```

### Using Sourcify (Recommended - No API key needed)

```bash
forge verify-contract \
  0x... \
  src/core/Registry.sol:Registry \
  --chain 84532 \
  --verifier sourcify
```

## Troubleshooting

### Error: "call to non-contract address"

**Cause**: Your setup doesn't have enough gas or there's a network issue.

**Solution**:
```bash
# Check balance
cast balance $(cast wallet address --account n6p-deployer) \
  --rpc-url https://sepolia.base.org

# Get more ETH from faucet if needed
```

### Error: "Account not found"

**Cause**: Wallet wasn't imported correctly.

**Solution**:
```bash
# Reimport wallet
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY_HERE

# List wallets to verify
cast wallet list
```

### Error: "Compilation failed"

**Cause**: Missing dependencies or imports.

**Solution**:
```bash
cd contracts
forge build --via-ir  # Use IR optimization if needed
```

### Error: "Revert during simulation"

**Cause**: Your deployment script has logic errors.

**Solution**:
```bash
# Run with verbose output to see what's happening
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  -vvv
```

## Monitoring Deployment

### Check Transaction Status

```bash
# Using cast to check transaction
cast receipt 0xTX_HASH \
  --rpc-url https://sepolia.base.org

# Check contract was deployed
cast code 0xCONTRACT_ADDRESS \
  --rpc-url https://sepolia.base.org
```

### View on Basescan

Visit: `https://sepolia.basescan.org/address/0xCONTRACT_ADDRESS`

## Advanced: Custom Deployment Configurations

You can create multiple deployment scripts for different scenarios:

```solidity
// script/deployBaseSepolia.s.sol - Production
contract DeployBaseSepolia is Script { ... }

// script/deployBaseSepolia-Test.s.sol - Testing
contract DeployBaseSepolia-Test is Script { ... }

// script/deployBaseSepolia-Local.s.sol - Local anvil
contract DeployBaseSepolia-Local is Script { ... }
```

Run specific script:

```bash
forge script script/deployBaseSepolia-Test.s.sol ...
```

## Complete Commands Reference

```bash
# ============================================================================
# SETUP
# ============================================================================

# Import wallet
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY_HERE

# Check wallet
cast wallet address --account n6p-deployer

# Check balance
cast balance $(cast wallet address --account n6p-deployer) \
  --rpc-url https://sepolia.base.org

# ============================================================================
# BUILD
# ============================================================================

cd contracts
forge build

# ============================================================================
# DEPLOY
# ============================================================================

# Main deployment
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  --sender $(cast wallet address --account n6p-deployer)

# ============================================================================
# VERIFY
# ============================================================================

# Verify on Sourcify (no API key)
forge verify-contract \
  0xCONTRACT_ADDRESS \
  src/core/Registry.sol:Registry \
  --chain 84532 \
  --verifier sourcify

# ============================================================================
# CHECK
# ============================================================================

# View deployment on Basescan
# https://sepolia.basescan.org/address/0xCONTRACT_ADDRESS

# Check contract code
cast code 0xCONTRACT_ADDRESS --rpc-url https://sepolia.base.org

# Check transaction
cast receipt 0xTX_HASH --rpc-url https://sepolia.base.org
```

## Next Steps

1. **Deploy**: Run the deployment script above
2. **Save Addresses**: Update `deployment-config.ts` with deployed addresses
3. **Verify**: Run contract verification on Basescan
4. **Test**: Update frontend environment variables and test integration
5. **Export ABIs**: Run the ABI export script to generate ABIs for frontend

See `FRONTEND_INTEGRATION.md` for how to use the deployed contracts in your frontend.
