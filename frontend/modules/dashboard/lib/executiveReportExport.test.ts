import { beforeEach, describe, expect, it, vi } from 'vitest';

import type { PerformanceDashboardResponse } from '@services/performanceService';
import { exportExecutivePerformanceReport } from './executiveReportExport';

const xlsxMocks = vi.hoisted(() => ({
  appendSheet: vi.fn(),
  bookNew: vi.fn(() => ({ SheetNames: [] })),
  jsonToSheet: vi.fn((rows: unknown[]) => ({ rows })),
  writeFile: vi.fn(),
}));

vi.mock('@modules/orders/utils/xlsx', () => ({
  loadXlsx: vi.fn(async () => ({
    utils: {
      book_new: xlsxMocks.bookNew,
      json_to_sheet: xlsxMocks.jsonToSheet,
      book_append_sheet: xlsxMocks.appendSheet,
    },
    writeFile: xlsxMocks.writeFile,
  })),
}));

const report: PerformanceDashboardResponse = {
  monthYear: '2026-07',
  effectiveEndDate: '2026-07-14',
  leaderboardDate: '2026-07-14',
  summary: {
    totalOrders: 120,
    activeRiders: 4,
    activeEmployees: 4,
    avgOrdersPerRider: 30,
    topPerformerToday: null,
    lowPerformerToday: null,
    topPerformerMonth: null,
    lowPerformerMonth: null,
  },
  comparison: {
    month: { currentOrders: 120, previousOrders: 100, growthPct: 20, currentActiveDays: 14, previousActiveDays: 14, activeDaysDelta: 0 },
    week: { currentOrders: 60, previousOrders: 50, growthPct: 20 },
  },
  targets: { totalTargetOrders: 160, targetAchievementPct: 75 },
  distribution: { excellent: 1, good: 2, average: 1, weak: 0 },
  ordersByApp: [],
  ordersByCity: [],
  dailyTrend: [],
  monthlyTrend: [],
  rankings: { topPerformers: [], lowPerformers: [], mostImproved: [], mostDeclined: [] },
  alerts: [],
};

describe('exportExecutivePerformanceReport', () => {
  beforeEach(() => vi.clearAllMocks());

  it('creates the four executive sheets and writes the monthly workbook', async () => {
    await exportExecutivePerformanceReport(report, 'شركة مهمة التوصيل');

    expect(xlsxMocks.appendSheet.mock.calls.map((call) => call[2])).toEqual([
      'الملخص',
      'المنصات',
      'المراكز',
      'التنبيهات',
    ]);
    expect(xlsxMocks.writeFile).toHaveBeenCalledWith(
      expect.anything(),
      'التقرير_التنفيذي_2026-07.xlsx',
    );
  });
});
