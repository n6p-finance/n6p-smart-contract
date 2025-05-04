# Test info

- Name: Dashboard Page >> should have responsive layout
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/dashboard.spec.ts:48:7

# Error details

```
Error: expect.toHaveClass: Error: strict mode violation: locator('.grid') resolved to 2 elements:
    1) <div role="list" class="grid grid-cols-1 lg:grid-cols-2 gap-6">…</div> aka getByRole('list').filter({ hasText: 'Your PortfolioTotal Value$10,' })
    2) <div class="grid grid-cols-3 gap-4 mb-8">…</div> aka getByText('Total Value$10,245.67+2.4% (24h)Current APY4.2%+0.3% from last weekRisk Score3.')

Call log:
  - expect.toHaveClass with timeout 5000ms
  - waiting for locator('.grid')

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/dashboard.spec.ts:57:30
```

# Page snapshot

```yaml
- navigation:
  - link "NapFi AI":
    - /url: /
  - link "Dashboard":
    - /url: /
  - link "Strategies":
    - /url: /strategies
  - link "AI Decisions":
    - /url: /decisions
  - button "Connect Wallet"
- main:
  - heading "NapFi AI Dashboard" [level=1]
  - paragraph: Not connected
  - list:
    - heading "Your Portfolio" [level=2]
    - heading "Total Value" [level=3]
    - paragraph: $10,245.67
    - paragraph: +2.4% (24h)
    - heading "Current APY" [level=3]
    - paragraph: 4.2%
    - paragraph: +0.3% from last week
    - heading "Risk Score" [level=3]
    - paragraph: 3.5/10
    - paragraph: Low risk profile
    - heading "Current Allocation" [level=3]
    - text: USDC Lending 45% ETH Staking 30% Curve LP 15% Balancer LP 10%
    - heading "AI Decision Insights" [level=2]
    - paragraph: Understand why NapFi AI has allocated your funds this way
    - paragraph: Connect your wallet to view AI allocation decisions
    - heading "Decision History" [level=3]
    - list:
      - listitem:
        - text: May 1, 2025 Initial allocation
        - button "View"
      - listitem:
        - text: May 15, 2025 Rebalance due to market change
        - button "View"
      - listitem:
        - text: June 1, 2025 Added new strategy
        - button "View"
- alert
- button "Open Next.js Dev Tools":
  - img
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('Dashboard Page', () => {
   4 |   test('should display dashboard components correctly', async ({ page }) => {
   5 |     // Go to the dashboard page
   6 |     await page.goto('/');
   7 |     
   8 |     // Verify the page title
   9 |     await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
  10 |     
  11 |     // Check for loading state initially
  12 |     const loadingSpinner = page.getByTestId('loading-spinner');
  13 |     if (await loadingSpinner.isVisible()) {
  14 |       // Wait for loading to complete
  15 |       await expect(loadingSpinner).not.toBeVisible({ timeout: 10000 });
  16 |     }
  17 |     
  18 |     // Verify portfolio section is visible after loading
  19 |     await expect(page.getByText('Your Portfolio')).toBeVisible();
  20 |     await expect(page.getByText('Total Value')).toBeVisible();
  21 |     await expect(page.getByText('Current APY')).toBeVisible();
  22 |     await expect(page.getByText('Risk Score')).toBeVisible();
  23 |     
  24 |     // Verify allocation chart is visible
  25 |     await expect(page.getByText('Current Allocation')).toBeVisible();
  26 |     
  27 |     // Verify decision history section
  28 |     await expect(page.getByText('Decision History')).toBeVisible();
  29 |   });
  30 |   
  31 |   test('should handle wallet connection state', async ({ page }) => {
  32 |     // Go to the dashboard page
  33 |     await page.goto('/');
  34 |     
  35 |     // Check if the wallet connection status is displayed
  36 |     const walletStatus = page.locator('.bg-gray-100.px-4.py-2.rounded-full');
  37 |     await expect(walletStatus).toBeVisible();
  38 |     
  39 |     // Note: In a real test, we would mock the wallet connection
  40 |     // For now, we'll just verify the UI elements are present
  41 |     
  42 |     // Check if the latest AI decision section displays appropriate content
  43 |     // This could be either the decision card or a message to connect wallet
  44 |     const latestDecisionSection = page.getByText('Latest AI Decision').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
  45 |     await expect(latestDecisionSection).toBeVisible();
  46 |   });
  47 |   
  48 |   test('should have responsive layout', async ({ page }) => {
  49 |     // Go to the dashboard page
  50 |     await page.goto('/');
  51 |     
  52 |     // Test desktop layout
  53 |     await page.setViewportSize({ width: 1280, height: 800 });
  54 |     
  55 |     // Check if the grid has desktop layout classes
  56 |     const gridLayout = page.locator('.grid');
> 57 |     await expect(gridLayout).toHaveClass(/lg:grid-cols-2/);
     |                              ^ Error: expect.toHaveClass: Error: strict mode violation: locator('.grid') resolved to 2 elements:
  58 |     
  59 |     // Test mobile layout
  60 |     await page.setViewportSize({ width: 375, height: 667 });
  61 |     
  62 |     // Check if the cards stack vertically on mobile
  63 |     await expect(gridLayout).toHaveClass(/grid-cols-1/);
  64 |     
  65 |     // Restore desktop view for other tests
  66 |     await page.setViewportSize({ width: 1280, height: 800 });
  67 |   });
  68 | });
  69 |
```