# Test info

- Name: Navigation >> should navigate between pages
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/navigation.spec.ts:4:7

# Error details

```
Error: locator.click: Test timeout of 30000ms exceeded.
Call log:
  - waiting for getByRole('link', { name: 'Decisions' })

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/navigation.spec.ts:13:57
```

# Page snapshot

```yaml
- navigation:
  - link "NapFi AI":
    - /url: /
  - button "Open main menu"
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
   3 | test.describe('Navigation', () => {
   4 |   test('should navigate between pages', async ({ page }) => {
   5 |     // Start at the home page
   6 |     await page.goto('/');
   7 |     
   8 |     // Verify we're on the home page
   9 |     await expect(page).toHaveTitle(/NapFi AI/);
  10 |     await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
  11 |     
  12 |     // Navigate to the decisions page
> 13 |     await page.getByRole('link', { name: 'Decisions' }).click();
     |                                                         ^ Error: locator.click: Test timeout of 30000ms exceeded.
  14 |     await expect(page.url()).toContain('/decisions');
  15 |     await expect(page.getByRole('heading', { name: 'AI Decision History' })).toBeVisible();
  16 |     
  17 |     // Navigate to the strategies page
  18 |     await page.getByRole('link', { name: 'Strategies' }).click();
  19 |     await expect(page.url()).toContain('/strategies');
  20 |     await expect(page.getByRole('heading', { name: 'Available Strategies' })).toBeVisible();
  21 |     
  22 |     // Navigate to the verify page
  23 |     await page.getByRole('link', { name: 'Verify' }).click();
  24 |     await expect(page.url()).toContain('/verify');
  25 |     await expect(page.getByRole('heading', { name: 'MCP Decision Verification' })).toBeVisible();
  26 |     
  27 |     // Navigate back to the home page
  28 |     await page.getByRole('link', { name: 'Dashboard' }).click();
  29 |     await expect(page.url()).toBe('http://localhost:3000/');
  30 |     await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
  31 |   });
  32 | });
  33 |
```