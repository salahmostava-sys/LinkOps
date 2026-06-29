import { test, expect } from '@playwright/test';

test.describe('Auth Flow', () => {
  test('login with valid credentials', async ({ page }) => {
    await page.goto('https://muhimat.vercel.app/login');
    await page.fill('input[name="email"]', 'admin@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/dashboard/);
  });
});
