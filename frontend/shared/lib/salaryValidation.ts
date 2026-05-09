/** Matches backend `salary-engine` and Postgres month filters (YYYY-MM). */
export const SALARY_MONTH_YEAR_REGEX = /^\d{4}-(0[1-9]|1[0-2])$/;

function safeToText(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  try {
    return JSON.stringify(value);
  } catch {
    return '';
  }
}

export function isValidSalaryMonthYear(value: string | undefined | null): boolean {
  if (value === undefined || value === null) return false;
  return SALARY_MONTH_YEAR_REGEX.test(safeToText(value).trim());
}

/** Same pattern as Edge Function `salary-engine` for `employee` mode. */
export function isEmployeeIdUuid(value: string | undefined | null): boolean {
  if (!value) return false;
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(safeToText(value).trim());
}

/**
 * Parse monetary cells from Excel (strings with commas, Arabic numerals normalized).
 */
export function parseSalaryAmount(value: unknown): number {
  if (value === null || value === undefined || value === '') return 0;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const AR = '٠١٢٣٤٥٦٧٨٩';
  const WD = '0123456789';
  const s = safeToText(value)
    .split('')
    .map((ch) => {
      const i = AR.indexOf(ch);
      return i >= 0 ? WD[i] : ch;
    })
    .join('')
    .replaceAll(',', '')
    .trim();
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

/** Build YYYY-MM from numeric year + month (1–12). */
export function monthYearFromParts(year: unknown, month: unknown): string | null {
  const y = typeof year === 'number' ? year : Number.parseInt(safeToText(year).trim(), 10);
  const m = typeof month === 'number' ? month : Number.parseInt(safeToText(month).trim(), 10);
  if (!Number.isInteger(y) || !Number.isInteger(m) || m < 1 || m > 12 || y < 2000 || y > 2100) return null;
  return `${y}-${String(m).padStart(2, '0')}`;
}
