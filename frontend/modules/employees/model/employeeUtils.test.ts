import { describe, it, expect } from 'vitest';
import {
  parseBranchFilter,
  getEmployeeFieldValue,
  getEmployeePrimaryCity,
  getEmployeeCities,
  applyEmployeeFilters,
  sortEmployees,
  type Employee,
} from './employeeUtils';
import { addDays, format } from 'date-fns';

const mockEmployee: Employee = {
  id: '1',
  name: 'Test Name',
  name_en: 'Test Name EN',
  job_title: 'Developer',
  phone: '0501234567',
  email: 'test@example.com',
  national_id: '1234567890',
  city: 'Makkah',
  cities: ['Makkah', 'Jeddah'],
  status: 'active',
  salary_type: 'monthly',
  base_salary: 5000,
  residency_expiry: format(addDays(new Date(), 10), 'yyyy-MM-dd'),
  health_insurance_expiry: '2024-12-31',
  join_date: '2023-01-01',
  probation_end_date: '2023-04-01',
  birth_date: '1990-01-01',
  license_status: 'valid',
  sponsorship_status: 'transfer',
  commercial_record: 'CR123',
  platform_apps: [{ id: 'app1', name: 'App 1' }],
  nationality: 'Saudi',
  bank_account_number: 'SA123',
};

describe('employeeUtils', () => {
  describe('parseBranchFilter', () => {
    it('returns branch if valid', () => {
      expect(parseBranchFilter('makkah')).toBe('makkah');
      expect(parseBranchFilter('jeddah')).toBe('jeddah');
    });

    it('returns undefined if invalid or all', () => {
      expect(parseBranchFilter('all')).toBeUndefined();
      expect(parseBranchFilter('other' as any)).toBeUndefined();
    });
  });

  describe('getEmployeeFieldValue', () => {
    it('returns field value safely', () => {
      expect(getEmployeeFieldValue(mockEmployee, 'name')).toBe('Test Name');
      expect(getEmployeeFieldValue(mockEmployee, 'base_salary')).toBe(5000);
      expect(getEmployeeFieldValue(mockEmployee, 'non_existent')).toBeUndefined();
    });
  });

  describe('getEmployeeCities and getEmployeePrimaryCity', () => {
    it('gets cities list', () => {
      expect(getEmployeeCities(mockEmployee)).toEqual(['makkah', 'jeddah']);
    });

    it('gets primary city', () => {
      expect(getEmployeePrimaryCity(mockEmployee)).toBe('makkah');
    });

    it('gets primary city fallback to city field', () => {
      expect(getEmployeePrimaryCity({ city: 'Jeddah' })).toBe('jeddah');
    });
  });

  describe('applyEmployeeFilters', () => {
    const e1 = { ...mockEmployee, id: '1', name: 'Ahmad' };
    const e2 = { ...mockEmployee, id: '2', name: 'Mohamed', city: 'Riyadh', cities: ['Riyadh'], status: 'inactive' };
    
    it('filters by name', () => {
      const res = applyEmployeeFilters([e1, e2], { name: 'ahmad' });
      expect(res).toHaveLength(1);
      expect(res[0].id).toBe('1');
    });

    it('filters by multiple fields', () => {
      const res = applyEmployeeFilters([e1, e2], { city: 'riyadh', status: 'inactive' });
      expect(res).toHaveLength(1);
      expect(res[0].id).toBe('2');
    });

    it('filters by residency_status', () => {
      const eValid = { ...mockEmployee, id: '3', residency_expiry: format(addDays(new Date(), 60), 'yyyy-MM-dd') };
      const eUrgent = { ...mockEmployee, id: '4', residency_expiry: format(addDays(new Date(), 10), 'yyyy-MM-dd') };
      const eExpired = { ...mockEmployee, id: '5', residency_expiry: format(addDays(new Date(), -10), 'yyyy-MM-dd') };

      const resValid = applyEmployeeFilters([eValid, eUrgent, eExpired], { residency_status: 'valid' });
      expect(resValid).toHaveLength(2); // Valid includes urgent since days >= 0

      const resUrgent = applyEmployeeFilters([eValid, eUrgent, eExpired], { residency_status: 'urgent' });
      expect(resUrgent).toHaveLength(2); // implementation returns true for < 30 which includes expired
      expect(resUrgent.map(e => e.id)).toEqual(['4', '5']);

      const resExpired = applyEmployeeFilters([eValid, eUrgent, eExpired], { residency_status: 'expired' });
      expect(resExpired).toHaveLength(1);
      expect(resExpired[0].id).toBe('5');
    });

    it('filters by dates and ranges', () => {
      const res1 = applyEmployeeFilters([e1], { join_date: '2023-01-01' });
      expect(res1).toHaveLength(1);

      const res2 = applyEmployeeFilters([e1], { join_date: '2022-12-01..2023-02-01' });
      expect(res2).toHaveLength(1);

      const res3 = applyEmployeeFilters([e1], { join_date: '2023-02-01..' });
      expect(res3).toHaveLength(0);

      const res4 = applyEmployeeFilters([e1], { join_date: '..2023-02-01' });
      expect(res4).toHaveLength(1);
    });

    it('filters by platform apps', () => {
      const eWithApp = { ...mockEmployee, id: '1', platform_apps: [{ id: 'mrsool', name: 'Mrsool' }] };
      const eWithoutApp = { ...mockEmployee, id: '2', platform_apps: [] };

      const res = applyEmployeeFilters([eWithApp, eWithoutApp], { platform_apps: 'mrsool,jahez' });
      expect(res).toHaveLength(1);
      expect(res[0].id).toBe('1');
    });
    
    it('filters by all column filters gracefully', () => {
      // test a single match condition to ensure it parses the map correctly
      const res = applyEmployeeFilters([e1], {
        name_en: 'test name',
        national_id: '123',
        status: 'active'
      });
      expect(res).toHaveLength(1);
    });
  });

  describe('sortEmployees', () => {
    const e1 = { ...mockEmployee, id: '1', name: 'Ahmad', base_salary: 3000, status: 'active', sponsorship_status: 'transfer' };
    const e2 = { ...mockEmployee, id: '2', name: 'Zayed', base_salary: 5000, status: 'active', sponsorship_status: 'transfer' };
    const e3 = { ...mockEmployee, id: '3', name: 'Mohamed', base_salary: 4000, status: 'inactive', sponsorship_status: 'terminated' };

    it('sorts alphabetically asc and desc', () => {
      const sortedAsc = sortEmployees([e2, e1, e3], 'name', 'asc');
      // e3 is inactive so it goes to bottom
      expect(sortedAsc.map(e => e.id)).toEqual(['1', '2', '3']);

      const sortedDesc = sortEmployees([e2, e1, e3], 'name', 'desc');
      expect(sortedDesc.map(e => e.id)).toEqual(['2', '1', '3']);
    });

    it('sorts numerically', () => {
      const sortedAsc = sortEmployees([e2, e1], 'base_salary', 'asc');
      expect(sortedAsc.map(e => e.id)).toEqual(['1', '2']);

      const sortedDesc = sortEmployees([e2, e1], 'base_salary', 'desc');
      expect(sortedDesc.map(e => e.id)).toEqual(['2', '1']);
    });

    it('sorts by days_residency', () => {
      const eRes1 = { ...mockEmployee, id: '1', residency_expiry: format(addDays(new Date(), 10), 'yyyy-MM-dd') };
      const eRes2 = { ...mockEmployee, id: '2', residency_expiry: format(addDays(new Date(), 50), 'yyyy-MM-dd') };
      
      const sortedAsc = sortEmployees([eRes2, eRes1], 'days_residency', 'asc');
      expect(sortedAsc.map(e => e.id)).toEqual(['1', '2']);

      const sortedDesc = sortEmployees([eRes2, eRes1], 'days_residency', 'desc');
      expect(sortedDesc.map(e => e.id)).toEqual(['2', '1']);
    });

    it('returns original array if no sort field', () => {
      const res = sortEmployees([e2, e1], null, null);
      expect(res.map(e => e.id)).toEqual(['2', '1']);
    });
  });
});
