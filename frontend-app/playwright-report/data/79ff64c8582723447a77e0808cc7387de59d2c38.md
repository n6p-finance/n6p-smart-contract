# Test info

- Name: Decisions Page >> should handle URL parameters for decision selection
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/decisions.spec.ts:38:7

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: getByTestId('mcp-decision-card')
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for getByTestId('mcp-decision-card')

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/decisions.spec.ts:48:32
```

# Page snapshot

```yaml
- navigation:
  - link "NapFi AI":
    - /url: /
  - button "Open main menu"
- main:
  - heading "AI Decision History" [level=1]
  - paragraph: View the history of allocation decisions made by NapFi AI and understand the reasoning behind each decision.
  - heading "Decision History" [level=3]
  - list:
    - listitem:
      - button "May 1, 2025 Initial allocation"
    - listitem:
      - button "May 15, 2025 Rebalance due to market change"
    - listitem:
      - button "June 1, 2025 Added new strategy"
  - heading "AI Decision Reasoning" [level=3]
  - paragraph: Loading decision data...
  - heading "Verify Decision Authenticity" [level=3]
  - paragraph: Verify that this decision was made by NapFi AI and has not been tampered with.
  - paragraph: "Decision ID:"
  - paragraph: "0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345"
  - paragraph: "Signature:"
  - paragraph: "0xbcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
  - button "Verify Signature"
- alert
- button "Open Next.js Dev Tools":
  - img
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('Decisions Page', () => {
   4 |   test('should display decision history and allow selection', async ({ page }) => {
   5 |     // Go to the decisions page
   6 |     await page.goto('/decisions');
   7 |     
   8 |     // Verify the page title
   9 |     await expect(page.getByRole('heading', { name: 'AI Decision History' })).toBeVisible();
  10 |     
  11 |     // Check if the decision history list is visible
  12 |     await expect(page.getByRole('heading', { name: 'Decision History' })).toBeVisible();
  13 |     
  14 |     // Check if the initial decisions are listed
  15 |     await expect(page.getByText('Initial allocation')).toBeVisible();
  16 |     await expect(page.getByText('Rebalance due to market change')).toBeVisible();
  17 |     await expect(page.getByText('Added new strategy')).toBeVisible();
  18 |     
  19 |     // By default, the first decision should be selected
  20 |     const firstDecision = page.getByText('Initial allocation').locator('xpath=ancestor::button');
  21 |     await expect(firstDecision).toHaveClass(/bg-blue-50/);
  22 |     
  23 |     // Select the second decision
  24 |     await page.getByText('Rebalance due to market change').click();
  25 |     
  26 |     // Verify the second decision is now selected
  27 |     const secondDecision = page.getByText('Rebalance due to market change').locator('xpath=ancestor::button');
  28 |     await expect(secondDecision).toHaveClass(/bg-blue-50/);
  29 |     
  30 |     // Verify the first decision is no longer selected
  31 |     await expect(firstDecision).not.toHaveClass(/bg-blue-50/);
  32 |     
  33 |     // Verify the MCP components are displayed
  34 |     await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
  35 |     await expect(page.getByTestId('mcp-verification')).toBeVisible();
  36 |   });
  37 |   
  38 |   test('should handle URL parameters for decision selection', async ({ page }) => {
  39 |     // Go to the decisions page with a specific decision ID
  40 |     await page.goto('/decisions?id=0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345');
  41 |     
  42 |     // Verify the second decision is selected
  43 |     const secondDecision = page.getByText('Rebalance due to market change').locator('xpath=ancestor::button');
  44 |     await expect(secondDecision).toHaveClass(/bg-blue-50/);
  45 |     
  46 |     // Verify the MCP decision card shows the correct decision
  47 |     const decisionCard = page.getByTestId('mcp-decision-card');
> 48 |     await expect(decisionCard).toBeVisible();
     |                                ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
  49 |     
  50 |     // Verify the MCP verification component is displayed
  51 |     await expect(page.getByTestId('mcp-verification')).toBeVisible();
  52 |   });
  53 |   
  54 |   test('should have responsive layout', async ({ page }) => {
  55 |     // Go to the decisions page
  56 |     await page.goto('/decisions');
  57 |     
  58 |     // Test desktop layout
  59 |     await page.setViewportSize({ width: 1280, height: 800 });
  60 |     
  61 |     // Check if the grid has desktop layout classes
  62 |     const gridLayout = page.locator('.grid');
  63 |     await expect(gridLayout).toHaveClass(/lg:grid-cols-3/);
  64 |     
  65 |     // Check if the decision list has the correct column span
  66 |     const decisionList = page.getByText('Decision History').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
  67 |     const decisionListParent = decisionList.locator('xpath=ancestor::div[contains(@class, "lg:col-span-1")]');
  68 |     await expect(decisionListParent).toBeVisible();
  69 |     
  70 |     // Check if the decision details section has the correct column span
  71 |     const decisionDetails = page.getByTestId('mcp-decision-card').locator('xpath=ancestor::div[contains(@class, "lg:col-span-2")]');
  72 |     await expect(decisionDetails).toBeVisible();
  73 |     
  74 |     // Test mobile layout
  75 |     await page.setViewportSize({ width: 375, height: 667 });
  76 |     
  77 |     // Check if the layout adjusts for mobile
  78 |     await expect(gridLayout).toHaveClass(/grid-cols-1/);
  79 |     
  80 |     // Restore desktop view for other tests
  81 |     await page.setViewportSize({ width: 1280, height: 800 });
  82 |   });
  83 | });
  84 |
```