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

import { shiftService } from './shiftService';

describe('shiftService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('returns all shifts successfully', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: [{ id: 's1' }], error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({ order: mockOrder })
      });

      const result = await shiftService.getAll();
      expect(fromMock).toHaveBeenCalledWith('daily_shifts');
      expect(result).toEqual([{ id: 's1' }]);
    });
  });

  describe('getByMonth', () => {
    it('returns shifts for the given month', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: [{ id: 's1' }], error: null });
      const mockLte = vi.fn().mockReturnValue({ order: mockOrder });
      const mockGte = vi.fn().mockReturnValue({ lte: mockLte });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({ gte: mockGte })
      });

      const result = await shiftService.getByMonth('2026-03');
      expect(fromMock).toHaveBeenCalledWith('daily_shifts');
      expect(mockGte).toHaveBeenCalledWith('date', '2026-03-01');
      expect(mockLte).toHaveBeenCalledWith('date', '2026-03-31');
      expect(result).toEqual([{ id: 's1' }]);
    });
  });

  describe('upsert', () => {
    it('inserts a single shift', async () => {
      const mockSingle = vi.fn().mockResolvedValueOnce({ data: { id: 's1' }, error: null });
      const mockSelect = vi.fn().mockReturnValue({ single: mockSingle });
      const mockUpsert = vi.fn().mockReturnValue({ select: mockSelect });
      fromMock.mockReturnValue({ upsert: mockUpsert });

      const result = await shiftService.upsert('emp-1', '2026-03-01', 'app-1', 8);
      expect(fromMock).toHaveBeenCalledWith('daily_shifts');
      expect(mockUpsert).toHaveBeenCalledWith(
        { employee_id: 'emp-1', date: '2026-03-01', app_id: 'app-1', hours_worked: 8, notes: null },
        { onConflict: 'employee_id,app_id,date' }
      );
      expect(result).toEqual({ id: 's1' });
    });
  });

  describe('deleteByMonthAndApp', () => {
    it('deletes shifts properly', async () => {
      const mockLte = vi.fn().mockResolvedValueOnce({ error: null });
      const mockGte = vi.fn().mockReturnValue({ lte: mockLte });
      const mockEq = vi.fn().mockReturnValue({ gte: mockGte });
      fromMock.mockReturnValue({
        delete: vi.fn().mockReturnValue({ eq: mockEq })
      });

      await shiftService.deleteByMonthAndApp(2026, 3, 'app-1');
      expect(mockEq).toHaveBeenCalledWith('app_id', 'app-1');
      expect(mockGte).toHaveBeenCalledWith('date', '2026-03-01');
      expect(mockLte).toHaveBeenCalledWith('date', '2026-03-31');
    });

    it('throws error if delete fails', async () => {
      const mockLte = vi.fn().mockResolvedValueOnce({ error: new Error('db error') });
      const mockGte = vi.fn().mockReturnValue({ lte: mockLte });
      const mockEq = vi.fn().mockReturnValue({ gte: mockGte });
      fromMock.mockReturnValue({
        delete: vi.fn().mockReturnValue({ eq: mockEq })
      });

      await expect(shiftService.deleteByMonthAndApp(2026, 3, 'app-1')).rejects.toThrow('shiftService.deleteByMonthAndApp: db error');
    });
  });
});
