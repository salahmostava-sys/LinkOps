import { describe, expect, it } from 'vitest';
import { ordersImportHeadersMatch, mergeImportedOrdersFromMatrix } from './importHelpers';
import type { App, Employee } from '@modules/orders/types';

describe('importHelpers', () => {
  describe('ordersImportHeadersMatch', () => {
    it('returns true for exact match', () => {
      expect(ordersImportHeadersMatch(['a', 'b'], ['a', 'b'])).toBe(true);
    });

    it('returns false for length mismatch', () => {
      expect(ordersImportHeadersMatch(['a'], ['a', 'b'])).toBe(false);
    });

    it('returns false for value mismatch', () => {
      expect(ordersImportHeadersMatch(['a', 'c'], ['a', 'b'])).toBe(false);
    });
  });

  describe('mergeImportedOrdersFromMatrix', () => {
    const apps: App[] = [
      { id: 'app1', name: 'App 1', brand_color: '', text_color: '' },
      { id: 'app2', name: 'App 2', brand_color: '', text_color: '' },
    ];
    const employees: Employee[] = [
      { id: 'emp1', name: 'John', platform_accounts: [] },
      { id: 'emp2', name: 'Jane', platform_accounts: [] },
    ];
    const dayArr = [1, 2, 3];

    it('returns error if no active platforms', () => {
      const result = mergeImportedOrdersFromMatrix([], dayArr, employees, [], {});
      expect(result.errors).toContain('لا توجد منصات نشطة');
      expect(result.imported).toBe(0);
    });

    it('skips rows with missing employee name', () => {
      const matrix = [
        [null, 5, 5, 5]
      ];
      const result = mergeImportedOrdersFromMatrix(matrix, dayArr, employees, apps, {});
      expect(result.skipped).toBe(1);
      expect(result.imported).toBe(0);
    });

    it('skips rows with unknown employee', () => {
      const matrix = [
        ['Ghost', 5, 5, 5]
      ];
      const result = mergeImportedOrdersFromMatrix(matrix, dayArr, employees, apps, {});
      expect(result.skipped).toBe(1);
      expect(result.errors[0]).toMatch(/الموظف "Ghost" غير موجود/);
    });

    it('imports valid data successfully', () => {
      const matrix = [
        ['John', 5, '10', null] // day 1: 5, day 2: 10, day 3: skip
      ];
      const result = mergeImportedOrdersFromMatrix(matrix, dayArr, employees, apps, {});
      
      // it imports 2 values per app, 2 apps total = 4 imports
      expect(result.imported).toBe(4);
      expect(result.skipped).toBe(0);
      expect(result.newData['emp1::app1::1']).toBe(5);
      expect(result.newData['emp1::app2::1']).toBe(5);
      expect(result.newData['emp1::app1::2']).toBe(10);
      expect(result.newData['emp1::app2::2']).toBe(10);
      expect(result.newData['emp1::app1::3']).toBeUndefined();
    });

    it('handles validation errors in cells', () => {
      const matrix = [
        ['John', -5, 15000, 'abc'] // day 1: <=0, day 2: >10000, day 3: NaN
      ];
      const result = mergeImportedOrdersFromMatrix(matrix, dayArr, employees, apps, {});
      
      expect(result.imported).toBe(0);
      expect(result.skipped).toBe(1); // skipped because no valid data
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors.some(e => e.includes('كبير جداً'))).toBe(true);
      expect(result.errors.some(e => e.includes('قيمة غير صحيحة'))).toBe(true);
    });

    it('filters by targetAppId', () => {
      const matrix = [
        ['Jane', 2, 2, 2]
      ];
      const result = mergeImportedOrdersFromMatrix(matrix, dayArr, employees, apps, {}, 'app1');
      
      // it imports 3 values * 1 app
      expect(result.imported).toBe(3);
      expect(result.newData['emp2::app1::1']).toBe(2);
      expect(result.newData['emp2::app2::1']).toBeUndefined();
    });
  });
});
