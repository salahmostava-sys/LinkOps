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
  handleSupabaseError: vi.fn((error: unknown, context: string) => {
    if (!error) return;
    const message = error instanceof Error ? error.message : 'service error';
    throw new Error(`${context}: ${message}`);
  }),
}));

vi.mock('@shared/lib/employeeVisibility', () => ({
  filterOperationallyVisibleEmployees: vi.fn((emps: unknown[]) => emps),
}));

import { vehicleService } from './vehicleService';

describe('vehicleService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getAll', () => {
    it('returns all vehicles successfully', async () => {
      const mockLimit = vi.fn().mockResolvedValueOnce({ data: [{ id: 'v1', plate_number: '123' }], error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: mockLimit,
          }),
        }),
      });

      const result = await vehicleService.getAll();
      expect(fromMock).toHaveBeenCalledWith('vehicles');
      expect(result).toEqual([{ id: 'v1', plate_number: '123' }]);
    });

    it('returns empty array on null data', async () => {
      const mockLimit = vi.fn().mockResolvedValueOnce({ data: null, error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: mockLimit,
          }),
        }),
      });

      const result = await vehicleService.getAll();
      expect(result).toEqual([]);
    });

    it('throws error when supabase fails', async () => {
      const mockLimit = vi.fn().mockResolvedValueOnce({ data: null, error: new Error('db error') });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: mockLimit,
          }),
        }),
      });

      await expect(vehicleService.getAll()).rejects.toThrow('vehicleService.getAll: db error');
    });
  });

  describe('create', () => {
    it('inserts a vehicle without assigned_employee_id', async () => {
      const mockSingle = vi.fn().mockResolvedValueOnce({ data: { id: 'v1' }, error: null });
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: mockSingle,
        }),
      });
      fromMock.mockReturnValue({ insert: mockInsert });

      const payload = { plate_number: '123', assigned_employee_id: 'emp-1' };
      const result = await vehicleService.create(payload);

      expect(fromMock).toHaveBeenCalledWith('vehicles');
      expect(mockInsert).toHaveBeenCalledWith({ plate_number: '123' });
      expect(result).toEqual({ id: 'v1' });
    });
  });

  describe('delete', () => {
    it('deletes a vehicle by id', async () => {
      const mockEq = vi.fn().mockResolvedValueOnce({ error: null });
      fromMock.mockReturnValue({
        delete: vi.fn().mockReturnValue({
          eq: mockEq,
        }),
      });

      await vehicleService.delete('v1');
      expect(fromMock).toHaveBeenCalledWith('vehicles');
      expect(mockEq).toHaveBeenCalledWith('id', 'v1');
    });
  });
});
