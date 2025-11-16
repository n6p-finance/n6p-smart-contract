# N6P Finance - Deployment Quick Reference

## TL;DR - Deploy in 3 Steps

### Step 1: Setup Wallet
```bash
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY_HERE
```

### Step 2: Build
```bash
cd /home/asyam321/Startup/smart_contract/n6p-smart-contract/contracts
forge build
```

### Step 3: Deploy
```bash
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  --sender $(cast wallet address --account n6p-deployer)
```

---

## Do You Need DeploymentHelper.s.sol?

**Short answer**: No, not for basic deployment.

**When to use it**: 
- If you want helper functions for recording deployments
- If you're doing complex orchestration across multiple scripts
- If you want structured deployment logging

For your case, `deployBaseSepolia.s.sol` alone is sufficient to:
- ✅ Deploy Registry
- ✅ Deploy Vault implementations (DeFi & RWA)
- ✅ Deploy CommonFeeOracle
- ✅ Deploy HealthCheckOverall
- ✅ Deploy BaseStrategy
- ✅ Log all addresses and configuration

**You only need deployBaseSepolia.s.sol** - it's self-contained.

---

## What Each File Does

| File | Purpose | Need for deployment? |
|------|---------|----------------------|
| `deployBaseSepolia.s.sol` | **Main deployment script** | ✅ YES - Required |
| `DeploymentHelper.s.sol` | Helper utilities for logging | ❌ Optional |
| `export-deployment.sh` | Extract ABIs for frontend | ❌ Optional (post-deploy) |

---

## Typical Workflow

```
1. Import wallet                  → cast wallet import
2. Build contracts               → forge build
3. Deploy all contracts          → forge script deployBaseSepolia.s.sol --broadcast
4. Get deployed addresses        → From console output
5. Update deployment-config.ts   → Copy addresses
6. Export ABIs (optional)        → bash scripts/export-deployment.sh
7. Deploy to frontend            → Use config + ABIs
```

---

## Expected Output

When deployment succeeds, you'll see something like:

```
== Base Sepolia N6P Finance Deployment ==
Governance: 0x005684ac7c737bff821eccb377cc46e5a7dcb60d
Management: 0x005684ac7c737bff821eccb377cc46e5a7dcb60d
Guardian: 0x005684ac7c737bff821eccb377cc46e5a7dcb60d
Rewards: 0x005684ac7c737bff821eccb377cc46e5a7dcb60d

1. Deploying Registry...
Registry deployed at: 0x1234567890...

2. Deploying Vault Implementations...
Vault DeFi Implementation deployed at: 0x9876543210...
Vault RWA Implementation deployed at: 0xabcdef1234...

3. Deploying Supporting Contracts...
Fee Oracle deployed at: 0x...
Health Check deployed at: 0x...
Base Strategy deployed at: 0x...

=== Deployment Complete ===
Registry: 0x1234567890...
Vault DeFi Implementation: 0x9876543210...
Vault RWA Implementation: 0xabcdef1234...
Fee Oracle: 0x...
Health Check: 0x...
Base Strategy: 0x...
```

Copy these addresses to `deployment-config.ts`!

---

## Commands Cheat Sheet

```bash
# === SETUP ===
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY

# === INFO ===
cast wallet list
cast wallet address --account n6p-deployer
cast balance $(cast wallet address --account n6p-deployer) \
  --rpc-url https://sepolia.base.org

# === BUILD ===
cd contracts && forge build

# === DEPLOY ===
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --account n6p-deployer \
  --sender $(cast wallet address --account n6p-deployer)

# === VERIFY ===
forge verify-contract 0x... \
  src/core/Registry.sol:Registry \
  --chain 84532 \
  --verifier sourcify

# === CHECK ===
cast code 0xCONTRACT_ADDRESS --rpc-url https://sepolia.base.org
cast receipt 0xTX_HASH --rpc-url https://sepolia.base.org
```

---

## Debugging

```bash
# If wallet not found:
cast wallet import n6p-deployer --private-key YOUR_PRIVATE_KEY

# If build fails:
forge build --via-ir

# If deployment reverts (see details):
forge script script/deployBaseSepolia.s.sol \
  --rpc-url https://sepolia.base.org \
  -vvv

# If low balance:
cast balance $(cast wallet address --account n6p-deployer) \
  --rpc-url https://sepolia.base.org
```

---

## Important Notes

1. **DeploymentHelper.s.sol is NOT needed** for your deployment. It's a utility library that could be imported if you want advanced features, but `deployBaseSepolia.s.sol` is completely standalone.

2. **Only deploy deployBaseSepolia.s.sol** with the command above - Foundry will automatically compile and deploy it.

3. **Save the output** - Copy all deployed addresses to `deployment-config.ts`

4. **Verify on Basescan** - This makes your contract trustworthy for users

5. **Export ABIs for frontend** - Run `bash scripts/export-deployment.sh` after deployment (optional but recommended)

---

## See Also

- Full guide: `DEPLOYMENT.md`
- Frontend integration: `FRONTEND_INTEGRATION.md`
- Testing guide: `TESTING.md`
