import { describe, expect, it } from 'vitest';
import {
  bankRows,
  buildWpsExport,
  mudadRows,
  toBankWpsAoa,
  toMudadCsv,
  WPS_COLUMNS,
  type WpsEmployeeInput,
  type WpsEstablishment,
} from './wpsExport';

const VALID_IBAN = 'SA0380000000608010167519'; // 24 chars, bank code 80

const baseEmp = (over: Partial<WpsEmployeeInput> = {}): WpsEmployeeInput => ({
  employeeId: 'e1',
  name: 'أحمد السيد',
  nationalId: '1234567890',
  iban: VALID_IBAN,
  paymentMethod: 'bank',
  basicSalary: 3000,
  otherAllowances: 500,
  deductions: 200,
  netSalary: 3300,
  ...over,
});

describe('buildWpsExport', () => {
  it('marks a valid bank employee as bank-eligible and derives the bank code', () => {
    const result = buildWpsExport([baseEmp()]);
    expect(result.bankExcluded).toHaveLength(0);
    expect(result.rows).toHaveLength(1);
    expect(result.rows[0].bankEligible).toBe(true);
    expect(result.rows[0].bankCode).toBe('80');
    expect(result.rows[0].housingAllowance).toBe(0);
  });

  it('includes cash employees for Mudad but keeps them out of the bank file', () => {
    const result = buildWpsExport([baseEmp({ paymentMethod: 'cash', iban: '' })]);
    // Mudad set = everyone
    expect(mudadRows(result)).toHaveLength(1);
    expect(mudadRows(result)[0].paymentMethod).toBe('cash');
    // Bank file excludes them
    expect(bankRows(result)).toHaveLength(0);
    expect(result.bankExcluded).toEqual([{ name: 'أحمد السيد', reason: 'payment_method_cash' }]);
  });

  it('keeps a bank employee with an invalid IBAN in Mudad but out of the bank file', () => {
    const result = buildWpsExport([baseEmp({ iban: 'SA123' })]);
    expect(mudadRows(result)).toHaveLength(1);
    expect(bankRows(result)).toHaveLength(0);
    expect(result.bankExcluded[0].reason).toBe('invalid_iban');
    expect(result.rows[0].iban).toBe(''); // invalid IBAN not carried through
  });

  it('drops employees with no national id (cannot be filed anywhere)', () => {
    const result = buildWpsExport([baseEmp({ nationalId: '  ' })]);
    expect(result.rows).toHaveLength(0);
    expect(result.dropped[0].reason).toBe('missing_national_id');
  });

  it('warns when net salary is below 50% of gross', () => {
    // gross = 3500; net 1000 < 1750 → warning, still included
    const result = buildWpsExport([baseEmp({ deductions: 2500, netSalary: 1000 })]);
    expect(result.rows).toHaveLength(1);
    expect(result.warnings).toEqual([{ name: 'أحمد السيد', reason: 'net_below_half_gross' }]);
  });
});

describe('toMudadCsv', () => {
  it('includes a payment-method column and one row per employee', () => {
    const result = buildWpsExport([baseEmp(), baseEmp({ name: 'سالم', paymentMethod: 'cash', iban: '' })]);
    const csv = toMudadCsv(mudadRows(result), '2026-07');
    const lines = csv.split('\r\n');
    expect(lines).toHaveLength(3); // header + 2
    expect(lines[0]).toContain('طريقة الدفع');
    expect(lines[0].endsWith('الشهر')).toBe(true);
    expect(lines[2]).toContain('نقدي');
  });
});

describe('toBankWpsAoa', () => {
  it('prepends the establishment header block before the employee table', () => {
    const est: WpsEstablishment = {
      companyName: 'شركة التوصيل',
      molEstablishmentNumber: '700123',
      employerIban: VALID_IBAN,
      employerBankCode: '80',
    };
    const result = buildWpsExport([baseEmp()]);
    const aoa = toBankWpsAoa(bankRows(result), est, '2026-07');
    expect(aoa[1]).toEqual(['المنشأة', 'شركة التوصيل']);
    const headerIdx = aoa.findIndex((r) => r[0] === WPS_COLUMNS[0].label);
    expect(headerIdx).toBeGreaterThan(0);
    expect(aoa[headerIdx + 1][0]).toBe('1234567890');
  });
});
