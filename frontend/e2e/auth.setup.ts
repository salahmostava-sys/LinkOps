import { test as setup, expect } from '@playwright/test';
import path from 'node:path';

import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('authenticate', async ({ page }) => {
  const email = process.env.E2E_DASHBOARD_EMAIL;
  const password = process.env.E2E_DASHBOARD_PASSWORD;

  if (!email || !password) {
    const msg = 'E2E_DASHBOARD_EMAIL and E2E_DASHBOARD_PASSWORD must be set for authenticated E2E tests.';
    if (process.env.CI) {
      throw new Error(msg);
    }
    setup.skip(true, msg);
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
