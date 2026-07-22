/**
 * Saudi WPS / Mudad wage-file builders (pure, framework-free — unit tested).
 *
 * Two channels with DIFFERENT eligibility:
 * - **Mudad**: documents salaries paid by ANY method, so it includes bank AND
 *   cash employees (cash employees carry an empty IBAN + a "cash" payment flag).
 * - **Bank file (SARIE)**: a direct bank transfer, so it needs a valid Saudi
 *   IBAN and bank payment — cash/no-IBAN employees are excluded from it.
 *
 * IMPORTANT: the exact column layout differs by bank and by Mudad version;
 * verify against your bank's/Mudad's own template before submitting. The file
 * keys on the numeric bank code, derived reliably from each IBAN.
 *
 * Housing allowance isn't tracked here, so it is emitted as 0 and all additions
 * go to "other allowances". Basic = base salary.
 */
import { deriveSaudiBankCode, isValidSaudiIban, normalizeIban } from '@shared/lib/saudiBank';

export interface WpsEmployeeInput {
  employeeId: string;
  name: string;
  nationalId: string;
  iban: string;
  paymentMethod: 'bank' | 'cash';
  basicSalary: number;
  otherAllowances: number;
  deductions: number;
  netSalary: number;
}

export interface WpsEstablishment {
  companyName: string;
  molEstablishmentNumber: string;
  employerIban: string;
  employerBankCode: string | null;
}

export interface WpsRow {
  name: string;
  nationalId: string;
  iban: string;
  bankCode: string;
  paymentMethod: 'bank' | 'cash';
  /** True when the row can go into the bank (SARIE) file: bank payment + valid IBAN. */
  bankEligible: boolean;
  basicSalary: number;
  housingAllowance: number;
  otherAllowances: number;
  deductions: number;
  netSalary: number;
}

export interface WpsNotice {
  name: string;
  reason: string;
}

export interface WpsBuildResult {
  /** All identifiable employees — the Mudad set (bank + cash). */
  rows: WpsRow[];
  /** Employees kept out of the BANK file (cash or invalid IBAN), with reason. */
  bankExcluded: WpsNotice[];
  /** Employees whose net is below the legal minimum ratio (Mudad may reject). */
  warnings: WpsNotice[];
  /** Employees dropped entirely (no national id — can't be filed anywhere). */
  dropped: WpsNotice[];
}

/** Minimum net-to-gross ratio the labor system requires (Mudad rejects below this). */
export const WPS_MIN_NET_RATIO = 0.5;

const round2 = (n: number) => Math.round((Number(n) || 0) * 100) / 100;

function toWpsRow(emp: WpsEmployeeInput): WpsRow {
  const iban = normalizeIban(emp.iban);
  const validIban = isValidSaudiIban(iban);
  return {
    name: emp.name,
    nationalId: emp.nationalId,
    iban: validIban ? iban : '',
    bankCode: validIban ? (deriveSaudiBankCode(iban) ?? '') : '',
    paymentMethod: emp.paymentMethod,
    bankEligible: emp.paymentMethod === 'bank' && validIban,
    basicSalary: round2(emp.basicSalary),
    housingAllowance: 0,
    otherAllowances: round2(emp.otherAllowances),
    deductions: round2(emp.deductions),
    netSalary: round2(emp.netSalary),
  };
}

export function buildWpsExport(inputs: WpsEmployeeInput[]): WpsBuildResult {
  const rows: WpsRow[] = [];
  const bankExcluded: WpsNotice[] = [];
  const warnings: WpsNotice[] = [];
  const dropped: WpsNotice[] = [];

  for (const emp of inputs) {
    if (!emp.nationalId?.trim()) {
      dropped.push({ name: emp.name, reason: 'missing_national_id' });
      continue;
    }

    const row = toWpsRow(emp);
    rows.push(row);

    if (!row.bankEligible) {
      bankExcluded.push({
        name: emp.name,
        reason: emp.paymentMethod !== 'bank' ? 'payment_method_cash' : 'invalid_iban',
      });
    }

    const gross = row.basicSalary + row.otherAllowances; // housing is 0
    if (gross > 0 && row.netSalary < WPS_MIN_NET_RATIO * gross) {
      warnings.push({ name: emp.name, reason: 'net_below_half_gross' });
    }
  }

  return { rows, bankExcluded, warnings, dropped };
}

/** The Mudad set: every identifiable employee (bank + cash). */
export const mudadRows = (result: WpsBuildResult): WpsRow[] => result.rows;

/** The bank-file set: only bank-paid employees with a valid IBAN. */
export const bankRows = (result: WpsBuildResult): WpsRow[] => result.rows.filter((r) => r.bankEligible);

const PAYMENT_LABEL: Record<'bank' | 'cash', string> = { bank: 'بنك', cash: 'نقدي' };

// Shared money/identity columns.
const BASE_COLUMNS: ReadonlyArray<{ key: keyof WpsRow; label: string }> = [
  { key: 'nationalId', label: 'رقم الهوية/الإقامة' },
  { key: 'name', label: 'اسم الموظف' },
  { key: 'iban', label: 'الآيبان' },
  { key: 'bankCode', label: 'كود البنك' },
  { key: 'basicSalary', label: 'الراتب الأساسي' },
  { key: 'housingAllowance', label: 'بدل السكن' },
  { key: 'otherAllowances', label: 'بدلات أخرى' },
  { key: 'deductions', label: 'الاستقطاعات' },
  { key: 'netSalary', label: 'صافي الراتب' },
];

// Kept exported for tests/backward reference.
export const WPS_COLUMNS = BASE_COLUMNS;

const csvCell = (value: string | number): string => {
  const s = String(value ?? '');
  return /[",\r\n]/u.test(s) ? `"${s.replaceAll('"', '""')}"` : s;
};

/** Mudad-style CSV: includes a payment-method column (bank/cash) + the month. */
export function toMudadCsv(rows: WpsRow[], monthYear: string): string {
  const header = [...BASE_COLUMNS.map((c) => c.label), 'طريقة الدفع', 'الشهر'];
  const lines = [header.map(csvCell).join(',')];
  for (const row of rows) {
    const cells = BASE_COLUMNS.map((c) => row[c.key] as string | number);
    lines.push([...cells, PAYMENT_LABEL[row.paymentMethod], monthYear].map(csvCell).join(','));
  }
  return lines.join('\r\n');
}

/**
 * Bank-file worksheet as an array-of-arrays (fed to SheetJS by the caller):
 * establishment header block, then the employee table (bank-eligible rows only).
 */
export function toBankWpsAoa(
  rows: WpsRow[],
  establishment: WpsEstablishment,
  monthYear: string,
): (string | number)[][] {
  return [
    ['ملف حماية الأجور (WPS)'],
    ['المنشأة', establishment.companyName],
    ['رقم المنشأة (مكتب العمل)', establishment.molEstablishmentNumber],
    ['آيبان المنشأة', establishment.employerIban],
    ['كود بنك المنشأة', establishment.employerBankCode ?? ''],
    ['الشهر', monthYear],
    [],
    BASE_COLUMNS.map((c) => c.label),
    ...rows.map((row) => BASE_COLUMNS.map((c) => row[c.key] as string | number)),
  ];
}
