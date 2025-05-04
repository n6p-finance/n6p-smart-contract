# Test info

- Name: Wallet Connection >> should handle wallet connection flow
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/wallet-connection.spec.ts:78:7

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
   3 | // Mock wallet connection for testing
   4 | test.beforeEach(async ({ page }) => {
   5 |   // Intercept wallet connection requests
   6 |   await page.route('**/api/wallet/**', async (route) => {
   7 |     // Mock successful wallet connection
   8 |     await route.fulfill({
   9 |       status: 200,
   10 |       contentType: 'application/json',
   11 |       body: JSON.stringify({
   12 |         connected: true,
   13 |         address: '0x1234567890123456789012345678901234567890',
   14 |         chainId: 1,
   15 |       }),
   16 |     });
   17 |   });
   18 |
   19 |   // Inject mock wallet object
   20 |   await page.addInitScript(() => {
   21 |     window.ethereum = {
   22 |       isMetaMask: true,
   23 |       request: async ({ method }: { method: string }) => {
   24 |         if (method === 'eth_requestAccounts') {
   25 |           return ['0x1234567890123456789012345678901234567890'];
   26 |         }
   27 |         if (method === 'eth_chainId') {
   28 |           return '0x1'; // Ethereum Mainnet
   29 |         }
   30 |         return null;
   31 |       },
   32 |       on: () => {},
   33 |       removeListener: () => {},
   34 |     };
   35 |   });
   36 | });
   37 |
   38 | test.describe('Wallet Connection', () => {
   39 |   test('should show connect wallet button when not connected', async ({ page }) => {
   40 |     // Override the default mock to simulate disconnected state
   41 |     await page.route('**/api/wallet/**', async (route) => {
   42 |       await route.fulfill({
   43 |         status: 200,
   44 |         contentType: 'application/json',
   45 |         body: JSON.stringify({
   46 |           connected: false,
   47 |           address: null,
   48 |           chainId: null,
   49 |         }),
   50 |       });
   51 |     });
   52 |
   53 |     // Go to the dashboard page
   54 |     await page.goto('/');
   55 |     
   56 |     // Check if the connect wallet button is visible
   57 |     const connectButton = page.getByRole('button', { name: /Connect Wallet/i });
   58 |     await expect(connectButton).toBeVisible();
   59 |     
   60 |     // Check if the dashboard shows the not connected state
   61 |     await expect(page.getByText('Connect your wallet to view AI allocation decisions')).toBeVisible();
   62 |   });
   63 |   
   64 |   test('should display wallet address when connected', async ({ page }) => {
   65 |     // Go to the dashboard page with mocked connected wallet
   66 |     await page.goto('/');
   67 |     
   68 |     // Wait for the wallet connection to be processed
   69 |     await page.waitForTimeout(1000);
   70 |     
   71 |     // Check if the wallet address is displayed
   72 |     await expect(page.getByText(/0x1234/)).toBeVisible();
   73 |     
   74 |     // Check if the dashboard shows the connected state
   75 |     await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
   76 |   });
   77 |   
>  78 |   test('should handle wallet connection flow', async ({ page }) => {
      |       ^ Error: browserType.launch: 
   79 |     // Start with disconnected state
   80 |     await page.route('**/api/wallet/**', async (route) => {
   81 |       await route.fulfill({
   82 |         status: 200,
   83 |         contentType: 'application/json',
   84 |         body: JSON.stringify({
   85 |           connected: false,
   86 |           address: null,
   87 |           chainId: null,
   88 |         }),
   89 |       });
   90 |     });
   91 |     
   92 |     // Go to the dashboard page
   93 |     await page.goto('/');
   94 |     
   95 |     // Check if the connect button is visible
   96 |     const connectButton = page.getByRole('button', { name: /Connect Wallet/i });
   97 |     await expect(connectButton).toBeVisible();
   98 |     
   99 |     // Set up a route to handle the connection request
  100 |     await page.route('**/api/wallet/connect', async (route) => {
  101 |       await route.fulfill({
  102 |         status: 200,
  103 |         contentType: 'application/json',
  104 |         body: JSON.stringify({
  105 |           connected: true,
  106 |           address: '0x1234567890123456789012345678901234567890',
  107 |           chainId: 1,
  108 |         }),
  109 |       });
  110 |     });
  111 |     
  112 |     // Click the connect button
  113 |     await connectButton.click();
  114 |     
  115 |     // Wait for the connection dialog
  116 |     const walletOptions = page.getByText('Connect a Wallet');
  117 |     if (await walletOptions.isVisible()) {
  118 |       // Select MetaMask
  119 |       await page.getByText('MetaMask').click();
  120 |     }
  121 |     
  122 |     // Wait for the connection to be processed
  123 |     await page.waitForTimeout(1000);
  124 |     
  125 |     // Check if the wallet address is displayed after connection
  126 |     await expect(page.getByText(/0x1234/)).toBeVisible();
  127 |     
  128 |     // Check if the dashboard shows the connected state
  129 |     await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
  130 |   });
  131 |   
  132 |   test('should handle network switching', async ({ page }) => {
  133 |     // Go to the dashboard page with mocked connected wallet
  134 |     await page.goto('/');
  135 |     
  136 |     // Wait for the wallet connection to be processed
  137 |     await page.waitForTimeout(1000);
  138 |     
  139 |     // Mock a network switch event
  140 |     await page.evaluate(() => {
  141 |       // Simulate chainChanged event
  142 |       window.dispatchEvent(new CustomEvent('chainChanged', { detail: '0x5' })); // Goerli testnet
  143 |     });
  144 |     
  145 |     // Set up a route to handle the network switch
  146 |     await page.route('**/api/wallet/network', async (route) => {
  147 |       await route.fulfill({
  148 |         status: 200,
  149 |         contentType: 'application/json',
  150 |         body: JSON.stringify({
  151 |           connected: true,
  152 |           address: '0x1234567890123456789012345678901234567890',
  153 |           chainId: 5, // Goerli testnet
  154 |         }),
  155 |       });
  156 |     });
  157 |     
  158 |     // Wait for the network switch to be processed
  159 |     await page.waitForTimeout(1000);
  160 |     
  161 |     // Check if the network name is displayed
  162 |     await expect(page.getByText('Goerli')).toBeVisible();
  163 |   });
  164 | });
  165 |
```