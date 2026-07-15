import { describe, expect, it } from 'vitest';

import { ALL_APPS_REPORT_ID, buildDailyAppReportRows } from './dailyAppReportModel';

describe('buildDailyAppReportRows', () => {
  it('aggregates all platforms and calculates target progress from elapsed days', () => {
    const rows = buildDailyAppReportRows({
      employees: [{ id: 'emp-1', name: 'أحمد', salary_type: 'monthly', status: 'active', sponsorship_status: null }],
      apps: [
        { id: 'keeta', name: 'كيتا', name_en: 'Keeta' },
        { id: 'hunger', name: 'هنقر', name_en: 'Hunger' },
      ],
      selectedAppId: ALL_APPS_REPORT_ID,
      data: {
        'emp-1::keeta::1': 10,
        'emp-1::hunger::1': 5,
        'emp-1::keeta::2': 10,
        'emp-1::hunger::2': 5,
      },
      targets: [
        { app_id: 'keeta', target_orders: 1000, employee_target_orders: 70 },
        { app_id: 'hunger', target_orders: 500, employee_target_orders: 50 },
      ],
      year: 2026,
      month: 7,
      startDay: 1,
      endDay: 4,
      today: new Date(2026, 6, 2),
    });

    expect(rows[0]).toMatchObject({
      total: 30,
      employeeTarget: 120,
      remaining: 90,
      achievementPercentage: 25,
      projectedTotal: 60,
      expectedToReachTarget: false,
    });
    expect(rows[0]?.dailyVals).toEqual([15, 15, 0, 0]);
  });
});
