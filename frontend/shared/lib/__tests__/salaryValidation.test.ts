import { describe, it, expect } from 'vitest';
import {
  isValidSalaryMonthYear,
  isEmployeeIdUuid,
  parseSalaryAmount,
  monthYearFromParts,
} from '@shared/lib/salaryValidation';

describe('salaryValidation', () => {
  describe('isValidSalaryMonthYear', () => {
    it('should accept valid month-year format', () => {
      expect(isValidSalaryMonthYear('2024-01')).toBe(true);
      expect(isValidSalaryMonthYear('2024-12')).toBe(true);
      expect(isValidSalaryMonthYear('2023-06')).toBe(true);
    });

    it('should reject invalid months', () => {
      expect(isValidSalaryMonthYear('2024-00')).toBe(false);
      expect(isValidSalaryMonthYear('2024-13')).toBe(false);
    });

    it('should reject invalid format', () => {
      expect(isValidSalaryMonthYear('2024-1')).toBe(false);
      expect(isValidSalaryMonthYear('24-01')).toBe(false);
      expect(isValidSalaryMonthYear('2024/01')).toBe(false);
    });

    it('should reject null and undefined', () => {
      expect(isValidSalaryMonthYear(null)).toBe(false);
      expect(isValidSalaryMonthYear(undefined)).toBe(false);
    });

    it('should handle whitespace', () => {
      expect(isValidSalaryMonthYear(' 2024-01 ')).toBe(true);
    });
  });

  describe('isEmployeeIdUuid', () => {
    it('should accept valid UUIDs', () => {
      expect(isEmployeeIdUuid('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
      expect(isEmployeeIdUuid('6ba7b810-9dad-11d1-80b4-00c04fd430c8')).toBe(true);
    });

    it('should reject invalid UUIDs', () => {
      expect(isEmployeeIdUuid('not-a-uuid')).toBe(false);
      expect(isEmployeeIdUuid('550e8400-e29b-41d4-a716')).toBe(false);
    });

    it('should reject null and undefined', () => {
      expect(isEmployeeIdUuid(null)).toBe(false);
      expect(isEmployeeIdUuid(undefined)).toBe(false);
    });

    it('should reject empty string', () => {
      expect(isEmployeeIdUuid('')).toBe(false);
    });

    it('should handle whitespace', () => {
      expect(isEmployeeIdUuid(' 550e8400-e29b-41d4-a716-446655440000 ')).toBe(true);
    });
  });

  describe('parseSalaryAmount', () => {
    it('should parse numeric values', () => {
      expect(parseSalaryAmount(1234.56)).toBe(1234.56);
      expect(parseSalaryAmount(0)).toBe(0);
      expect(parseSalaryAmount(-500)).toBe(-500);
    });

    it('should parse string numbers', () => {
      expect(parseSalaryAmount('1234.56')).toBe(1234.56);
      expect(parseSalaryAmount('1000')).toBe(1000);
    });

    it('should parse numbers with commas', () => {
      expect(parseSalaryAmount('1,234.56')).toBe(1234.56);
      expect(parseSalaryAmount('1,000,000')).toBe(1000000);
    });

    it('should parse Arabic-Indic digits', () => {
      expect(parseSalaryAmount('١٢٣٤')).toBe(1234);
      expect(parseSalaryAmount('٥٠٠٠')).toBe(5000);
    });

    it('should parse mixed Arabic and commas', () => {
      expect(parseSalaryAmount('١,٢٣٤.٥٦')).toBe(1234.56);
    });

    it('should handle null and undefined', () => {
      expect(parseSalaryAmount(null)).toBe(0);
      expect(parseSalaryAmount(undefined)).toBe(0);
    });

    it('should handle empty string', () => {
      expect(parseSalaryAmount('')).toBe(0);
    });

    it('should handle invalid strings', () => {
      expect(parseSalaryAmount('abc')).toBe(0);
      expect(parseSalaryAmount('not a number')).toBe(0);
    });

    it('should handle Infinity', () => {
      expect(parseSalaryAmount(Infinity)).toBe(0);
      expect(parseSalaryAmount(-Infinity)).toBe(0);
    });
  });

  describe('monthYearFromParts', () => {
    it('should build valid month-year from numbers', () => {
      expect(monthYearFromParts(2024, 1)).toBe('2024-01');
      expect(monthYearFromParts(2024, 12)).toBe('2024-12');
    });

    it('should pad single digit months', () => {
      expect(monthYearFromParts(2024, 5)).toBe('2024-05');
    });

    it('should parse string numbers', () => {
      expect(monthYearFromParts('2024', '6')).toBe('2024-06');
    });

    it('should reject invalid months', () => {
      expect(monthYearFromParts(2024, 0)).toBeNull();
      expect(monthYearFromParts(2024, 13)).toBeNull();
    });

    it('should reject invalid years', () => {
      expect(monthYearFromParts(1999, 6)).toBeNull();
      expect(monthYearFromParts(2101, 6)).toBeNull();
    });

    it('should reject non-numeric values', () => {
      expect(monthYearFromParts('abc', 6)).toBeNull();
      expect(monthYearFromParts(2024, 'xyz')).toBeNull();
    });

    it('should handle whitespace in strings', () => {
      expect(monthYearFromParts(' 2024 ', ' 6 ')).toBe('2024-06');
    });
  });
});
