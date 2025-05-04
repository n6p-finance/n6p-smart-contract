import { test, expect } from '@playwright/test';

test.describe('Dashboard Page', () => {
  test('should display dashboard components correctly', async ({ page }) => {
    // Go to the dashboard page
    await page.goto('/');
    
    // Verify the page title
    await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
    
    // Check for loading state initially
    const loadingSpinner = page.getByTestId('loading-spinner');
    if (await loadingSpinner.isVisible()) {
      // Wait for loading to complete
      await expect(loadingSpinner).not.toBeVisible({ timeout: 10000 });
    }
    
    // Verify portfolio section is visible after loading
    await expect(page.getByText('Your Portfolio')).toBeVisible();
    await expect(page.getByText('Total Value')).toBeVisible();
    await expect(page.getByText('Current APY')).toBeVisible();
    await expect(page.getByText('Risk Score')).toBeVisible();
    
    // Verify allocation chart is visible
    await expect(page.getByText('Current Allocation')).toBeVisible();
    
    // Verify decision history section
    await expect(page.getByText('Decision History')).toBeVisible();
  });
  
  test('should handle wallet connection state', async ({ page }) => {
    // Go to the dashboard page
    await page.goto('/');
    
    // Check if the wallet connection status is displayed
    const walletStatus = page.locator('.bg-gray-100.px-4.py-2.rounded-full');
    await expect(walletStatus).toBeVisible();
    
    // Note: In a real test, we would mock the wallet connection
    // For now, we'll just verify the UI elements are present
    
    // Check if the latest AI decision section displays appropriate content
    // This could be either the decision card or a message to connect wallet
    const latestDecisionSection = page.getByText('Latest AI Decision').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
    await expect(latestDecisionSection).toBeVisible();
  });
  
  test('should have responsive layout', async ({ page }) => {
    // Go to the dashboard page
    await page.goto('/');
    
    // Test desktop layout
    await page.setViewportSize({ width: 1280, height: 800 });
    
    // Check if the grid has desktop layout classes
    const gridLayout = page.locator('.grid');
    await expect(gridLayout).toHaveClass(/lg:grid-cols-2/);
    
    // Test mobile layout
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check if the cards stack vertically on mobile
    await expect(gridLayout).toHaveClass(/grid-cols-1/);
    
    // Restore desktop view for other tests
    await page.setViewportSize({ width: 1280, height: 800 });
  });
});
