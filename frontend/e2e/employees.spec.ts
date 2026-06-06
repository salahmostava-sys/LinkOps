import { test, expect } from '@playwright/test';

test.describe('صفحة الموظفين (Employees)', () => {
  test('يجب أن تعرض صفحة الموظفين الأساسية والتبويبات', async ({ page }) => {
    // Navigate to employees page
    await page.goto('/employees');

    // Wait for the main heading or breadcrumb to ensure the page loaded
    await expect(page.locator('.page-breadcrumb')).toContainText('الموظفون');

    // Tab buttons should be visible
    const tableTab = page.getByRole('button', { name: /جدول الموظفين/ });
    const kpiTab = page.getByRole('button', { name: /مؤشرات الأداء/ });

    await expect(tableTab).toBeVisible();
    await expect(kpiTab).toBeVisible();

    // The grid/table should be active by default
    await expect(tableTab).toHaveClass(/bg-background/);
    
    // Switch to KPI tab
    await kpiTab.click();
    await expect(kpiTab).toHaveClass(/bg-background/);
  });
});
