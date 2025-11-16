# N6P Finance Frontend Integration Guide

## Overview

This guide covers how to integrate N6P Finance smart contracts with your frontend application. After deployment, all contract ABIs and addresses will be available in the deployment configuration.

## Setup

### 1. Import Configuration

```typescript
import { BASE_SEPOLIA_CONFIG, getVaultAddress, getTokenConfig } from './deployment-config';

// Or use the exported ABIs
import * as ContractABIs from './abis';
```

### 2. Initialize Web3 Provider

```typescript
import { ethers } from 'ethers';

// Using Viem (recommended for modern dApps)
import { createPublicClient, http, createWalletClient } from 'viem';
import { baseSepolia } from 'viem/chains';

const publicClient = createPublicClient({
  chain: baseSepolia,
  transport: http(BASE_SEPOLIA_CONFIG.rpcUrl),
});

const walletClient = createWalletClient({
  chain: baseSepolia,
  transport: http(),
});

// Or using ethers.js (legacy)
const provider = new ethers.JsonRpcProvider(BASE_SEPOLIA_CONFIG.rpcUrl);
```

## Contract Interactions

### Registry Contract

The Registry manages all vaults and releases in the N6P ecosystem.

```typescript
import { getContract } from 'viem';

const registry = getContract({
  address: BASE_SEPOLIA_CONFIG.addresses.registry,
  abi: ContractABIs.Registry,
  client: { public: publicClient, wallet: walletClient },
});

// Get all releases
const releaseCount = await registry.read.releaseCount();

// Get a specific release
const release = await registry.read.releases([0]);

// Get vault addresses for a token
const vaults = await registry.read.vaultsForRelease([release]);
```

### Vault Contracts (DeFi & RWA)

Vaults are the main contracts users interact with for deposits and withdrawals.

```typescript
// Get vault contract
const vaultAddress = getVaultAddress('USDC');
const vault = getContract({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  client: { public: publicClient, wallet: walletClient },
});

// Read vault information
const name = await vault.read.name();
const symbol = await vault.read.symbol();
const asset = await vault.read.asset();
const totalAssets = await vault.read.totalAssets();
const totalSupply = await vault.read.totalSupply();

// Calculate shares for deposit amount
const depositAmount = ethers.parseUnits('1000', 6); // 1000 USDC
const sharesOut = await vault.read.convertToShares([depositAmount]);

// Calculate assets for shares
const shareAmount = ethers.parseUnits('100', 18); // 100 vault shares
const assetsOut = await vault.read.convertToAssets([shareAmount]);
```

### Deposit Workflow

```typescript
const userAddress = '0x...'; // Connected user
const depositAmount = ethers.parseUnits('1000', 6); // 1000 USDC

// 1. Check allowance
const tokenContract = getContract({
  address: asset,
  abi: ContractABIs.ERC20,
  client: { public: publicClient, wallet: walletClient },
});

const allowance = await tokenContract.read.allowance([userAddress, vaultAddress]);

// 2. Approve if needed
if (allowance < depositAmount) {
  const approveTx = await walletClient.writeContract({
    address: asset,
    abi: ContractABIs.ERC20,
    functionName: 'approve',
    args: [vaultAddress, depositAmount],
    account: userAddress,
  });
  
  await publicClient.waitForTransactionReceipt({ hash: approveTx });
}

// 3. Deposit into vault
const depositTx = await walletClient.writeContract({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  functionName: 'deposit',
  args: [depositAmount, userAddress],
  account: userAddress,
});

await publicClient.waitForTransactionReceipt({ hash: depositTx });
```

### Withdrawal Workflow

```typescript
const shareAmount = ethers.parseUnits('100', 18); // 100 vault shares

// Withdraw shares for assets
const withdrawTx = await walletClient.writeContract({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  functionName: 'withdraw',
  args: [
    shareAmount,      // max amount of assets to withdraw
    userAddress,      // recipient
    userAddress,      // owner
  ],
  account: userAddress,
});

await publicClient.waitForTransactionReceipt({ hash: withdrawTx });
```

### EIP-2612 Permit Support

Vaults support permit() for gasless approvals:

```typescript
// Get permit signature from user
const permitData = await getPermitSignature({
  token: vaultAddress,
  owner: userAddress,
  spender: strategyAddress,
  amount: shareAmount,
  deadline: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
  chainId: BASE_SEPOLIA_CONFIG.chainId,
});

// Use permit in transaction
const tx = await walletClient.writeContract({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  functionName: 'permitWithdraw',
  args: [
    shareAmount,
    userAddress,
    userAddress,
    permitData.deadline,
    permitData.v,
    permitData.r,
    permitData.s,
  ],
  account: userAddress,
});
```

## Event Monitoring

### Listen to Vault Events

```typescript
// Deposit event
const unsubscribe = publicClient.watchContractEvent({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  eventName: 'Deposit',
  onLogs: (logs) => {
    logs.forEach(log => {
      console.log('Deposit:', {
        sender: log.args.sender,
        owner: log.args.owner,
        assets: log.args.assets,
        shares: log.args.shares,
      });
    });
  },
});

// Strategy event
publicClient.watchContractEvent({
  address: vaultAddress,
  abi: ContractABIs.VaultDeFi,
  eventName: 'StrategyChanged',
  onLogs: (logs) => {
    console.log('Strategy changed:', logs);
  },
});
```

## Utility Functions

### Format Numbers

```typescript
// Format tokens for display
function formatToken(amount: bigint, decimals: number = 6): string {
  return ethers.formatUnits(amount, decimals);
}

// Parse user input
function parseTokenInput(amount: string, decimals: number = 6): bigint {
  return ethers.parseUnits(amount, decimals);
}

// Format percentage
function formatPercent(numerator: bigint, denominator: bigint): string {
  const percent = (Number(numerator) / Number(denominator)) * 100;
  return `${percent.toFixed(2)}%`;
}
```

### Vault Metrics

```typescript
// Calculate deposit fees
async function getDepositFeeAmount(vaultAddress: string, amount: bigint): Promise<bigint> {
  const vault = getContract({
    address: vaultAddress,
    abi: ContractABIs.VaultDeFi,
    client: { public: publicClient },
  });
  
  const feeOracle = getContract({
    address: BASE_SEPOLIA_CONFIG.addresses.feeOracle,
    abi: ContractABIs.CommonFeeOracle,
    client: { public: publicClient },
  });

  const fee = await feeOracle.read.depositFee([vaultAddress]);
  return (amount * fee) / 10000n; // fee is in basis points
}

// Calculate APY from price oracle
async function getVaultAPY(vaultAddress: string): Promise<string> {
  const yieldOracle = getContract({
    address: BASE_SEPOLIA_CONFIG.addresses.yieldOracle,
    abi: ContractABIs.YieldOracle,
    client: { public: publicClient },
  });

  const apy = await yieldOracle.read.getAPY([vaultAddress]);
  return formatPercent(apy, 10000n); // APY in basis points
}

// Get current locked profit degradation
async function getLockedProfit(vaultAddress: string): Promise<{
  lockedProfit: bigint;
  degradationPerBlock: bigint;
}> {
  const vault = getContract({
    address: vaultAddress,
    abi: ContractABIs.VaultDeFi,
    client: { public: publicClient },
  });

  return {
    lockedProfit: await vault.read.lockedProfit(),
    degradationPerBlock: await vault.read.lockedProfitDegradation(),
  };
}
```

## Common Patterns

### Check if Vault is Shutdown

```typescript
async function isVaultShutdown(vaultAddress: string): Promise<boolean> {
  const vault = getContract({
    address: vaultAddress,
    abi: ContractABIs.VaultDeFi,
    client: { public: publicClient },
  });

  return await vault.read.shutdown();
}
```

### Get User Vault Balance

```typescript
async function getUserVaultBalance(vaultAddress: string, userAddress: string): Promise<bigint> {
  const vault = getContract({
    address: vaultAddress,
    abi: ContractABIs.VaultDeFi,
    client: { public: publicClient },
  });

  return await vault.read.balanceOf([userAddress]);
}

// Get equivalent assets
async function getUserVaultAssets(vaultAddress: string, userAddress: string): Promise<bigint> {
  const vault = getContract({
    address: vaultAddress,
    abi: ContractABIs.VaultDeFi,
    client: { public: publicClient },
  });

  const shares = await vault.read.balanceOf([userAddress]);
  return await vault.read.convertToAssets([shares]);
}
```

### Monitor Health Check Status

```typescript
async function getVaultHealthStatus(vaultAddress: string): Promise<{
  isHealthy: boolean;
  lastReport: number;
  lossTolerance: bigint;
}> {
  const healthCheck = getContract({
    address: BASE_SEPOLIA_CONFIG.addresses.healthCheck,
    abi: ContractABIs.HealthCheckOverall,
    client: { public: publicClient },
  });

  return {
    isHealthy: await healthCheck.read.isVaultHealthy([vaultAddress]),
    lastReport: await healthCheck.read.lastReportTime([vaultAddress]),
    lossTolerance: await healthCheck.read.getLossTolerance([vaultAddress]),
  };
}
```

## Error Handling

```typescript
import { ContractFunctionExecutionError } from 'viem';

async function safeVaultDeposit(
  vaultAddress: string,
  depositAmount: bigint,
  userAddress: string,
) {
  try {
    // Check vault is not shutdown
    const vault = getContract({
      address: vaultAddress,
      abi: ContractABIs.VaultDeFi,
      client: { public: publicClient },
    });

    if (await vault.read.shutdown()) {
      throw new Error('Vault is shutdown');
    }

    // Check sufficient balance
    const asset = await vault.read.asset();
    const token = getContract({
      address: asset,
      abi: ContractABIs.ERC20,
      client: { public: publicClient },
    });

    const balance = await token.read.balanceOf([userAddress]);
    if (balance < depositAmount) {
      throw new Error('Insufficient balance');
    }

    // Execute deposit
    const tx = await walletClient.writeContract({
      address: vaultAddress,
      abi: ContractABIs.VaultDeFi,
      functionName: 'deposit',
      args: [depositAmount, userAddress],
      account: userAddress,
    });

    return tx;
  } catch (error) {
    if (error instanceof ContractFunctionExecutionError) {
      console.error('Contract error:', error.shortMessage);
    } else {
      console.error('Error:', error);
    }
    throw error;
  }
}
```

## Environment Configuration

After deployment, update your `.env` file:

```bash
# Network Configuration
VITE_CHAIN_ID=84532
VITE_RPC_URL=https://sepolia.base.org

# Contract Addresses (update with actual deployed addresses)
VITE_REGISTRY_ADDRESS=0x...
VITE_VAULT_DEFI_IMPL=0x...
VITE_VAULT_RWA_IMPL=0x...
VITE_FEE_ORACLE=0x...
VITE_HEALTH_CHECK=0x...
VITE_BASE_STRATEGY=0x...

# Role Addresses
VITE_GOVERNANCE=0x005684ac7c737bff821eccb377cc46e5a7dcb60d
VITE_MANAGEMENT=0x005684ac7c737bff821eccb377cc46e5a7dcb60d
VITE_GUARDIAN=0x005684ac7c737bff821eccb377cc46e5a7dcb60d
```

## Testing Integration

```typescript
describe('Vault Integration', () => {
  it('should deposit and withdraw', async () => {
    const depositAmount = ethers.parseUnits('1000', 6);
    
    // Deposit
    const depositTx = await walletClient.writeContract({
      address: vaultAddress,
      abi: ContractABIs.VaultDeFi,
      functionName: 'deposit',
      args: [depositAmount, userAddress],
      account: userAddress,
    });
    
    await publicClient.waitForTransactionReceipt({ hash: depositTx });
    
    // Check balance
    const balance = await vault.read.balanceOf([userAddress]);
    expect(balance).toBeGreaterThan(0n);
  });
});
```

## Support

For detailed contract documentation, see:
- `ARCHITECTURE.md` - Overall system architecture
- `contracts/src/interfaces/IVaultAPI.sol` - Vault interface specification
- `contracts/src/core/Registry.sol` - Registry contract source

For questions or issues, open an issue in the GitHub repository.
