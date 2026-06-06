import { describe, it, expect } from 'vitest';
import {
  validateUploadFile,
  validatePhoneNumber,
  validateEmail,
  validateNationalID,
  isUuid,
  isValidMonth,
  isValidDate,
} from '@shared/lib/validation';

describe('validation', () => {
  describe('validateUploadFile', () => {
    it('should accept valid file types', () => {
      const file = new File(['content'], 'test.pdf', { type: 'application/pdf' });
      const result = validateUploadFile(file);
      expect(result.valid).toBe(true);
    });

    it('should reject invalid file types', () => {
      const file = new File(['content'], 'test.exe', { type: 'application/x-msdownload' });
      const result = validateUploadFile(file);
      expect(result.valid).toBe(false);
      expect(result.error).toBe('غير مسموح بهذا النوع');
    });

    it('should reject files exceeding max size', () => {
      const file = new File(['a'], 'large.pdf', { type: 'application/pdf' });
      Object.defineProperty(file, 'size', { value: 6 * 1024 * 1024 });
      const result = validateUploadFile(file);
      expect(result.valid).toBe(false);
      expect(result.error).toBe('الملف كبير جدًا');
    });

    it('should accept custom allowed types', () => {
      const file = new File(['content'], 'test.txt', { type: 'text/plain' });
      const result = validateUploadFile(file, { allowedTypes: ['text/plain'] });
      expect(result.valid).toBe(true);
    });

    it('should accept custom max size', () => {
      const content = new Array(2 * 1024 * 1024).fill('a').join('');
      const file = new File([content], 'test.pdf', { type: 'application/pdf' });
      const result = validateUploadFile(file, { maxSizeBytes: 1024 * 1024 });
      expect(result.valid).toBe(false);
    });
  });

  describe('validatePhoneNumber', () => {
    it('should accept valid phone numbers', () => {
      expect(validatePhoneNumber('(050) 123-4567')).toBe(true);
      expect(validatePhoneNumber('(055) 987-6543')).toBe(true);
    });

    it('should reject invalid length', () => {
      expect(validatePhoneNumber('(050) 123-456')).toBe(false);
      expect(validatePhoneNumber('(050) 123-45678')).toBe(false);
    });

    it('should reject invalid format', () => {
      expect(validatePhoneNumber('050-123-4567')).toBe(false);
      expect(validatePhoneNumber('(050)123-4567')).toBe(false);
      expect(validatePhoneNumber('(050) 1234567')).toBe(false);
    });

    it('should reject non-numeric characters', () => {
      expect(validatePhoneNumber('(05a) 123-4567')).toBe(false);
      expect(validatePhoneNumber('(050) 12b-4567')).toBe(false);
    });
  });

  describe('validateEmail', () => {
    it('should accept valid emails', () => {
      expect(validateEmail('test@example.com')).toBe(true);
      expect(validateEmail('user.name@domain.co.uk')).toBe(true);
      expect(validateEmail('test+tag@example.com')).toBe(true);
    });

    it('should reject empty or whitespace', () => {
      expect(validateEmail('')).toBe(false);
      expect(validateEmail('   ')).toBe(false);
    });

    it('should reject missing @', () => {
      expect(validateEmail('testexample.com')).toBe(false);
    });

    it('should reject multiple @', () => {
      expect(validateEmail('test@@example.com')).toBe(false);
      expect(validateEmail('test@ex@ample.com')).toBe(false);
    });

    it('should reject missing local or domain', () => {
      expect(validateEmail('@example.com')).toBe(false);
      expect(validateEmail('test@')).toBe(false);
    });

    it('should reject spaces', () => {
      expect(validateEmail('test @example.com')).toBe(false);
      expect(validateEmail('test@exam ple.com')).toBe(false);
    });

    it('should reject invalid domain', () => {
      expect(validateEmail('test@.example.com')).toBe(false);
      expect(validateEmail('test@example.com.')).toBe(false);
      expect(validateEmail('test@example')).toBe(false);
    });
  });

  describe('validateNationalID', () => {
    it('should accept valid national IDs', () => {
      expect(validateNationalID('1234-5678')).toBe(true);
      expect(validateNationalID('9876-5432')).toBe(true);
    });

    it('should reject invalid length', () => {
      expect(validateNationalID('123-5678')).toBe(false);
      expect(validateNationalID('12345-5678')).toBe(false);
    });

    it('should reject missing dash', () => {
      expect(validateNationalID('12345678')).toBe(false);
    });

    it('should reject wrong dash position', () => {
      expect(validateNationalID('123-45678')).toBe(false);
      expect(validateNationalID('12345-678')).toBe(false);
    });

    it('should reject non-numeric characters', () => {
      expect(validateNationalID('123a-5678')).toBe(false);
      expect(validateNationalID('1234-567b')).toBe(false);
    });
  });

  describe('isUuid', () => {
    it('should accept valid UUIDs', () => {
      expect(isUuid('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
      expect(isUuid('6ba7b810-9dad-11d1-80b4-00c04fd430c8')).toBe(true);
      expect(isUuid('6ba7b811-9dad-21d1-80b4-00c04fd430c8')).toBe(true);
    });

    it('should reject invalid format', () => {
      expect(isUuid('550e8400-e29b-41d4-a716')).toBe(false);
      expect(isUuid('550e8400e29b41d4a716446655440000')).toBe(false);
      expect(isUuid('not-a-uuid')).toBe(false);
    });

    it('should reject invalid version', () => {
      expect(isUuid('550e8400-e29b-01d4-a716-446655440000')).toBe(false);
      expect(isUuid('550e8400-e29b-61d4-a716-446655440000')).toBe(false);
    });

    it('should reject invalid variant', () => {
      expect(isUuid('550e8400-e29b-41d4-0716-446655440000')).toBe(false);
      expect(isUuid('550e8400-e29b-41d4-f716-446655440000')).toBe(false);
    });

    it('should be case insensitive', () => {
      expect(isUuid('550E8400-E29B-41D4-A716-446655440000')).toBe(true);
    });
  });

  describe('isValidMonth', () => {
    it('should accept valid months', () => {
      expect(isValidMonth('2024-01')).toBe(true);
      expect(isValidMonth('2024-12')).toBe(true);
      expect(isValidMonth('2023-06')).toBe(true);
    });

    it('should reject invalid month numbers', () => {
      expect(isValidMonth('2024-00')).toBe(false);
      expect(isValidMonth('2024-13')).toBe(false);
    });

    it('should reject invalid format', () => {
      expect(isValidMonth('2024-1')).toBe(false);
      expect(isValidMonth('24-01')).toBe(false);
      expect(isValidMonth('2024/01')).toBe(false);
    });
  });

  describe('isValidDate', () => {
    it('should accept valid dates', () => {
      expect(isValidDate('2024-01-01')).toBe(true);
      expect(isValidDate('2024-12-31')).toBe(true);
      expect(isValidDate('2023-06-15')).toBe(true);
    });

    it('should reject invalid day numbers', () => {
      expect(isValidDate('2024-01-00')).toBe(false);
      expect(isValidDate('2024-01-32')).toBe(false);
    });

    it('should reject invalid format', () => {
      expect(isValidDate('2024-1-1')).toBe(false);
      expect(isValidDate('24-01-01')).toBe(false);
      expect(isValidDate('2024/01/01')).toBe(false);
    });
  });
});
