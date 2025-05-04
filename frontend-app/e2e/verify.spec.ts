import { test, expect } from '@playwright/test';

test.describe('Verify Page', () => {
  test('should display verification form when no params are provided', async ({ page }) => {
    // Go to the verify page
    await page.goto('/verify');
    
    // Verify the page title
    await expect(page.getByRole('heading', { name: 'MCP Decision Verification' })).toBeVisible();
    
    // Check if the form is displayed
    await expect(page.getByRole('heading', { name: 'Verify Decision' })).toBeVisible();
    
    // Check if the form fields are displayed
    await expect(page.getByLabel('Decision ID')).toBeVisible();
    await expect(page.getByLabel('Signature')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Verify Decision' })).toBeVisible();
    
    // Check if the about section is displayed
    await expect(page.getByRole('heading', { name: 'About MCP Verification' })).toBeVisible();
    await expect(page.getByText('The Model Context Protocol (MCP) ensures transparency')).toBeVisible();
  });
  
  test('should handle form input and submission', async ({ page }) => {
    // Go to the verify page
    await page.goto('/verify');
    
    // Enter values in the form fields
    await page.getByLabel('Decision ID').fill('0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234');
    await page.getByLabel('Signature').fill('0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
    
    // Click the verify button
    await page.getByRole('button', { name: 'Verify Decision' }).click();
    
    // Check if the URL is updated with the parameters
    await expect(page.url()).toContain('id=0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234');
    await expect(page.url()).toContain('signature=0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
    
    // Check if the verification component is displayed
    await expect(page.getByTestId('mcp-verification')).toBeVisible();
    
    // Form should no longer be visible
    await expect(page.getByLabel('Decision ID')).not.toBeVisible();
    await expect(page.getByLabel('Signature')).not.toBeVisible();
  });
  
  test('should display verification component when params are provided in URL', async ({ page }) => {
    // Go to the verify page with parameters
    await page.goto('/verify?id=0x123456789abcdef123456789abcdef123456789abcdef123456789abcdef1234&signature=0xabcdef123456789abcdef123456789abcdef123456789abcdef123456789abcdef');
    
    // Check if the verification component is displayed
    await expect(page.getByTestId('mcp-verification')).toBeVisible();
    
    // Form should not be visible
    await expect(page.getByLabel('Decision ID')).not.toBeVisible();
    await expect(page.getByLabel('Signature')).not.toBeVisible();
    
    // About section should still be visible
    await expect(page.getByRole('heading', { name: 'About MCP Verification' })).toBeVisible();
  });
  
  test('should validate form input', async ({ page }) => {
    // Go to the verify page
    await page.goto('/verify');
    
    // Try to submit the form without entering values
    await page.getByRole('button', { name: 'Verify Decision' }).click();
    
    // URL should not be updated
    await expect(page.url()).not.toContain('id=');
    await expect(page.url()).not.toContain('signature=');
    
    // Form should still be visible
    await expect(page.getByLabel('Decision ID')).toBeVisible();
    await expect(page.getByLabel('Signature')).toBeVisible();
    
    // Enter only decision ID
    await page.getByLabel('Decision ID').fill('0x123456789abcdef');
    await page.getByRole('button', { name: 'Verify Decision' }).click();
    
    // URL should not be updated
    await expect(page.url()).not.toContain('id=');
    
    // Enter only signature
    await page.getByLabel('Decision ID').clear();
    await page.getByLabel('Signature').fill('0xabcdef123456789');
    await page.getByRole('button', { name: 'Verify Decision' }).click();
    
    // URL should not be updated
    await expect(page.url()).not.toContain('signature=');
  });
});
