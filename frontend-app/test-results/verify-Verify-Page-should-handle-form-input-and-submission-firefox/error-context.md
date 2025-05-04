# Test info

- Name: Verify Page >> should handle form input and submission
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/verify.spec.ts:24:7

# Error details

```
Error: locator.click: Test timeout of 30000ms exceeded.
Call log:
  - waiting for getByRole('button', { name: 'Verify Decision' })

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/verify.spec.ts:33:65
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
  - heading "MCP Decision Verification" [level=1]
  - paragraph: Verify the authenticity of AI-driven allocation decisions using the Model Context Protocol.
  - heading "Verify Decision Authenticity" [level=3]
  - paragraph: Verify that this decision was made by NapFi AI and has not been tampered with.
  - paragraph: "Decision ID:"
  - paragraph: "0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234"
  - paragraph: "Signature:"
  - paragraph: "0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef"
  - button "Verify Signature"
  - heading "About MCP Verification" [level=2]
  - paragraph: The Model Context Protocol (MCP) ensures transparency and verifiability in AI-driven decision making. Each allocation decision made by NapFi AI is recorded on-chain with a cryptographic signature that can be verified to ensure the decision was made by the authorized AI system and has not been tampered with.
  - paragraph: By verifying decisions, users can trust that their funds are being allocated based on legitimate AI recommendations and not manipulated by malicious actors.
- alert
- button "Open Next.js Dev Tools":
  - img
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('Verify Page', () => {
   4 |   test('should display verification form when no params are provided', async ({ page }) => {
   5 |     // Go to the verify page
   6 |     await page.goto('/verify');
   7 |     
   8 |     // Verify the page title
   9 |     await expect(page.getByRole('heading', { name: 'MCP Decision Verification' })).toBeVisible();
  10 |     
  11 |     // Check if the form is displayed
  12 |     await expect(page.getByRole('heading', { name: 'Verify Decision' })).toBeVisible();
  13 |     
  14 |     // Check if the form fields are displayed
  15 |     await expect(page.getByLabel('Decision ID')).toBeVisible();
  16 |     await expect(page.getByLabel('Signature')).toBeVisible();
  17 |     await expect(page.getByRole('button', { name: 'Verify Decision' })).toBeVisible();
  18 |     
  19 |     // Check if the about section is displayed
  20 |     await expect(page.getByRole('heading', { name: 'About MCP Verification' })).toBeVisible();
  21 |     await expect(page.getByText('The Model Context Protocol (MCP) ensures transparency')).toBeVisible();
  22 |   });
  23 |   
  24 |   test('should handle form input and submission', async ({ page }) => {
  25 |     // Go to the verify page
  26 |     await page.goto('/verify');
  27 |     
  28 |     // Enter values in the form fields
  29 |     await page.getByLabel('Decision ID').fill('0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234');
  30 |     await page.getByLabel('Signature').fill('0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
  31 |     
  32 |     // Click the verify button
> 33 |     await page.getByRole('button', { name: 'Verify Decision' }).click();
     |                                                                 ^ Error: locator.click: Test timeout of 30000ms exceeded.
  34 |     
  35 |     // Check if the URL is updated with the parameters
  36 |     await expect(page.url()).toContain('id=0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234');
  37 |     await expect(page.url()).toContain('signature=0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
  38 |     
  39 |     // Check if the verification component is displayed
  40 |     await expect(page.getByTestId('mcp-verification')).toBeVisible();
  41 |     
  42 |     // Form should no longer be visible
  43 |     await expect(page.getByLabel('Decision ID')).not.toBeVisible();
  44 |     await expect(page.getByLabel('Signature')).not.toBeVisible();
  45 |   });
  46 |   
  47 |   test('should display verification component when params are provided in URL', async ({ page }) => {
  48 |     // Go to the verify page with parameters
  49 |     await page.goto('/verify?id=0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234&signature=0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
  50 |     
  51 |     // Check if the verification component is displayed
  52 |     await expect(page.getByTestId('mcp-verification')).toBeVisible();
  53 |     
  54 |     // Form should not be visible
  55 |     await expect(page.getByLabel('Decision ID')).not.toBeVisible();
  56 |     await expect(page.getByLabel('Signature')).not.toBeVisible();
  57 |     
  58 |     // About section should still be visible
  59 |     await expect(page.getByRole('heading', { name: 'About MCP Verification' })).toBeVisible();
  60 |   });
  61 |   
  62 |   test('should validate form input', async ({ page }) => {
  63 |     // Go to the verify page
  64 |     await page.goto('/verify');
  65 |     
  66 |     // Try to submit the form without entering values
  67 |     await page.getByRole('button', { name: 'Verify Decision' }).click();
  68 |     
  69 |     // URL should not be updated
  70 |     await expect(page.url()).not.toContain('id=');
  71 |     await expect(page.url()).not.toContain('signature=');
  72 |     
  73 |     // Form should still be visible
  74 |     await expect(page.getByLabel('Decision ID')).toBeVisible();
  75 |     await expect(page.getByLabel('Signature')).toBeVisible();
  76 |     
  77 |     // Enter only decision ID
  78 |     await page.getByLabel('Decision ID').fill('0x123456789abcdef');
  79 |     await page.getByRole('button', { name: 'Verify Decision' }).click();
  80 |     
  81 |     // URL should not be updated
  82 |     await expect(page.url()).not.toContain('id=');
  83 |     
  84 |     // Enter only signature
  85 |     await page.getByLabel('Decision ID').clear();
  86 |     await page.getByLabel('Signature').fill('0xabcdef123456789');
  87 |     await page.getByRole('button', { name: 'Verify Decision' }).click();
  88 |     
  89 |     // URL should not be updated
  90 |     await expect(page.url()).not.toContain('signature=');
  91 |   });
  92 | });
  93 |
```