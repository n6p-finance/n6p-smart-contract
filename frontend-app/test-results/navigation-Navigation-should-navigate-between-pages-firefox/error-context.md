# Test info

- Name: Navigation >> should navigate between pages
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/navigation.spec.ts:4:7

# Error details

```
Error: expect(received).toContain(expected) // indexOf

Expected substring: "/decisions"
Received string:    "http://localhost:3000/"
    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/navigation.spec.ts:14:30
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
  - paragraph: "0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234"
  - paragraph: "Signature:"
  - paragraph: "0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef"
  - button "Verify Signature"
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
  13 |     await page.getByRole('link', { name: 'Decisions' }).click();
> 14 |     await expect(page.url()).toContain('/decisions');
     |                              ^ Error: expect(received).toContain(expected) // indexOf
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