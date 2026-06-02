import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createQueryBuilder, type MockQueryResult } from '@shared/test/mocks/supabaseClientMock';
import { resetMockTableResults, throwFormattedServiceError } from '@shared/test/mocks/serviceLayerTestUtils';

const { tableResults, fromMock, rpcMock } = vi.hoisted(() => {
  const tableResultsLocal: Record<string, MockQueryResult> = {};
  return {
    tableResults: tableResultsLocal,
    fromMock: vi.fn((table: string) => createQueryBuilder(tableResultsLocal[table] ?? { data: null, error: null })),
    rpcMock: vi.fn(),
  };
});

vi.mock('@services/supabase/client', () => ({
  supabase: {
    from: fromMock,
    rpc: rpcMock,
  },
}));

vi.mock('@services/serviceError', () => ({
  handleSupabaseError: vi.fn(throwFormattedServiceError),
}));

import { dashboardService } from './dashboardService';

describe('dashboardService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    resetMockTableResults(tableResults);
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-04-05T12:00:00.000Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('throws when additional metrics fuel query fails', async () => {
    tableResults.fuel_records = {
      data: null,
      error: new Error('fuel down'),
    };

    await expect(dashboardService.getAdditionalMetrics('2026-04')).rejects.toThrow(
      'dashboardService.getAdditionalMetrics.fuelRes: fuel down',
    );
  });

  it('throws when KPIs employee query fails', async () => {
    tableResults.employees = {
      data: null,
      error: new Error('employees query failed'),
    };
    tableResults.attendance = { data: [], error: null };
    tableResults.advances = { data: [], error: null };
    tableResults.salary_records = { data: [], error: null };

    await expect(dashboardService.getKPIs('2026-04', '2026-04-05')).rejects.toThrow(
      'dashboardService.getKPIs.empRes: employees query failed',
    );
  });

  it('filters operationally hidden employees from active employee count', async () => {
    tableResults.employees = {
      data: [
        {
          id: 'emp-visible',
          status: 'active',
          sponsorship_status: 'sponsored',
          probation_end_date: null,
        },
        {
          id: 'emp-hidden',
          status: 'active',
          sponsorship_status: 'terminated',
          probation_end_date: '2026-03-01',
        },
      ],
      error: null,
    };
    tableResults.attendance = { data: [], error: null };
    tableResults.advances = { data: [], error: null };
    tableResults.salary_records = { data: [], error: null };

    const result = await dashboardService.getKPIs('2026-04', '2026-04-05');

    // Only the sponsored employee without terminated probation should be visible
    expect(result.kpis.activeEmployees).toBe(1);
  });
});
