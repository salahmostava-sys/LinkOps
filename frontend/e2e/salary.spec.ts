import { test, expect } from '@playwright/test';

test.describe('Salary Flow', () => {
  test('calculate salary for employee', async ({ page }) => {
    await page.goto('https://muhimat.vercel.app/salary');
    await page.click('button:has-text("Calculate")');
    await expect(page.locator('.salary-result')).toBeVisible();
  });
});
