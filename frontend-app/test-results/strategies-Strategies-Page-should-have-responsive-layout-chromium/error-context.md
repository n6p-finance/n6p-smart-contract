# Test info

- Name: Strategies Page >> should have responsive layout
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/strategies.spec.ts:56:7

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toHaveClass(expected)

Locator: locator('.grid').last()
Expected pattern: /lg:grid-cols-3/
Received string:  "grid grid-cols-3 gap-4 mb-4"
Call log:
  - expect.toHaveClass with timeout 5000ms
  - waiting for locator('.grid').last()
    8 × locator resolved to <div class="grid grid-cols-3 gap-4 mb-4">…</div>
      - unexpected value "grid grid-cols-3 gap-4 mb-4"

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/strategies.spec.ts:65:30
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
  - heading "Available Strategies" [level=1]
  - paragraph: NapFi AI automatically allocates your funds across these strategies based on market conditions, risk profile, and yield opportunities.
  - heading "Aave Lending" [level=3]
  - paragraph: Deposit assets into Aave lending pools to earn interest from borrowers.
  - paragraph: APY
  - paragraph: 4.2%
  - paragraph: Risk
  - paragraph: Low
  - paragraph: TVL
  - paragraph: $1.2B
  - button "Allocate Funds"
  - heading "Compound Lending" [level=3]
  - paragraph: Supply assets to Compound protocol to earn interest and COMP tokens.
  - paragraph: APY
  - paragraph: 3.8%
  - paragraph: Risk
  - paragraph: Low
  - paragraph: TVL
  - paragraph: $890M
  - button "Allocate Funds"
  - heading "Curve Stablecoin LP" [level=3]
  - paragraph: Provide liquidity to Curve stablecoin pools and earn trading fees.
  - paragraph: APY
  - paragraph: 5.1%
  - paragraph: Risk
  - paragraph: Medium
  - paragraph: TVL
  - paragraph: $450M
  - button "Allocate Funds"
  - heading "Uniswap V3 LP" [level=3]
  - paragraph: Provide concentrated liquidity to Uniswap V3 pools.
  - paragraph: APY
  - paragraph: 8.5%
  - paragraph: Risk
  - paragraph: Medium-High
  - paragraph: TVL
  - paragraph: $320M
  - button "Allocate Funds"
  - heading "Lido Staking" [level=3]
  - paragraph: Stake ETH with Lido to earn staking rewards while maintaining liquidity.
  - paragraph: APY
  - paragraph: 3.9%
  - paragraph: Risk
  - paragraph: Low
  - paragraph: TVL
  - paragraph: $2.1B
  - button "Allocate Funds"
  - heading "Yearn Vaults" [level=3]
  - paragraph: Deposit into Yearn vaults for automated yield optimization.
  - paragraph: APY
  - paragraph: 6.7%
  - paragraph: Risk
  - paragraph: Medium
  - paragraph: TVL
  - paragraph: $580M
  - button "Allocate Funds"
- alert
- button "Open Next.js Dev Tools":
  - img
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('Strategies Page', () => {
   4 |   test('should display all strategy cards', async ({ page }) => {
   5 |     // Go to the strategies page
   6 |     await page.goto('/strategies');
   7 |     
   8 |     // Verify the page title
   9 |     await expect(page.getByRole('heading', { name: 'Available Strategies' })).toBeVisible();
  10 |     
  11 |     // Check if the description text is displayed
  12 |     await expect(page.getByText('NapFi AI automatically allocates your funds across these strategies')).toBeVisible();
  13 |     
  14 |     // Check if all strategy cards are displayed
  15 |     await expect(page.getByText('Aave Lending')).toBeVisible();
  16 |     await expect(page.getByText('Compound Lending')).toBeVisible();
  17 |     await expect(page.getByText('Curve Stablecoin LP')).toBeVisible();
  18 |     await expect(page.getByText('Uniswap V3 LP')).toBeVisible();
  19 |     await expect(page.getByText('Lido Staking')).toBeVisible();
  20 |     await expect(page.getByText('Yearn Vaults')).toBeVisible();
  21 |     
  22 |     // Check if strategy metrics are displayed
  23 |     await expect(page.getByText('APY')).toBeVisible();
  24 |     await expect(page.getByText('Risk')).toBeVisible();
  25 |     await expect(page.getByText('TVL')).toBeVisible();
  26 |     
  27 |     // Check specific strategy details
  28 |     const aaveCard = page.getByText('Aave Lending').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
  29 |     await expect(aaveCard.getByText('4.2%')).toBeVisible();
  30 |     await expect(aaveCard.getByText('Low')).toBeVisible();
  31 |     await expect(aaveCard.getByText('$1.2B')).toBeVisible();
  32 |     
  33 |     // Check if all cards have the allocate button
  34 |     const allocateButtons = page.getByRole('button', { name: 'Allocate Funds' });
  35 |     await expect(allocateButtons).toHaveCount(6);
  36 |   });
  37 |   
  38 |   test('should handle button interactions', async ({ page }) => {
  39 |     // Go to the strategies page
  40 |     await page.goto('/strategies');
  41 |     
  42 |     // Get the first allocate button
  43 |     const firstAllocateButton = page.getByRole('button', { name: 'Allocate Funds' }).first();
  44 |     
  45 |     // Verify button hover state
  46 |     await firstAllocateButton.hover();
  47 |     await expect(firstAllocateButton).toHaveClass(/hover:bg-indigo-700/);
  48 |     
  49 |     // Click the button (in a real test, we would verify the action)
  50 |     await firstAllocateButton.click();
  51 |     
  52 |     // Since this is a mock, we just verify the button was clicked
  53 |     // In a real app, we would check for a modal, navigation, or other action
  54 |   });
  55 |   
  56 |   test('should have responsive layout', async ({ page }) => {
  57 |     // Go to the strategies page
  58 |     await page.goto('/strategies');
  59 |     
  60 |     // Test desktop layout
  61 |     await page.setViewportSize({ width: 1280, height: 800 });
  62 |     
  63 |     // Check if the grid has desktop layout classes
  64 |     const gridLayout = page.locator('.grid').last();
> 65 |     await expect(gridLayout).toHaveClass(/lg:grid-cols-3/);
     |                              ^ Error: Timed out 5000ms waiting for expect(locator).toHaveClass(expected)
  66 |     await expect(gridLayout).toHaveClass(/md:grid-cols-2/);
  67 |     
  68 |     // Test tablet layout
  69 |     await page.setViewportSize({ width: 768, height: 1024 });
  70 |     
  71 |     // Check if the layout adjusts for tablet
  72 |     await expect(gridLayout).toHaveClass(/md:grid-cols-2/);
  73 |     await expect(gridLayout).not.toHaveClass(/lg:grid-cols-3/);
  74 |     
  75 |     // Test mobile layout
  76 |     await page.setViewportSize({ width: 375, height: 667 });
  77 |     
  78 |     // Check if the layout adjusts for mobile
  79 |     await expect(gridLayout).toHaveClass(/grid-cols-1/);
  80 |     
  81 |     // Restore desktop view for other tests
  82 |     await page.setViewportSize({ width: 1280, height: 800 });
  83 |   });
  84 | });
  85 |
```