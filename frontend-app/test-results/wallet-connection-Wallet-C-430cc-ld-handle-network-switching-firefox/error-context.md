# Test info

- Name: Wallet Connection >> should handle network switching
- Location: /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/wallet-connection.spec.ts:132:7

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: getByText('Goerli')
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for getByText('Goerli')

    at /home/mamenesia/Repository/Web3/napfi_ai/frontend-app/e2e/wallet-connection.spec.ts:162:44
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
   78 |   test('should handle wallet connection flow', async ({ page }) => {
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
> 162 |     await expect(page.getByText('Goerli')).toBeVisible();
      |                                            ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
  163 |   });
  164 | });
  165 |
```