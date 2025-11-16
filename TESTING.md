# N6P Finance - Testing Guide

## Overview

This guide covers testing the N6P Finance smart contracts and frontend integration. The project uses Foundry for smart contract testing and Jest/Vitest for frontend integration tests.

## Smart Contract Testing (Foundry)

### Run All Tests

```bash
cd contracts
forge test
```

### Run Specific Test Suite

```bash
# Run a specific test file
forge test --match-path "test/function/vault/misc.t.sol"

# Run tests matching a pattern
forge test --match-test "test_vault_deposit"

# Run tests in a specific contract
forge test --match-contract "ConfigTest"
```

### Run with Coverage

```bash
forge coverage
```

Output in `lcov.info` for coverage reports.

### Debug Tests

```bash
# Run with verbose output
forge test -vv

# Run with very verbose output (including logs)
forge test -vvv

# Run with specific fuzz runs
forge test --fuzz-runs 10000
```

### Test Structure

Tests are organized by functionality:

```
contracts/test/
├── confest.t.sol           # Shared setup and utilities
├── function/
│   ├── registry/
│   │   ├── deployment.t.sol
│   │   └── ...
│   └── vault/
│       ├── config.t.sol        # Base config for all vaults
│       ├── permit.t.sol        # EIP-2612 permit tests
│       ├── shares.t.sol        # Share transfer tests
│       ├── misc.t.sol          # Miscellaneous vault tests
│       ├── strategies.t.sol    # Strategy management
│       └── losses.t.sol        # Loss reporting
```

### Key Test Files

#### ConfigTest (config.t.sol)

Base test contract inherited by all vault tests. Sets up vault proxies and users.

```solidity
// Base setup
address internal user = address(0x123);
address internal keeper = address(0x456);
IVault internal vault;

// Common assertions
function assertVaultName(string memory expectedName) internal {
    assertEq(vault.name(), expectedName);
}

function assertTotalAssets(uint256 expected) internal {
    assertEq(vault.totalAssets(), expected);
}
```

#### Permit Tests (permit.t.sol)

Tests EIP-2612 permit functionality for gasless approvals.

```solidity
// Key tests
test_permit_basic_approval()      // Basic permit flow
test_permit_expired()             // Expired permit rejection
test_permit_invalid_signature()   // Invalid signature handling
test_permit_domain_separator()    // Domain separator verification
```

#### Vault Operations Tests (misc.t.sol)

Tests core vault operations like deposits and withdrawals.

```solidity
// Key tests
test_vault_deposit()              // Basic deposit
test_vault_deposit_zero()         // Zero amount handling
test_vault_withdraw()             // Basic withdrawal
test_vault_emergency_shutdown()   // Shutdown mechanics
test_vault_deposit_limit()        // Max deposit checks
```

#### Registry Tests (deployment.t.sol)

Tests vault creation and registration.

```solidity
// Key tests
test_deployment_basic()           // Basic vault deployment
test_deployment_management()      // Management vault creation
test_experimental_deployments()   // Experimental vault factory
```

### Running Custom Tests

Create a new test file in `contracts/test/function/`:

```solidity
// contracts/test/function/vault/custom.t.sol

pragma solidity ^0.8.20;

import {ConfigTest} from "../config.t.sol";

contract CustomTest is ConfigTest {
    function setUp() public override {
        super.setUp();
        // Additional setup for custom tests
    }

    function test_custom_functionality() public {
        // Your test here
        assertEq(vault.totalAssets(), 0);
    }

    function test_custom_with_deposit() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        
        // Deposit and verify
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, address(this));
        
        assertGt(shares, 0);
        assertEq(vault.totalAssets(), depositAmount);
    }
}
```

Run your tests:

```bash
forge test --match-contract "CustomTest"
```

## Frontend Testing

### Setup

```bash
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom
```

### Unit Tests for Hooks

Create test files in `hooks/__tests__/`:

```typescript
// hooks/__tests__/useVault.test.ts

import { renderHook, waitFor } from '@testing-library/react';
import { useVaultInfo } from '../useVault';
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('useVaultInfo', () => {
  beforeEach(() => {
    // Mock publicClient and contract reads
    vi.clearAllMocks();
  });

  it('should fetch vault information', async () => {
    const { result } = renderHook(() =>
      useVaultInfo('0x1234567890123456789012345678901234567890')
    );

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.name).toBeDefined();
    expect(result.current.symbol).toBeDefined();
    expect(result.current.error).toBeNull();
  });

  it('should handle errors gracefully', async () => {
    // Mock error scenario
    const { result } = renderHook(() =>
      useVaultInfo('0x0000000000000000000000000000000000000000')
    );

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBeDefined();
  });
});
```

### Integration Tests

```typescript
// __tests__/integration.test.ts

import { describe, it, expect } from 'vitest';
import { depositVault, withdrawVault } from '../lib/vault';
import { BASE_SEPOLIA_CONFIG } from '../deployment-config';

describe('Vault Integration', () => {
  it('should execute complete deposit flow', async () => {
    const depositAmount = 1000n * 10n ** 6n; // 1000 USDC

    const result = await depositVault(
      BASE_SEPOLIA_CONFIG.addresses.registry,
      '0xusdc',
      depositAmount,
      '0xuser',
    );

    expect(result.hash).toBeDefined();
    expect(result.receipt.status).toBe('success');
  });

  it('should handle insufficient balance', async () => {
    const largeAmount = 10000000n * 10n ** 6n; // 10M USDC

    expect(async () => {
      await depositVault(
        BASE_SEPOLIA_CONFIG.addresses.registry,
        '0xusdc',
        largeAmount,
        '0xuser',
      );
    }).rejects.toThrow('Insufficient balance');
  });
});
```

### Component Tests

```typescript
// components/__tests__/VaultDeposit.test.tsx

import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { VaultDeposit } from '../VaultDeposit';
import { describe, it, expect } from 'vitest';

describe('VaultDeposit Component', () => {
  it('should render deposit form', () => {
    render(<VaultDeposit vaultAddress="0x123" />);

    expect(screen.getByLabelText(/deposit amount/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /deposit/i })).toBeInTheDocument();
  });

  it('should validate input', async () => {
    render(<VaultDeposit vaultAddress="0x123" />);

    const input = screen.getByLabelText(/deposit amount/i);
    fireEvent.change(input, { target: { value: '0' } });

    const button = screen.getByRole('button', { name: /deposit/i });
    fireEvent.click(button);

    await waitFor(() => {
      expect(
        screen.getByText(/amount must be greater than 0/i)
      ).toBeInTheDocument();
    });
  });

  it('should handle successful deposit', async () => {
    render(<VaultDeposit vaultAddress="0x123" />);

    const input = screen.getByLabelText(/deposit amount/i);
    fireEvent.change(input, { target: { value: '100' } });

    const button = screen.getByRole('button', { name: /deposit/i });
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/deposit successful/i)).toBeInTheDocument();
    });
  });
});
```

### Run Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test useVault.test.ts

# Run with coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```

## End-to-End Testing

### Setup Testnet Environment

1. Get Base Sepolia ETH from faucet:
   - https://www.alchemy.com/faucets/base-sepolia
   - https://sepoliafaucet.com/

2. Create test account and fund it

3. Set environment variables:

```bash
export PRIVATE_KEY="0x..."
export BASE_SEPOLIA_RPC="https://sepolia.base.org"
```

### Deploy to Testnet

```bash
cd contracts

# Deploy with Foundry
forge script script/deployBaseSepolia.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast

# Verify deployment
forge verify-contract <CONTRACT_ADDRESS> \
  --rpc-url $BASE_SEPOLIA_RPC \
  --etherscan-api-key $BASESCAN_API_KEY
```

### Test with Frontend

1. Update `deployment-config.ts` with deployed addresses

2. Start frontend dev server:

```bash
npm run dev
```

3. Test manual flows:
   - Connect wallet to Base Sepolia
   - Check vault information loads
   - Approve token
   - Deposit into vault
   - Verify balance updates
   - Withdraw from vault

### Automated E2E Tests

```typescript
// e2e/vault.test.ts

import { test, expect } from '@playwright/test';

test.describe('Vault E2E', () => {
  test('should deposit and withdraw', async ({ page }) => {
    // Connect wallet
    await page.goto('http://localhost:3000');
    await page.click('[data-testid="connect-wallet"]');
    // ... wallet connection steps ...

    // Navigate to vault
    await page.click('[data-testid="vault-nav"]');

    // Check vault info loads
    expect(await page.textContent('[data-testid="vault-name"]')).toBeTruthy();

    // Deposit
    await page.fill('[data-testid="deposit-input"]', '100');
    await page.click('[data-testid="deposit-button"]');

    // Wait for transaction
    await page.waitForSelector('[data-testid="deposit-success"]');
    expect(await page.textContent('[data-testid="user-balance"]')).toContain(
      '100'
    );

    // Withdraw
    await page.fill('[data-testid="withdraw-input"]', '50');
    await page.click('[data-testid="withdraw-button"]');

    // Verify
    await page.waitForSelector('[data-testid="withdraw-success"]');
    expect(await page.textContent('[data-testid="user-balance"]')).toContain(
      '50'
    );
  });
});
```

Run E2E tests:

```bash
npm run test:e2e
```

## Continuous Integration

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  contract-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: foundry-rs/foundry-toolchain@v1
      - run: cd contracts && forge test

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
      - run: npm run test:e2e
```

## Debugging Tips

### Smart Contract Debugging

```bash
# Run with gas reporting
forge test --gas-report

# Run with stack trace
forge test -vvv

# Run single test with verbose output
forge test --match-test "test_vault_deposit" -vvv

# Use console logs
import "forge-std/console.sol";
console.log("Value:", value);
```

### Frontend Debugging

```typescript
// Add debug logs
console.log('useVaultInfo', { vaultAddress, info });

// Use React DevTools browser extension
// Use Redux DevTools if using Redux

// Test individual functions
const mockPublicClient = {
  readContract: () => Promise.resolve(mockValue),
};
```

## Performance Testing

### Smart Contract Gas Usage

```bash
# Generate gas report
forge test --gas-report > gas-report.txt

# Compare gas between versions
forge test --gas-report > gas-report-new.txt
# Compare with previous report
```

### Frontend Performance

```typescript
// Measure render time
import { measureRender } from '@testing-library/react';

it('should render efficiently', () => {
  const time = measureRender(() => <VaultComponent />);
  expect(time).toBeLessThan(100); // milliseconds
});

// Check bundle size
npm run build:analyze
```

## Security Testing

### Smart Contract Security

```bash
# Run Slither security analysis
slither . --solc-remaps "@openzeppelin=$(pwd)/lib/openzeppelin-contracts"

# Run with specific checks
slither . --checklist
```

### Frontend Security

```bash
# Check dependencies for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Security headers check
npm run test:security
```

## Common Issues and Solutions

### Test Failing Due to Timestamp

```solidity
// Use vm.warp to set block timestamp
function test_time_dependent() public {
    vm.warp(block.timestamp + 1 days);
    // Your test here
}
```

### Test Failing Due to Random Value

```solidity
// Use vm.seed for deterministic randomness in tests
function test_deterministic() public {
    vm.seed(12345);
    // Your test here
}
```

### Permit Test Failing

```solidity
// Ensure domain separator is calculated correctly
bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
// Should match expected value based on vault name and version
```

### Hook Test Failing

```typescript
// Wrap hook in provider
import { WagmiConfig } from 'wagmi';

it('should work', () => {
  render(
    <WagmiConfig config={config}>
      <TestComponent />
    </WagmiConfig>
  );
});
```

## Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Vitest Documentation](https://vitest.dev/)
- [React Testing Library](https://testing-library.com/react)
- [Viem Documentation](https://viem.sh/)
- [Wagmi Documentation](https://wagmi.sh/)

## Support

For testing issues or questions:
1. Check test logs: `forge test -vvv`
2. Review contract code for logic errors
3. Check deployment config is correct
4. Open GitHub issue with detailed error message
