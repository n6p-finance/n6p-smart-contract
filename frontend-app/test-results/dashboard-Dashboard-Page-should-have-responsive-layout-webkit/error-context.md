# Test info

- Name: Dashboard Page >> should have responsive layout
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/dashboard.spec.ts:48:7

# Error details

```
Error: browserType.launch: 
╔══════════════════════════════════════════════════════╗
║ Host system is missing dependencies to run browsers. ║
║ Missing libraries:                                   ║
║     libgtk-4.so.1                                    ║
║     libgraphene-1.0.so.0                             ║
║     libatomic.so.1                                   ║
║     libxslt.so.1                                     ║
║     libwoff2dec.so.1.0.2                             ║
║     libvpx.so.9                                      ║
║     libevent-2.1.so.7                                ║
║     libopus.so.0                                     ║
║     libgstallocators-1.0.so.0                        ║
║     libgstapp-1.0.so.0                               ║
║     libgstpbutils-1.0.so.0                           ║
║     libgstaudio-1.0.so.0                             ║
║     libgsttag-1.0.so.0                               ║
║     libgstvideo-1.0.so.0                             ║
║     libgstgl-1.0.so.0                                ║
║     libgstcodecparsers-1.0.so.0                      ║
║     libgstfft-1.0.so.0                               ║
║     libflite.so.1                                    ║
║     libflite_usenglish.so.1                          ║
║     libflite_cmu_grapheme_lang.so.1                  ║
║     libflite_cmu_grapheme_lex.so.1                   ║
║     libflite_cmu_indic_lang.so.1                     ║
║     libflite_cmu_indic_lex.so.1                      ║
║     libflite_cmulex.so.1                             ║
║     libflite_cmu_time_awb.so.1                       ║
║     libflite_cmu_us_awb.so.1                         ║
║     libflite_cmu_us_kal16.so.1                       ║
║     libflite_cmu_us_kal.so.1                         ║
║     libflite_cmu_us_rms.so.1                         ║
║     libflite_cmu_us_slt.so.1                         ║
║     libwebpdemux.so.2                                ║
║     libavif.so.16                                    ║
║     libharfbuzz-icu.so.0                             ║
║     libwebpmux.so.3                                  ║
║     libenchant-2.so.2                                ║
║     libsecret-1.so.0                                 ║
║     libhyphen.so.0                                   ║
║     libmanette-0.2.so.0                              ║
║     libGLESv2.so.2                                   ║
║     libx264.so                                       ║
╚══════════════════════════════════════════════════════╝
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
> 48 |   test('should have responsive layout', async ({ page }) => {
     |       ^ Error: browserType.launch: 
  49 |     // Go to the dashboard page
  50 |     await page.goto('/');
  51 |     
  52 |     // Test desktop layout
  53 |     await page.setViewportSize({ width: 1280, height: 800 });
  54 |     
  55 |     // Check if the grid has desktop layout classes
  56 |     const gridLayout = page.locator('.grid');
  57 |     await expect(gridLayout).toHaveClass(/lg:grid-cols-2/);
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