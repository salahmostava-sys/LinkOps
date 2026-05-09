import { describe, it, expect } from 'vitest';
import {
  normalizeArabicDigits,
  formatDate,
  formatCurrency,
  todayISO,
  formatNumber,
} from '@shared/lib/formatters';

describe('formatters', () => {
  describe('normalizeArabicDigits', () => {
    it('should convert Arabic-Indic digits to ASCII', () => {
      expect(normalizeArabicDigits('٠١٢٣٤٥٦٧٨٩')).toBe('0123456789');
    });

    it('should preserve ASCII digits', () => {
      expect(normalizeArabicDigits('0123456789')).toBe('0123456789');
    });

    it('should handle mixed content', () => {
      expect(normalizeArabicDigits('٢٠٢٤-٠١-١٥')).toBe('2024-01-15');
    });

    it('should handle empty string', () => {
      expect(normalizeArabicDigits('')).toBe('');
    });
  });

  describe('formatDate', () => {
    it('should format valid dates to YYYY-MM-DD', () => {
      const date = new Date(Date.UTC(2024, 0, 15));
      expect(formatDate(date)).toBe('2024-01-15');
    });

    it('should handle single digit months and days', () => {
      const date = new Date(Date.UTC(2024, 0, 5));
      expect(formatDate(date)).toBe('2024-01-05');
    });

    it('should return empty string for null', () => {
      expect(formatDate(null)).toBe('');
    });

    it('should return empty string for undefined', () => {
      expect(formatDate(undefined)).toBe('');
    });

    it('should return empty string for invalid date', () => {
      expect(formatDate(new Date('invalid'))).toBe('');
    });
  });

  describe('formatCurrency', () => {
    it('should format positive amounts', () => {
      expect(formatCurrency(1234.56)).toBe('$1234.56');
    });

    it('should format zero', () => {
      expect(formatCurrency(0)).toBe('$0.00');
    });

    it('should format negative amounts', () => {
      expect(formatCurrency(-500.25)).toBe('$-500.25');
    });

    it('should use custom currency symbol', () => {
      expect(formatCurrency(100, 'ر.س')).toBe('ر.س100.00');
    });

    it('should handle null', () => {
      expect(formatCurrency(null)).toBe('$0.00');
    });

    it('should handle undefined', () => {
      expect(formatCurrency(undefined)).toBe('$0.00');
    });

    it('should handle NaN', () => {
      expect(formatCurrency(Number.NaN)).toBe('$0.00');
    });

    it('should round to 2 decimal places', () => {
      expect(formatCurrency(10.999)).toBe('$11.00');
    });
  });

  describe('todayISO', () => {
    it('should return date in YYYY-MM-DD format', () => {
      const result = todayISO();
      expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it('should return current date', () => {
      const now = new Date();
      const result = todayISO();
      const [year, month, day] = result.split('-');
      expect(year).toBe(String(now.getFullYear()));
      expect(month).toBe(String(now.getMonth() + 1).padStart(2, '0'));
      expect(day).toBe(String(now.getDate()).padStart(2, '0'));
    });
  });

  describe('formatNumber', () => {
    it('should format numbers with commas', () => {
      expect(formatNumber(1234567)).toBe('1,234,567');
    });

    it('should format zero', () => {
      expect(formatNumber(0)).toBe('0');
    });

    it('should format negative numbers', () => {
      expect(formatNumber(-1234)).toBe('-1,234');
    });

    it('should format decimals', () => {
      expect(formatNumber(1234.56)).toBe('1,234.56');
    });

    it('should handle null', () => {
      expect(formatNumber(null)).toBe('0');
    });

    it('should handle undefined', () => {
      expect(formatNumber(undefined)).toBe('0');
    });

    it('should handle NaN', () => {
      expect(formatNumber(Number.NaN)).toBe('0');
    });
  });
});
