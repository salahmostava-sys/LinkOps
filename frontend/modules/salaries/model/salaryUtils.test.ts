import { describe, expect, it } from 'vitest';
import { 
  getDisplayedBaseSalary, 
  getSalaryRowActivityTotals, 
  isAdministrativeJobTitle,
  toCityArabicLabel,
  hasPlatformActivity,
  isRiderJobTitle,
  getPrimaryPlatformActivityCount,
  getPlatformActivitySummary,
  getPlatformActivityCompactSummary,
  getSalaryRowActivitySummary
} from './salaryUtils';


describe('toCityArabicLabel', () => {
  it('translates makkah to Arabic', () => {
    expect(toCityArabicLabel('makkah')).toBe('مكة');
  });

  it('translates jeddah to Arabic', () => {
    expect(toCityArabicLabel('jeddah')).toBe('جدة');
  });

  it('returns dash for unknown or undefined', () => {
    expect(toCityArabicLabel('riyadh')).toBe('—');
    expect(toCityArabicLabel(null)).toBe('—');
    expect(toCityArabicLabel(undefined)).toBe('—');
  });
});

describe('hasPlatformActivity', () => {
  it('returns false for null or empty metric', () => {
    expect(hasPlatformActivity(null)).toBe(false);
    expect(hasPlatformActivity(undefined)).toBe(false);
    expect(hasPlatformActivity({ ordersCount: 0, shiftDays: 0, salary: 0 } as any)).toBe(false);
  });

  it('returns true if any activity exists', () => {
    expect(hasPlatformActivity({ ordersCount: 1, shiftDays: 0, salary: 0 } as any)).toBe(true);
    expect(hasPlatformActivity({ ordersCount: 0, shiftDays: 1, salary: 0 } as any)).toBe(true);
    expect(hasPlatformActivity({ ordersCount: 0, shiftDays: 0, salary: 100 } as any)).toBe(true);
  });
});

describe('isRiderJobTitle', () => {
  it('returns true for rider keywords', () => {
    expect(isRiderJobTitle('Rider')).toBe(true);
    expect(isRiderJobTitle('Delivery Driver')).toBe(true);
    expect(isRiderJobTitle('مندوب مبيعات')).toBe(true);
  });

  it('returns false for non-rider titles', () => {
    expect(isRiderJobTitle('Manager')).toBe(false);
    expect(isRiderJobTitle('Accountant')).toBe(false);
    expect(isRiderJobTitle(null)).toBe(false);
    expect(isRiderJobTitle('')).toBe(false);
  });
});

describe('isAdministrativeJobTitle', () => {
  it('matches common Arabic and English administration titles', () => {
    expect(isAdministrativeJobTitle('مدير عمليات')).toBe(true);
    expect(isAdministrativeJobTitle('HR Coordinator')).toBe(true);
    expect(isAdministrativeJobTitle('محاسب')).toBe(true);
  });

  it('does not classify delivery roles as administration', () => {
    expect(isAdministrativeJobTitle('مندوب توصيل')).toBe(false);
    expect(isAdministrativeJobTitle('Driver')).toBe(false);
  });

  it('returns false for empty titles', () => {
    expect(isAdministrativeJobTitle(null)).toBe(false);
    expect(isAdministrativeJobTitle('')).toBe(false);
  });
});

describe('getDisplayedBaseSalary', () => {
  it('uses preferEngineBaseSalary when it is true and > 0', () => {
    expect(
      getDisplayedBaseSalary({
        preferEngineBaseSalary: true,
        engineBaseSalary: 2000,
        platformSalaries: { Keeta: 5000 },
      }),
    ).toBe(2000);
  });

  it('uses platform salaries when they are present', () => {
    expect(
      getDisplayedBaseSalary({
        preferEngineBaseSalary: false,
        platformSalaries: { Keeta: 1200, Talabat: 1710 },
        engineBaseSalary: 0,
      }),
    ).toBe(2910);
  });

  it('falls back to the editable manual base salary when platform salaries are zero', () => {
    expect(
      getDisplayedBaseSalary({
        preferEngineBaseSalary: false,
        platformSalaries: { Keeta: 0, Talabat: 0 },
        engineBaseSalary: 1800,
      }),
    ).toBe(1800);
  });
});

describe('getPrimaryPlatformActivityCount', () => {
  it('returns 0 for missing metric', () => {
    expect(getPrimaryPlatformActivityCount(null)).toBe(0);
  });

  it('returns shiftDays for shift workType', () => {
    expect(getPrimaryPlatformActivityCount({ workType: 'shift', shiftDays: 5, ordersCount: 10 } as any)).toBe(5);
  });

  it('returns shiftDays for hybrid if ordersCount is 0', () => {
    expect(getPrimaryPlatformActivityCount({ workType: 'hybrid', shiftDays: 5, ordersCount: 0 } as any)).toBe(5);
  });

  it('returns ordersCount for hybrid if > 0', () => {
    expect(getPrimaryPlatformActivityCount({ workType: 'hybrid', shiftDays: 5, ordersCount: 10 } as any)).toBe(10);
  });

  it('returns ordersCount for orders workType', () => {
    expect(getPrimaryPlatformActivityCount({ workType: 'orders', shiftDays: 5, ordersCount: 10 } as any)).toBe(10);
  });
});

describe('getPlatformActivitySummary', () => {
  it('returns dash for missing metric', () => {
    expect(getPlatformActivitySummary(null)).toBe('—');
  });

  it('formats shift workType correctly', () => {
    expect(getPlatformActivitySummary({ workType: 'shift', shiftDays: 5 } as any)).toBe('5 دوام');
    expect(getPlatformActivitySummary({ workType: 'shift', shiftDays: 0 } as any)).toBe('—');
  });

  it('formats hybrid workType correctly', () => {
    expect(getPlatformActivitySummary({ workType: 'hybrid', shiftDays: 5, ordersCount: 10 } as any)).toBe('5 دوام + 10 طلب');
    expect(getPlatformActivitySummary({ workType: 'hybrid', shiftDays: 5, ordersCount: 0 } as any)).toBe('5 دوام');
    expect(getPlatformActivitySummary({ workType: 'hybrid', shiftDays: 0, ordersCount: 0 } as any)).toBe('—');
  });

  it('formats orders workType correctly', () => {
    expect(getPlatformActivitySummary({ workType: 'orders', ordersCount: 10 } as any)).toBe('10 طلب');
    expect(getPlatformActivitySummary({ workType: 'orders', ordersCount: 0 } as any)).toBe('—');
  });
});

describe('getSalaryRowActivityTotals', () => {
  it('keeps order totals separate from shift days', () => {
    expect(
      getSalaryRowActivityTotals({
        platformMetrics: {
          Keeta: {
            appName: 'Keeta',
            workType: 'orders',
            ordersCount: 7211,
            shiftDays: 0,
            salary: 0,
          },
          Hunger: {
            appName: 'Hunger',
            workType: 'hybrid',
            ordersCount: 9572,
            shiftDays: 1794,
            salary: 0,
          },
        },
      }),
    ).toEqual({
      orders: 16783,
      shiftDays: 1794,
    });
  });
  
  it('returns 0 for no metrics', () => {
    expect(getSalaryRowActivityTotals({})).toEqual({
      orders: 0,
      shiftDays: 0,
    });
  });
});

describe('getPlatformActivityCompactSummary', () => {
  it('returns dash for missing metric', () => {
    expect(getPlatformActivityCompactSummary(null)).toBe('—');
  });

  it('formats shift workType correctly', () => {
    expect(getPlatformActivityCompactSummary({ workType: 'shift', shiftDays: 5 } as any)).toBe('5 د');
    expect(getPlatformActivityCompactSummary({ workType: 'shift', shiftDays: 0 } as any)).toBe('—');
  });

  it('formats hybrid workType correctly', () => {
    expect(getPlatformActivityCompactSummary({ workType: 'hybrid', shiftDays: 5, ordersCount: 10 } as any)).toBe('5 د + 10 ط');
    expect(getPlatformActivityCompactSummary({ workType: 'hybrid', shiftDays: 5, ordersCount: 0 } as any)).toBe('5 د');
    expect(getPlatformActivityCompactSummary({ workType: 'hybrid', shiftDays: 0, ordersCount: 0, salary: 1 } as any)).toBe('مختلط');
    expect(getPlatformActivityCompactSummary({ workType: 'hybrid', shiftDays: 0, ordersCount: 0, salary: 0 } as any)).toBe('—');
  });

  it('formats orders workType correctly', () => {
    expect(getPlatformActivityCompactSummary({ workType: 'orders', ordersCount: 10 } as any)).toBe('10 ط');
    expect(getPlatformActivityCompactSummary({ workType: 'orders', ordersCount: 0 } as any)).toBe('—');
  });
});

describe('getSalaryRowActivitySummary', () => {
  it('formats summary for hybrid correctly', () => {
    expect(getSalaryRowActivitySummary({
      platformMetrics: {
        A: { shiftDays: 5, ordersCount: 0 } as any,
        B: { shiftDays: 0, ordersCount: 10 } as any,
      }
    })).toBe('10 طلب + 5 دوام');
  });
  
  it('formats summary for shift correctly', () => {
    expect(getSalaryRowActivitySummary({
      platformMetrics: {
        A: { shiftDays: 5, ordersCount: 0 } as any,
      }
    })).toBe('5 دوام');
  });

  it('formats summary for orders correctly', () => {
    expect(getSalaryRowActivitySummary({
      platformMetrics: {
        A: { shiftDays: 0, ordersCount: 10 } as any,
      }
    })).toBe('10 طلب');
  });

  it('returns dash for no activity', () => {
    expect(getSalaryRowActivitySummary({
      platformMetrics: {
        A: { shiftDays: 0, ordersCount: 0 } as any,
      }
    })).toBe('—');
  });
});

