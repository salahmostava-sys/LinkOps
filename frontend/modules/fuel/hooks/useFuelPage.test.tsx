import { renderHook } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { createQueryClientWrapper } from '@shared/test/authedQuerySetup';

vi.mock('@shared/hooks/use-toast', () => ({
  useToast: () => ({ toast: vi.fn() }),
}));

vi.mock('@shared/hooks/usePermissions', () => ({
  usePermissions: () => ({ permissions: { can_edit: true } }),
}));

vi.mock('@shared/hooks/useAuthQueryGate', () => ({
  authQueryUserId: () => '__unauthenticated__',
  useAuthQueryGate: () => ({ enabled: false, userId: null }),
}));

vi.mock('@app/providers/TemporalContext', () => ({
  useTemporalContext: () => ({ selectedMonth: '2026-07' }),
}));

vi.mock('@modules/fuel/hooks/useFuel', () => ({
  useFuel: () => ({
    upsertDailyMileage: vi.fn(),
    bulkUpsertDailyMileage: vi.fn(),
    deleteDailyMileage: vi.fn(),
  }),
}));

import { useFuelPage } from './useFuelPage';

describe('useFuelPage', () => {
  it('initializes empty derived rows before authenticated query data arrives', () => {
    const { result } = renderHook(() => useFuelPage(), {
      wrapper: createQueryClientWrapper(),
    });

    expect(result.current.monthOrdersMap).toEqual({});
    expect(result.current.ridersForTab).toEqual([]);
    expect(result.current.dailyRows).toEqual([]);
  });
});
