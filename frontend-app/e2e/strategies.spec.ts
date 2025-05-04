import { test, expect } from '@playwright/test';

test.describe('Strategies Page', () => {
  test('should display all strategy cards', async ({ page }) => {
    // Go to the strategies page
    await page.goto('/strategies');
    
    // Verify the page title
    await expect(page.getByRole('heading', { name: 'Available Strategies' })).toBeVisible();
    
    // Check if the description text is displayed
    await expect(page.getByText('NapFi AI automatically allocates your funds across these strategies')).toBeVisible();
    
    // Check if all strategy cards are displayed
    await expect(page.getByText('Aave Lending')).toBeVisible();
    await expect(page.getByText('Compound Lending')).toBeVisible();
    await expect(page.getByText('Curve Stablecoin LP')).toBeVisible();
    await expect(page.getByText('Uniswap V3 LP')).toBeVisible();
    await expect(page.getByText('Lido Staking')).toBeVisible();
    await expect(page.getByText('Yearn Vaults')).toBeVisible();
    
    // Check if strategy metrics are displayed
    await expect(page.getByText('APY')).toBeVisible();
    await expect(page.getByText('Risk')).toBeVisible();
    await expect(page.getByText('TVL')).toBeVisible();
    
    // Check specific strategy details
    const aaveCard = page.getByText('Aave Lending').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
    await expect(aaveCard.getByText('4.2%')).toBeVisible();
    await expect(aaveCard.getByText('Low')).toBeVisible();
    await expect(aaveCard.getByText('$1.2B')).toBeVisible();
    
    // Check if all cards have the allocate button
    const allocateButtons = page.getByRole('button', { name: 'Allocate Funds' });
    await expect(allocateButtons).toHaveCount(6);
  });
  
  test('should handle button interactions', async ({ page }) => {
    // Go to the strategies page
    await page.goto('/strategies');
    
    // Get the first allocate button
    const firstAllocateButton = page.getByRole('button', { name: 'Allocate Funds' }).first();
    
    // Verify button hover state
    await firstAllocateButton.hover();
    await expect(firstAllocateButton).toHaveClass(/hover:bg-indigo-700/);
    
    // Click the button (in a real test, we would verify the action)
    await firstAllocateButton.click();
    
    // Since this is a mock, we just verify the button was clicked
    // In a real app, we would check for a modal, navigation, or other action
  });
  
  test('should have responsive layout', async ({ page }) => {
    // Go to the strategies page
    await page.goto('/strategies');
    
    // Test desktop layout
    await page.setViewportSize({ width: 1280, height: 800 });
    
    // Check if the grid has desktop layout classes
    const gridLayout = page.locator('.grid').last();
    await expect(gridLayout).toHaveClass(/lg:grid-cols-3/);
    await expect(gridLayout).toHaveClass(/md:grid-cols-2/);
    
    // Test tablet layout
    await page.setViewportSize({ width: 768, height: 1024 });
    
    // Check if the layout adjusts for tablet
    await expect(gridLayout).toHaveClass(/md:grid-cols-2/);
    await expect(gridLayout).not.toHaveClass(/lg:grid-cols-3/);
    
    // Test mobile layout
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check if the layout adjusts for mobile
    await expect(gridLayout).toHaveClass(/grid-cols-1/);
    
    // Restore desktop view for other tests
    await page.setViewportSize({ width: 1280, height: 800 });
  });
});
