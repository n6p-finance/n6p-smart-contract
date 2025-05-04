import { test, expect } from '@playwright/test';

test.describe('Navigation', () => {
  test('should navigate between pages', async ({ page }) => {
    // Start at the home page
    await page.goto('/');
    
    // Verify we're on the home page
    await expect(page).toHaveTitle(/NapFi AI/);
    await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
    
    // Navigate to the decisions page
    await page.getByRole('link', { name: 'Decisions' }).click();
    await expect(page.url()).toContain('/decisions');
    await expect(page.getByRole('heading', { name: 'AI Decision History' })).toBeVisible();
    
    // Navigate to the strategies page
    await page.getByRole('link', { name: 'Strategies' }).click();
    await expect(page.url()).toContain('/strategies');
    await expect(page.getByRole('heading', { name: 'Available Strategies' })).toBeVisible();
    
    // Navigate to the verify page
    await page.getByRole('link', { name: 'Verify' }).click();
    await expect(page.url()).toContain('/verify');
    await expect(page.getByRole('heading', { name: 'MCP Decision Verification' })).toBeVisible();
    
    // Navigate back to the home page
    await page.getByRole('link', { name: 'Dashboard' }).click();
    await expect(page.url()).toBe('http://localhost:3000/');
    await expect(page.getByRole('heading', { name: 'NapFi AI Dashboard' })).toBeVisible();
  });
});
