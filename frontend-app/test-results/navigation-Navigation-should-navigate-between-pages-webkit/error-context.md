# Test info

- Name: Navigation >> should navigate between pages
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/navigation.spec.ts:4:7

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
   3 | test.describe('Navigation', () => {
>  4 |   test('should navigate between pages', async ({ page }) => {
     |       ^ Error: browserType.launch: 
   5 |     // Start at the home page
   6 |     await page.goto('/');
   7 |     
   8 |     // Verify we're on the home page
   9 |     await expect(page).toHaveTitle(/NapFi AI/);
  10 |     await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
  11 |     
  12 |     // Navigate to the decisions page
  13 |     await page.getByRole('link', { name: 'Decisions' }).click();
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