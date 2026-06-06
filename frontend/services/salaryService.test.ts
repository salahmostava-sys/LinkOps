import { beforeEach, describe, expect, it, vi } from 'vitest';

const { fromMock, rpcMock, getSessionMock } = vi.hoisted(() => ({
  fromMock: vi.fn(),
  rpcMock: vi.fn(),
  getSessionMock: vi.fn(),
}));

vi.mock('@services/supabase/client', () => ({
  supabase: {
    from: fromMock,
    rpc: rpcMock,
    auth: {
      getSession: getSessionMock,
    },
  },
}));

vi.mock('@services/serviceError', () => ({
  handleSupabaseError: vi.fn((error: unknown, context: string) => {
    if (!error) return;
    const message = error instanceof Error ? error.message : 'service error';
    throw new Error(`${context}: ${message}`);
  }),
}));

import { salaryService } from './salaryService';

describe('salaryService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    global.fetch = vi.fn();
  });

  describe('calculateSalaryForEmployeeMonth', () => {
    it('calls the salary-engine edge function correctly', async () => {
      getSessionMock.mockResolvedValueOnce({ data: { session: { access_token: 'fake-token' } } });
      const mockResponse = { data: { net_salary: 1000 } };
      (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      });

      const result = await salaryService.calculateSalaryForEmployeeMonth(
        '123e4567-e89b-12d3-a456-426614174000',
        '2026-03',
        'cash',
        100,
        'Penalty'
      );

      expect(global.fetch).toHaveBeenCalledWith('/api/functions/salary-engine', expect.objectContaining({
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer fake-token' },
      }));
      expect(result).toEqual(mockResponse.data);
    });

    it('throws error when employee_id is invalid', async () => {
      await expect(
        salaryService.calculateSalaryForEmployeeMonth('invalid-id', '2026-03')
      ).rejects.toThrow('salaryService.calculateSalaryForEmployeeMonth: Invalid employee_id or month_year');
    });
  });

  describe('getByMonth', () => {
    it('queries salary_records table correctly', async () => {
      const mockEq = vi.fn().mockReturnThis();
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: [{ id: '1' }], error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: mockEq.mockReturnValue({
            order: mockOrder,
          }),
        }),
      });

      const result = await salaryService.getByMonth('2026-03');
      expect(fromMock).toHaveBeenCalledWith('salary_records');
      expect(result).toEqual([{ id: '1' }]);
    });
  });

  describe('upsert', () => {
    it('upserts a salary record', async () => {
      const mockSingle = vi.fn().mockResolvedValueOnce({ data: { id: '1' }, error: null });
      fromMock.mockReturnValue({
        upsert: vi.fn().mockReturnValue({
          select: vi.fn().mockReturnValue({
            single: mockSingle,
          }),
        }),
      });

      const payload = { employee_id: 'e1', month_year: '2026-03' };
      const result = await salaryService.upsert(payload);
      expect(fromMock).toHaveBeenCalledWith('salary_records');
      expect(result).toEqual({ id: '1' });
    });
  });

  describe('calculateTierSalary', () => {
    it('calculates tier salary correctly (total_multiplier)', () => {
      const tiers = [
        { from_orders: 1, to_orders: 100, price_per_order: 10, tier_order: 1, tier_type: 'total_multiplier' as const },
        { from_orders: 101, to_orders: null, price_per_order: 15, tier_order: 2, tier_type: 'total_multiplier' as const },
      ];
      const salary = salaryService.calculateTierSalary(110, tiers, null, null);
      // 100 * 10 + 10 * 15 = 1000 + 150 = 1150
      expect(salary).toBe(1150);
    });

    it('returns 0 when orders is 0', () => {
      const tiers = [{ from_orders: 1, to_orders: 100, price_per_order: 10, tier_order: 1, tier_type: 'total_multiplier' as const }];
      expect(salaryService.calculateTierSalary(0, tiers, null, null)).toBe(0);
    });
  });
});
