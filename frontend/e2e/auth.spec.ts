import { expect, test } from '@playwright/test';

test.describe('حماية المسارات', () => {
  test('تعيد المستخدم غير المسجل إلى صفحة الدخول', async ({ page }) => {
    await page.goto('/employees');

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.locator('#login-email')).toBeVisible();
  });
});
