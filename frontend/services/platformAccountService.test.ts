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

import { platformAccountService } from './platformAccountService';

describe('platformAccountService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getApps', () => {
    it('returns active apps successfully', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: [{ id: 'app1' }], error: null });
      const mockEq = vi.fn().mockReturnValue({ order: mockOrder });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({ eq: mockEq })
      });

      const result = await platformAccountService.getApps();
      expect(fromMock).toHaveBeenCalledWith('apps');
      expect(mockEq).toHaveBeenCalledWith('is_active', true);
      expect(result).toEqual([{ id: 'app1' }]);
    });

    it('returns empty array when data is null', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: null, error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({ order: mockOrder })
        })
      });

      const result = await platformAccountService.getApps();
      expect(result).toEqual([]);
    });

    it('throws error when supabase query fails', async () => {
      const mockOrder = vi.fn().mockResolvedValueOnce({ data: null, error: new Error('db error') });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({ order: mockOrder })
        })
      });

      await expect(platformAccountService.getApps()).rejects.toThrow('platformAccountService.getApps: db error');
    });
  });

  describe('createAccount', () => {
    it('inserts account successfully', async () => {
      const mockSingle = vi.fn().mockResolvedValueOnce({ data: { id: 'acc1' }, error: null });
      const mockInsert = vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: mockSingle,
        }),
      });
      fromMock.mockReturnValue({ insert: mockInsert });

      const payload = {
        app_id: 'app1',
        account_username: 'user1',
        employee_id: null,
        account_id_on_platform: null,
        iqama_number: null,
        iqama_expiry_date: null,
        status: 'active' as const,
        notes: null,
      };

      const result = await platformAccountService.createAccount(payload);
      expect(fromMock).toHaveBeenCalledWith('platform_accounts');
      expect(mockInsert).toHaveBeenCalledWith(payload);
      expect(result).toEqual({ id: 'acc1' });
    });
  });

  describe('updateAccount', () => {
    it('updates account successfully', async () => {
      const mockEq = vi.fn().mockResolvedValueOnce({ error: null });
      const mockUpdate = vi.fn().mockReturnValue({ eq: mockEq });
      fromMock.mockReturnValue({ update: mockUpdate });

      const payload = {
        app_id: 'app1',
        account_username: 'user1',
        employee_id: null,
        account_id_on_platform: null,
        iqama_number: null,
        iqama_expiry_date: null,
        status: 'inactive' as const,
        notes: null,
      };

      await platformAccountService.updateAccount('acc1', payload);
      expect(fromMock).toHaveBeenCalledWith('platform_accounts');
      expect(mockUpdate).toHaveBeenCalledWith(payload);
      expect(mockEq).toHaveBeenCalledWith('id', 'acc1');
    });
  });
});
