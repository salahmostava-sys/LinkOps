import { test as setup, expect } from '@playwright/test';
import path from 'node:path';

import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('authenticate', async ({ page }) => {
  const email = process.env.E2E_DASHBOARD_EMAIL;
  const password = process.env.E2E_DASHBOARD_PASSWORD;

  if (!email || !password) {
    console.warn('Skipping auth setup: E2E_DASHBOARD_EMAIL or E2E_DASHBOARD_PASSWORD is not set.');
    // Save empty state to avoid errors in dependent tests that might gracefully skip
    await page.context().storageState({ path: authFile });
    return;
  }

  await page.goto('/login');
  
  await page.locator('#login-email').fill(email);
  await page.locator('#login-password').fill(password);
  await page.getByRole('button', { name: 'تسجيل الدخول' }).click();

  // Wait until the URL changes to the dashboard or an expected logged-in state
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole('heading', { name: 'لوحة التحكم' })).toBeVisible();

  // End of authentication steps.
  await page.context().storageState({ path: authFile });
});
