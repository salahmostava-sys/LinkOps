import { describe, expect, it } from 'vitest';
import {
  buildAppEmployeeIdsMap,
  collectEmployeeIdsWithOrdersOnApp,
  buildDailyDataMap,
  filterDailyDataByAppIds,
  calculatePlatformTotals,
  getOrdersEmployeeSortPair,
} from './gridHelpers';
import type { App, Employee, EmployeeAppAssignmentRow, OrderRawRow } from '@modules/orders/types';

describe('gridHelpers', () => {
  describe('buildAppEmployeeIdsMap', () => {
    it('builds map correctly', () => {
      const rows: EmployeeAppAssignmentRow[] = [
        { employee_id: 'emp1', app_id: 'app1' },
        { employee_id: 'emp2', app_id: 'app1' },
        { employee_id: 'emp1', app_id: 'app2' },
      ];
      const map = buildAppEmployeeIdsMap(rows);
      expect(map['app1'].has('emp1')).toBe(true);
      expect(map['app1'].has('emp2')).toBe(true);
      expect(map['app2'].has('emp1')).toBe(true);
      expect(map['app2'].has('emp2')).toBe(false);
    });
  });

  describe('collectEmployeeIdsWithOrdersOnApp', () => {
    it('collects employee ids with > 0 orders for given app', () => {
      const data = {
        'emp1::app1::1': 5,
        'emp2::app1::1': 0,
        'emp3::app2::1': 10,
      };
      const result = collectEmployeeIdsWithOrdersOnApp(data, 'app1');
      expect(result.has('emp1')).toBe(true);
      expect(result.has('emp2')).toBe(false);
      expect(result.has('emp3')).toBe(false);
    });
  });

  describe('buildDailyDataMap', () => {
    it('builds daily data map correctly parsing dates', () => {
      const rows: OrderRawRow[] = [
        { employee_id: 'emp1', app_id: 'app1', date: '2026-03-05', orders_count: 10 },
        { employee_id: 'emp2', app_id: 'app1', date: '2026-03-15T00:00:00.000Z', orders_count: 5 },
      ];
      const map = buildDailyDataMap(rows);
      expect(map['emp1::app1::5']).toBe(10);
      expect(map['emp2::app1::15']).toBe(5);
    });
  });

  describe('filterDailyDataByAppIds', () => {
    it('filters data by app ids', () => {
      const data = {
        'emp1::app1::1': 5,
        'emp1::app2::1': 10,
      };
      const filtered = filterDailyDataByAppIds(data, new Set(['app1']));
      expect(filtered['emp1::app1::1']).toBe(5);
      expect(filtered['emp1::app2::1']).toBeUndefined();
    });

    it('returns empty object if no app ids provided', () => {
      const data = { 'emp1::app1::1': 5 };
      expect(filterDailyDataByAppIds(data, new Set())).toEqual({});
    });
  });

  describe('calculatePlatformTotals', () => {
    it('calculates totals only for filtered employees and provided apps', () => {
      const apps: App[] = [{ id: 'app1', name: 'App 1', brand_color: '', text_color: '' }];
      const employees: Employee[] = [{ id: 'emp1', name: 'John', platform_accounts: [] }];
      const data = {
        'emp1::app1::1': 5,
        'emp1::app1::2': 10,
        'emp2::app1::1': 15, // emp2 not in filteredEmployees
        'emp1::app2::1': 20, // app2 not in apps
      };
      const totals = calculatePlatformTotals(apps, employees, [1, 2], data);
      expect(totals['app1']).toBe(15);
      expect(totals['app2']).toBeUndefined();
    });
  });

  describe('getOrdersEmployeeSortPair', () => {
    const a: Employee = { id: 'empA', name: 'Alice', platform_accounts: [] };
    const b: Employee = { id: 'empB', name: 'Bob', platform_accounts: [] };
    const empTotal = (id: string) => (id === 'empA' ? 50 : 30);
    const dayArr = [1, 2];
    const data = {
      'empA::app1::1': 10,
      'empA::app1::2': 5,
      'empB::app1::1': 20,
      'empB::app1::2': 0,
    };

    it('sorts by name', () => {
      expect(getOrdersEmployeeSortPair(a, b, 'name', empTotal, dayArr, data)).toEqual(['Alice', 'Bob']);
    });

    it('sorts by total', () => {
      expect(getOrdersEmployeeSortPair(a, b, 'total', empTotal, dayArr, data)).toEqual([50, 30]);
    });

    it('sorts by specific app', () => {
      expect(getOrdersEmployeeSortPair(a, b, 'app:app1', empTotal, dayArr, data)).toEqual([15, 20]);
    });
  });
});
