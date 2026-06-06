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

  describe('getOverviewRpc', () => {
    it('throws on invalid monthYear format', async () => {
      await expect(dashboardService.getOverviewRpc('2026/04', '2026-04-05')).rejects.toThrow('Invalid monthYear format');
    });

    it('throws on invalid today format', async () => {
      await expect(dashboardService.getOverviewRpc('2026-04', '05-04-2026')).rejects.toThrow('Invalid today format');
    });

    it('returns data successfully on first try', async () => {
      rpcMock.mockResolvedValueOnce({ data: { some: 'data' }, error: null });
      const res = await dashboardService.getOverviewRpc('2026-04', '2026-04-05');
      expect(res).toEqual({ some: 'data' });
    });

    it('retries on signature mismatch and eventually succeeds', async () => {
      rpcMock
        .mockResolvedValueOnce({ data: null, error: { message: 'Could not find the function public.dashboard_overview_rpc' } })
        .mockResolvedValueOnce({ data: { success: true }, error: null });

      const res = await dashboardService.getOverviewRpc('2026-04', '2026-04-05');
      expect(res).toEqual({ success: true });
    });

    it('throws immediately on non-signature mismatch error', async () => {
      rpcMock.mockResolvedValueOnce({ data: null, error: new Error('Permission denied') });
      await expect(dashboardService.getOverviewRpc('2026-04', '2026-04-05')).rejects.toThrow('dashboardService.getOverviewRpc: Permission denied');
    });

    it('throws if all attempts fail with signature mismatch', async () => {
      rpcMock.mockResolvedValue({ data: null, error: new Error('Could not find the function public.dashboard_overview_rpc') });
      await expect(dashboardService.getOverviewRpc('2026-04', '2026-04-05')).rejects.toThrow('dashboardService.getOverviewRpc: Could not find the function');
    });
  });

  describe('getActiveApps', () => {
    it('returns active apps', async () => {
      tableResults.apps = { data: [{ id: '1', name: 'App' }], error: null };
      const res = await dashboardService.getActiveApps();
      expect(res).toEqual([{ id: '1', name: 'App' }]);
    });
    it('throws on error', async () => {
      tableResults.apps = { data: null, error: new Error('apps error') };
      await expect(dashboardService.getActiveApps()).rejects.toThrow('apps error');
    });
  });

  describe('getActiveEmployeeCount', () => {
    it('returns visible active employee count', async () => {
      tableResults.employees = {
        data: [{ id: '1', status: 'active', sponsorship_status: 'sponsored', probation_end_date: null }],
        error: null,
      };
      const res = await dashboardService.getActiveEmployeeCount();
      expect(res).toBe(1);
    });
    it('throws on error', async () => {
      tableResults.employees = { data: null, error: new Error('emp error') };
      await expect(dashboardService.getActiveEmployeeCount()).rejects.toThrow('emp error');
    });
  });

  describe('getMonthSalaryTotal', () => {
    it('returns total sum', async () => {
      tableResults.salary_records = { data: [{ net_salary: 100 }, { net_salary: 200 }], error: null };
      const res = await dashboardService.getMonthSalaryTotal('2026-04');
      expect(res).toBe(300);
    });
    it('throws on error', async () => {
      tableResults.salary_records = { data: null, error: new Error('err') };
      await expect(dashboardService.getMonthSalaryTotal('2026-04')).rejects.toThrow('err');
    });
  });

  describe('getActiveAdvancesTotal', () => {
    it('returns sum of active advances', async () => {
      tableResults.advances = { data: [{ amount: 50 }, { amount: 150 }], error: null };
      const res = await dashboardService.getActiveAdvancesTotal();
      expect(res).toBe(200);
    });
    it('throws on error', async () => {
      tableResults.advances = { data: null, error: new Error('err') };
      await expect(dashboardService.getActiveAdvancesTotal()).rejects.toThrow('err');
    });
  });

  describe('getAttendanceToday', () => {
    it('returns grouped counts', async () => {
      tableResults.attendance = {
        data: [{ status: 'present' }, { status: 'absent' }, { status: 'absent' }, { status: 'leave' }],
        error: null,
      };
      const res = await dashboardService.getAttendanceToday('2026-04-05');
      expect(res).toEqual({ present: 1, absent: 2, leave: 1 });
    });
    it('throws on error', async () => {
      tableResults.attendance = { data: null, error: new Error('err') };
      await expect(dashboardService.getAttendanceToday('2026-04-05')).rejects.toThrow('err');
    });
  });

  describe('getMonthOrders', () => {
    it('returns data', async () => {
      tableResults.daily_orders = { data: [{ id: '1' }], error: null };
      const res = await dashboardService.getMonthOrders('2026-04');
      expect(res).toEqual([{ id: '1' }]);
    });
    it('throws on error', async () => {
      tableResults.daily_orders = { data: null, error: new Error('err') };
      await expect(dashboardService.getMonthOrders('2026-04')).rejects.toThrow('err');
    });
  });

  describe('getMonthOrdersCount', () => {
    it('returns sum', async () => {
      tableResults.daily_orders = { data: [{ orders_count: 5 }, { orders_count: 10 }], error: null };
      const res = await dashboardService.getMonthOrdersCount('2026-04');
      expect(res).toBe(15);
    });
    it('throws on error', async () => {
      tableResults.daily_orders = { data: null, error: new Error('err') };
      await expect(dashboardService.getMonthOrdersCount('2026-04')).rejects.toThrow('err');
    });
  });

  describe('getAttendanceTrend', () => {
    it('returns mapped trend data', async () => {
      tableResults.attendance = {
        data: [
          { date: '2026-04-01', status: 'present' },
          { date: '2026-04-01', status: 'absent' },
          { date: '2026-04-02', status: 'leave' },
        ],
        error: null,
      };
      const res = await dashboardService.getAttendanceTrend('2026-04-01', '2026-04-02');
      expect(res).toEqual([
        { date: '2026-04-01', present: 1, absent: 1, leave: 0 },
        { date: '2026-04-02', present: 0, absent: 0, leave: 1 },
      ]);
    });
    it('throws on error', async () => {
      tableResults.attendance = { data: null, error: new Error('err') };
      await expect(dashboardService.getAttendanceTrend('2026-04-01', '2026-04-02')).rejects.toThrow('err');
    });
  });

  describe('getRecentActivity', () => {
    it('returns data', async () => {
      tableResults.audit_log = { data: [{ id: '1' }], error: null };
      const res = await dashboardService.getRecentActivity();
      expect(res).toEqual([{ id: '1' }]);
    });
    it('throws on error', async () => {
      tableResults.audit_log = { data: null, error: new Error('err') };
      await expect(dashboardService.getRecentActivity()).rejects.toThrow('err');
    });
  });

  describe('getEmployeeAppAssignments', () => {
    it('returns data', async () => {
      tableResults.employee_apps = { data: [{ app_id: '1' }], error: null };
      const res = await dashboardService.getEmployeeAppAssignments();
      expect(res).toEqual([{ app_id: '1' }]);
    });
    it('throws on error', async () => {
      tableResults.employee_apps = { data: null, error: new Error('err') };
      await expect(dashboardService.getEmployeeAppAssignments()).rejects.toThrow('err');
    });
  });

  describe('getSystemSettings', () => {
    it('returns data', async () => {
      tableResults.system_settings = { data: { logo_url: 'logo.png' }, error: null };
      const res = await dashboardService.getSystemSettings();
      expect(res).toEqual({ logo_url: 'logo.png' });
    });
    it('throws on error', async () => {
      tableResults.system_settings = { data: null, error: new Error('err') };
      await expect(dashboardService.getSystemSettings()).rejects.toThrow('err');
    });
  });

  describe('getEmployeeDistribution', () => {
    it('returns data filtered', async () => {
      tableResults.employees = {
        data: [{ id: '1', status: 'active', sponsorship_status: 'sponsored', probation_end_date: null }],
        error: null,
      };
      const res = await dashboardService.getEmployeeDistribution();
      expect(res.length).toBe(1);
    });
    it('throws on error', async () => {
      tableResults.employees = { data: null, error: new Error('err') };
      await expect(dashboardService.getEmployeeDistribution()).rejects.toThrow('err');
    });
  });

  describe('getActiveVehiclesCount', () => {
    it('returns count', async () => {
      tableResults.vehicles = { data: null, count: 5, error: null };
      const res = await dashboardService.getActiveVehiclesCount();
      expect(res).toBe(5);
    });
    it('throws on error', async () => {
      tableResults.vehicles = { data: null, error: new Error('err') };
      await expect(dashboardService.getActiveVehiclesCount()).rejects.toThrow('err');
    });
  });

  describe('getUnresolvedAlertsCount', () => {
    it('returns count', async () => {
      tableResults.alerts = { data: null, count: 3, error: null };
      const res = await dashboardService.getUnresolvedAlertsCount();
      expect(res).toBe(3);
    });
    it('throws on error', async () => {
      tableResults.alerts = { data: null, error: new Error('err') };
      await expect(dashboardService.getUnresolvedAlertsCount()).rejects.toThrow('err');
    });
  });

  describe('getAppTargets', () => {
    it('returns data', async () => {
      tableResults.app_targets = { data: [{ app_id: '1' }], error: null };
      const res = await dashboardService.getAppTargets('2026-04');
      expect(res).toEqual([{ app_id: '1' }]);
    });
    it('throws on error', async () => {
      tableResults.app_targets = { data: null, error: new Error('err') };
      await expect(dashboardService.getAppTargets('2026-04')).rejects.toThrow('err');
    });
  });

  describe('getSupervisorPerformance', () => {
    it('returns performance rows', async () => {
      tableResults.supervisor_targets = { data: [{ supervisor_id: 's1', target_orders: 100 }], error: null };
      tableResults.profiles = { data: [{ id: 's1', name: 'Supervisor A' }], error: null };
      tableResults.supervisor_employee_assignments = {
        data: [{ supervisor_id: 's1', employee_id: 'e1', start_date: '2026-04-01', end_date: null }],
        error: null,
      };
      tableResults.daily_orders = {
        data: [{ employee_id: 'e1', date: '2026-04-02', orders_count: 50 }],
        error: null,
      };

      const res = await dashboardService.getSupervisorPerformance('2026-04');
      expect(res).toEqual([
        {
          supervisor_id: 's1',
          supervisor_name: 'Supervisor A',
          target_orders: 100,
          actual_orders: 50,
          achievement_percent: 50,
        },
      ]);
    });

    it('throws if targets query fails', async () => {
      tableResults.supervisor_targets = { data: null, error: new Error('targets error') };
      tableResults.profiles = { data: [], error: null };
      tableResults.supervisor_employee_assignments = { data: [], error: null };
      tableResults.daily_orders = { data: [], error: null };

      await expect(dashboardService.getSupervisorPerformance('2026-04')).rejects.toThrow('dashboardService.getSupervisorPerformance.targets: targets error');
    });
    
    it('throws if profiles query fails', async () => {
      tableResults.supervisor_targets = { data: [], error: null };
      tableResults.profiles = { data: null, error: new Error('profiles error') };
      tableResults.supervisor_employee_assignments = { data: [], error: null };
      tableResults.daily_orders = { data: [], error: null };

      await expect(dashboardService.getSupervisorPerformance('2026-04')).rejects.toThrow('dashboardService.getSupervisorPerformance.profiles: profiles error');
    });
    
    it('throws if assignments query fails', async () => {
      tableResults.supervisor_targets = { data: [], error: null };
      tableResults.profiles = { data: [], error: null };
      tableResults.supervisor_employee_assignments = { data: null, error: new Error('assignments error') };
      tableResults.daily_orders = { data: [], error: null };

      await expect(dashboardService.getSupervisorPerformance('2026-04')).rejects.toThrow('dashboardService.getSupervisorPerformance.assignments: assignments error');
    });

    it('throws if orders query fails', async () => {
      tableResults.supervisor_targets = { data: [], error: null };
      tableResults.profiles = { data: [], error: null };
      tableResults.supervisor_employee_assignments = { data: [], error: null };
      tableResults.daily_orders = { data: null, error: new Error('orders error') };

      await expect(dashboardService.getSupervisorPerformance('2026-04')).rejects.toThrow('dashboardService.getSupervisorPerformance.orders: orders error');
    });
  });

  describe('getAdditionalMetrics', () => {
    it('returns formatted metrics', async () => {
      tableResults.fuel_records = { data: [{ cost: 100, liters: 50 }], error: null };
      tableResults.maintenance_records = { data: [{ cost: 200 }], error: null };
      tableResults.violations = { data: [{ amount: 300 }], error: null };
      tableResults.advances = { data: [{ amount: 400 }], error: null };
      tableResults.salary_records = { data: [{ net_salary: 500 }], error: null };

      const res = await dashboardService.getAdditionalMetrics('2026-04');
      expect(res).toEqual({
        fuelCost: 100,
        fuelLiters: 50,
        maintenanceCost: 200,
        violationsCount: 1,
        violationsCost: 300,
        pendingAdvances: 400,
        totalSalaries: 500,
      });
    });

    it('throws when maintenance query fails', async () => {
      tableResults.fuel_records = { data: [], error: null };
      tableResults.maintenance_records = { data: null, error: new Error('m error') };
      tableResults.violations = { data: [], error: null };
      tableResults.advances = { data: [], error: null };
      tableResults.salary_records = { data: [], error: null };

      await expect(dashboardService.getAdditionalMetrics('2026-04')).rejects.toThrow('m error');
    });
    
    it('throws when violations query fails', async () => {
      tableResults.fuel_records = { data: [], error: null };
      tableResults.maintenance_records = { data: [], error: null };
      tableResults.violations = { data: null, error: new Error('v error') };
      tableResults.advances = { data: [], error: null };
      tableResults.salary_records = { data: [], error: null };

      await expect(dashboardService.getAdditionalMetrics('2026-04')).rejects.toThrow('v error');
    });
    
    it('throws when advances query fails', async () => {
      tableResults.fuel_records = { data: [], error: null };
      tableResults.maintenance_records = { data: [], error: null };
      tableResults.violations = { data: [], error: null };
      tableResults.advances = { data: null, error: new Error('a error') };
      tableResults.salary_records = { data: [], error: null };

      await expect(dashboardService.getAdditionalMetrics('2026-04')).rejects.toThrow('a error');
    });
    
    it('throws when salaries query fails', async () => {
      tableResults.fuel_records = { data: [], error: null };
      tableResults.maintenance_records = { data: [], error: null };
      tableResults.violations = { data: [], error: null };
      tableResults.advances = { data: [], error: null };
      tableResults.salary_records = { data: null, error: new Error('s error') };

      await expect(dashboardService.getAdditionalMetrics('2026-04')).rejects.toThrow('s error');
    });
  });

  describe('getKPIs', () => {
    it('returns kpis', async () => {
      tableResults.employees = {
        data: [{ id: '1', status: 'active', sponsorship_status: 'sponsored', probation_end_date: null }],
        error: null,
      };
      tableResults.attendance = { data: [{ status: 'present' }], error: null };
      tableResults.advances = { data: [{ amount: 10 }], error: null };
      tableResults.salary_records = { data: [{ net_salary: 100 }], error: null };

      const res = await dashboardService.getKPIs('2026-04', '2026-04-05');
      expect(res.kpis).toEqual({
        activeEmployees: 1,
        presentToday: 1,
        absentToday: 0,
        activeAdvances: 10,
        totalSalaries: 100,
        totalOrders: 0,
      });
    });

    it('throws when attendance fails', async () => {
      tableResults.employees = { data: [], error: null };
      tableResults.attendance = { data: null, error: new Error('att err') };
      tableResults.advances = { data: [], error: null };
      tableResults.salary_records = { data: [], error: null };

      await expect(dashboardService.getKPIs('2026-04', '2026-04-05')).rejects.toThrow('att err');
    });

    it('throws when advances fails', async () => {
      tableResults.employees = { data: [], error: null };
      tableResults.attendance = { data: [], error: null };
      tableResults.advances = { data: null, error: new Error('adv err') };
      tableResults.salary_records = { data: [], error: null };

      await expect(dashboardService.getKPIs('2026-04', '2026-04-05')).rejects.toThrow('adv err');
    });
    
    it('throws when salary fails', async () => {
      tableResults.employees = { data: [], error: null };
      tableResults.attendance = { data: [], error: null };
      tableResults.advances = { data: [], error: null };
      tableResults.salary_records = { data: null, error: new Error('sal err') };

      await expect(dashboardService.getKPIs('2026-04', '2026-04-05')).rejects.toThrow('sal err');
    });
  });
});
