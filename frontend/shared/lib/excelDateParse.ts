/** Parse Excel serial date number (days since 1900-01-01) to {y,m,d} — no xlsx import needed */
function parseExcelSerialDate(serial: number): { y: number; m: number; d: number } | null {
  if (!Number.isFinite(serial) || serial < 1) return null;
  // Excel incorrectly treats 1900 as a leap year; values >= 60 need adjustment
  const adjusted = serial >= 60 ? serial - 1 : serial;
  const epoch = new Date(Date.UTC(1900, 0, 1));
  epoch.setUTCDate(epoch.getUTCDate() + adjusted - 1);
  return { y: epoch.getUTCFullYear(), m: epoch.getUTCMonth() + 1, d: epoch.getUTCDate() };
}

const DD_MM_YYYY = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;
const YYYY_MM_DD = /^(\d{4})-(\d{2})-(\d{2})$/;

function toIsoDate(date: Date): string | null {
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString().split('T')[0];
}

/** Parse Excel cell value to ISO date string yyyy-MM-dd */
export function parseExcelDate(val: unknown): string | null {
  if (val === undefined || val === null || val === '') return null;

  if (val instanceof Date) {
    return toIsoDate(val);
  }

  if (typeof val === 'number') {
    const date = parseExcelSerialDate(val);
    if (!date) return null;
    return toIsoDate(new Date(date.y, date.m - 1, date.d));
  }

  if (typeof val === 'string') {
    const s = val.trim();
    if (!s) return null;

    const dmyMatch = DD_MM_YYYY.exec(s);
    if (dmyMatch) {
      const d = new Date(`${dmyMatch[3]}-${dmyMatch[2].padStart(2, '0')}-${dmyMatch[1].padStart(2, '0')}`);
      return toIsoDate(d);
    }

    if (YYYY_MM_DD.exec(s)) return s;
    return toIsoDate(new Date(s));
  }

  return null;
}
