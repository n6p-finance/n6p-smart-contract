import { test, expect } from '@playwright/test';

test.describe('Decisions Page', () => {
  test('should display decision history and allow selection', async ({ page }) => {
    // Go to the decisions page
    await page.goto('/decisions');
    
    // Verify the page title
    await expect(page.getByRole('heading', { name: 'AI Decision History' })).toBeVisible();
    
    // Check if the decision history list is visible
    await expect(page.getByRole('heading', { name: 'Decision History' })).toBeVisible();
    
    // Check if the initial decisions are listed
    await expect(page.getByText('Initial allocation')).toBeVisible();
    await expect(page.getByText('Rebalance due to market change')).toBeVisible();
    await expect(page.getByText('Added new strategy')).toBeVisible();
    
    // By default, the first decision should be selected
    const firstDecision = page.getByText('Initial allocation').locator('xpath=ancestor::button');
    await expect(firstDecision).toHaveClass(/bg-blue-50/);
    
    // Select the second decision
    await page.getByText('Rebalance due to market change').click();
    
    // Verify the second decision is now selected
    const secondDecision = page.getByText('Rebalance due to market change').locator('xpath=ancestor::button');
    await expect(secondDecision).toHaveClass(/bg-blue-50/);
    
    // Verify the first decision is no longer selected
    await expect(firstDecision).not.toHaveClass(/bg-blue-50/);
    
    // Verify the MCP components are displayed
    await expect(page.getByTestId('mcp-decision-card')).toBeVisible();
    await expect(page.getByTestId('mcp-verification')).toBeVisible();
  });
  
  test('should handle URL parameters for decision selection', async ({ page }) => {
    // Go to the decisions page with a specific decision ID
    await page.goto('/decisions?id=0x234567890abcdef234567890abcdef234567890abcdef234567890abcdef2345');
    
    // Verify the second decision is selected
    const secondDecision = page.getByText('Rebalance due to market change').locator('xpath=ancestor::button');
    await expect(secondDecision).toHaveClass(/bg-blue-50/);
    
    // Verify the MCP decision card shows the correct decision
    const decisionCard = page.getByTestId('mcp-decision-card');
    await expect(decisionCard).toBeVisible();
    
    // Verify the MCP verification component is displayed
    await expect(page.getByTestId('mcp-verification')).toBeVisible();
  });
  
  test('should have responsive layout', async ({ page }) => {
    // Go to the decisions page
    await page.goto('/decisions');
    
    // Test desktop layout
    await page.setViewportSize({ width: 1280, height: 800 });
    
    // Check if the grid has desktop layout classes
    const gridLayout = page.locator('.grid');
    await expect(gridLayout).toHaveClass(/lg:grid-cols-3/);
    
    // Check if the decision list has the correct column span
    const decisionList = page.getByText('Decision History').locator('xpath=ancestor::div[contains(@class, "bg-white")]');
    const decisionListParent = decisionList.locator('xpath=ancestor::div[contains(@class, "lg:col-span-1")]');
    await expect(decisionListParent).toBeVisible();
    
    // Check if the decision details section has the correct column span
    const decisionDetails = page.getByTestId('mcp-decision-card').locator('xpath=ancestor::div[contains(@class, "lg:col-span-2")]');
    await expect(decisionDetails).toBeVisible();
    
    // Test mobile layout
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check if the layout adjusts for mobile
    await expect(gridLayout).toHaveClass(/grid-cols-1/);
    
    // Restore desktop view for other tests
    await page.setViewportSize({ width: 1280, height: 800 });
  });
});
