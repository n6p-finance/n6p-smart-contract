import { test, expect } from '@playwright/test';

// Mock wallet connection for testing
test.beforeEach(async ({ page }) => {
  // Intercept wallet connection requests
  await page.route('**/api/wallet/**', async (route) => {
    // Mock successful wallet connection
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        connected: true,
        address: '0x1234567890123456789012345678901234567890',
        chainId: 1,
      }),
    });
  });

  // Inject mock wallet object
  await page.addInitScript(() => {
    window.ethereum = {
      isMetaMask: true,
      request: async ({ method }: { method: string }) => {
        if (method === 'eth_requestAccounts') {
          return ['0x1234567890123456789012345678901234567890'];
        }
        if (method === 'eth_chainId') {
          return '0x1'; // Ethereum Mainnet
        }
        return null;
      },
      on: () => {},
      removeListener: () => {},
    };
  });
});

test.describe('Wallet Connection', () => {
  test('should show connect wallet button when not connected', async ({ page }) => {
    // Override the default mock to simulate disconnected state
    await page.route('**/api/wallet/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          connected: false,
          address: null,
          chainId: null,
        }),
      });
    });

    // Go to the dashboard page
    await page.goto('/');
    
    // Check if the connect wallet button is visible
    const connectButton = page.getByRole('button', { name: /Connect Wallet/i });
    await expect(connectButton).toBeVisible();
    
    // Check if the dashboard shows the not connected state
    await expect(page.getByText('Connect your wallet to view AI allocation decisions')).toBeVisible();
  });
  
  test('should display wallet address when connected', async ({ page }) => {
    // Go to the dashboard page with mocked connected wallet
    await page.goto('/');
    
    // Wait for the wallet connection to be processed
    await page.waitForTimeout(1000);
    
    // Check if the wallet address is displayed
    await expect(page.getByText(/0x1234/)).toBeVisible();
    
    // Check if the dashboard shows the connected state
    await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
  });
  
  test('should handle wallet connection flow', async ({ page }) => {
    // Start with disconnected state
    await page.route('**/api/wallet/**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          connected: false,
          address: null,
          chainId: null,
        }),
      });
    });
    
    // Go to the dashboard page
    await page.goto('/');
    
    // Check if the connect button is visible
    const connectButton = page.getByRole('button', { name: /Connect Wallet/i });
    await expect(connectButton).toBeVisible();
    
    // Set up a route to handle the connection request
    await page.route('**/api/wallet/connect', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          connected: true,
          address: '0x1234567890123456789012345678901234567890',
          chainId: 1,
        }),
      });
    });
    
    // Click the connect button
    await connectButton.click();
    
    // Wait for the connection dialog
    const walletOptions = page.getByText('Connect a Wallet');
    if (await walletOptions.isVisible()) {
      // Select MetaMask
      await page.getByText('MetaMask').click();
    }
    
    // Wait for the connection to be processed
    await page.waitForTimeout(1000);
    
    // Check if the wallet address is displayed after connection
    await expect(page.getByText(/0x1234/)).toBeVisible();
    
    // Check if the dashboard shows the connected state
    await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
  });
  
  test('should handle network switching', async ({ page }) => {
    // Go to the dashboard page with mocked connected wallet
    await page.goto('/');
    
    // Wait for the wallet connection to be processed
    await page.waitForTimeout(1000);
    
    // Mock a network switch event
    await page.evaluate(() => {
      // Simulate chainChanged event
      window.dispatchEvent(new CustomEvent('chainChanged', { detail: '0x5' })); // Goerli testnet
    });
    
    // Set up a route to handle the network switch
    await page.route('**/api/wallet/network', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          connected: true,
          address: '0x1234567890123456789012345678901234567890',
          chainId: 5, // Goerli testnet
        }),
      });
    });
    
    // Wait for the network switch to be processed
    await page.waitForTimeout(1000);
    
    // Check if the network name is displayed
    await expect(page.getByText('Goerli')).toBeVisible();
  });
});
