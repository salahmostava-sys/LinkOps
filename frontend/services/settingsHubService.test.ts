import { beforeEach, describe, expect, it, vi } from 'vitest';

const { fromMock, getSessionMock } = vi.hoisted(() => ({
  fromMock: vi.fn(),
  getSessionMock: vi.fn(),
}));

vi.mock('@services/supabase/client', () => ({
  supabase: {
    from: fromMock,
    auth: {
      getSession: getSessionMock,
    },
    storage: {
      from: vi.fn().mockReturnValue({
        upload: vi.fn(),
        getPublicUrl: vi.fn(),
      })
    }
  },
}));

vi.mock('@services/serviceError', () => ({
  toServiceError: vi.fn((error: unknown, context: string) => {
    if (!error) return;
    const message = error instanceof Error ? error.message : 'service error';
    return new Error(`${context}: ${message}`);
  }),
}));

vi.mock('@services/authService', () => ({
  authService: {
    updatePassword: vi.fn(),
  }
}));

import { settingsHubService } from './settingsHubService';

describe('settingsHubService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('getCurrentUserId', () => {
    it('returns the user id when session exists', async () => {
      getSessionMock.mockResolvedValueOnce({ data: { session: { user: { id: 'user-1' } } }, error: null });
      const result = await settingsHubService.getCurrentUserId();
      expect(result).toBe('user-1');
    });

    it('returns null when there is no user', async () => {
      getSessionMock.mockResolvedValueOnce({ data: { session: null }, error: null });
      const result = await settingsHubService.getCurrentUserId();
      expect(result).toBeNull();
    });

    it('throws error when session fetch fails', async () => {
      getSessionMock.mockResolvedValueOnce({ data: null, error: new Error('auth failed') });
      await expect(settingsHubService.getCurrentUserId()).rejects.toThrow('settingsHubService.getCurrentUserId: auth failed');
    });
  });

  describe('getSystemSettings', () => {
    it('returns settings on success', async () => {
      const mockSettings = { project_name_en: 'Test' };
      const maybeSingle = vi.fn().mockResolvedValueOnce({ data: mockSettings, error: null });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          limit: vi.fn().mockReturnValue({
            maybeSingle
          })
        })
      });

      const result = await settingsHubService.getSystemSettings();
      expect(fromMock).toHaveBeenCalledWith('system_settings');
      expect(result).toEqual(mockSettings);
    });

    it('throws on error', async () => {
      const maybeSingle = vi.fn().mockResolvedValueOnce({ data: null, error: new Error('db error') });
      fromMock.mockReturnValue({
        select: vi.fn().mockReturnValue({
          limit: vi.fn().mockReturnValue({
            maybeSingle
          })
        })
      });

      await expect(settingsHubService.getSystemSettings()).rejects.toThrow('settingsHubService.getSystemSettings: db error');
    });
  });

  describe('saveSystemSettings', () => {
    it('updates existing settings if settingsId provided', async () => {
      const mockUpdate = vi.fn().mockReturnValue({
        eq: vi.fn().mockResolvedValueOnce({ error: null })
      });
      fromMock.mockReturnValue({ update: mockUpdate });

      await settingsHubService.saveSystemSettings('id-1', {
        project_name_ar: 'test',
        project_name_en: 'test',
        default_language: 'ar',
        logo_url: null,
        iqama_alert_days: 90
      });

      expect(fromMock).toHaveBeenCalledWith('system_settings');
      expect(mockUpdate).toHaveBeenCalled();
    });

    it('inserts new settings if settingsId is null', async () => {
      const mockInsert = vi.fn().mockResolvedValueOnce({ error: null });
      fromMock.mockReturnValue({ insert: mockInsert });

      await settingsHubService.saveSystemSettings(null, {
        project_name_ar: 'test',
        project_name_en: 'test',
        default_language: 'ar',
        logo_url: null,
        iqama_alert_days: 90
      });

      expect(fromMock).toHaveBeenCalledWith('system_settings');
      expect(mockInsert).toHaveBeenCalled();
    });
  });

  describe('exportTableRows', () => {
    it('exports allowed tables correctly', async () => {
      const mockSelect = vi.fn().mockResolvedValueOnce({ data: [{ id: 1 }], error: null });
      fromMock.mockReturnValue({ select: mockSelect });

      const result = await settingsHubService.exportTableRows('employees');
      expect(fromMock).toHaveBeenCalledWith('employees');
      expect(result).toEqual([{ id: 1 }]);
    });

    it('throws for disallowed tables', async () => {
      await expect(settingsHubService.exportTableRows('secrets_table')).rejects.toThrow('Table is not allowed for export');
    });

    it('handles empty results', async () => {
      const mockSelect = vi.fn().mockResolvedValueOnce({ data: null, error: null });
      fromMock.mockReturnValue({ select: mockSelect });

      const result = await settingsHubService.exportTableRows('employees');
      expect(result).toEqual([]);
    });
  });
});
