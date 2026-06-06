import { beforeEach, describe, expect, it, vi } from 'vitest';

const { fromMock } = vi.hoisted(() => ({
  fromMock: vi.fn(),
}));

vi.mock('@services/supabase/client', () => ({
  supabase: {
    from: fromMock,
  },
}));

vi.mock('@services/serviceError', () => ({
  toServiceError: vi.fn((error: unknown, context: string) => {
    if (!error) return;
    const message = error instanceof Error ? error.message : 'service error';
    return new Error(`${context}: ${message}`);
  }),
}));

import { salarySchemeService } from './salarySchemeService';

describe('salarySchemeService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getSchemes', () => {
    it('returns schemes successfully', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: [{ id: 'scheme1' }], error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({ order: mockOrder })
      });

      const result = await salarySchemeService.getSchemes();
      expect(fromMock).toHaveBeenCalledWith('salary_schemes');
      expect(result).toEqual([{ id: 'scheme1' }]);
    });
  });

  describe('createScheme', () => {
    it('creates a new scheme and returns its id', async () => {
      const mockSingle = vi.fn().mockResolvedValueOnce({ data: { id: 'scheme1' }, error: null });
      const mockSelect = vi.fn().mockReturnValue({ single: mockSingle });
      const mockInsert = vi.fn().mockReturnValue({ select: mockSelect });
      fromMock.mockReturnValue({ insert: mockInsert });

      const payload = {
        name: 'New Scheme',
        scheme_type: 'order_based' as const,
        monthly_amount: null,
        target_orders: null,
        target_bonus: null,
      };

      const result = await salarySchemeService.createScheme(payload);
      expect(fromMock).toHaveBeenCalledWith('salary_schemes');
      expect(mockInsert).toHaveBeenCalledWith(payload);
      expect(result).toEqual({ id: 'scheme1' });
    });
  });

  describe('upsertSnapshot', () => {
    it('upserts a scheme snapshot successfully', async () => {
      const mockUpsert = vi.fn().mockResolvedValueOnce({ error: null });
      fromMock.mockReturnValue({ upsert: mockUpsert });

      const snapshot = { name: 'New Scheme' };
      await salarySchemeService.upsertSnapshot('scheme1', '2026-03', snapshot);

      expect(fromMock).toHaveBeenCalledWith('scheme_month_snapshots');
      expect(mockUpsert).toHaveBeenCalledWith(
        { scheme_id: 'scheme1', month_year: '2026-03', snapshot },
        { onConflict: 'scheme_id,month_year' }
      );
    });

    it('throws error when supabase fails', async () => {
      const mockUpsert = vi.fn().mockResolvedValueOnce({ error: new Error('db error') });
      fromMock.mockReturnValue({ upsert: mockUpsert });

      await expect(
        salarySchemeService.upsertSnapshot('scheme1', '2026-03', {})
      ).rejects.toThrow('salarySchemeService.upsertSnapshot: db error');
    });
  });
});
