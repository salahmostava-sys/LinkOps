import { describe, it, expect } from 'vitest';
import {
  clampEmployeePhoneInput,
  isValidEmployeePhone,
  clampEmployeeNationalIdInput,
  isValidEmployeeNationalId,
} from '@modules/employees/model/employeeFieldValidation';

describe('employeeFieldValidation', () => {
  describe('clampEmployeePhoneInput', () => {
    it('should clamp local phone numbers', () => {
      expect(clampEmployeePhoneInput('05012345678')).toBe('0501234567');
    });

    it('should clamp international phone numbers', () => {
      expect(clampEmployeePhoneInput('96650123456789')).toBe('966501234567');
    });

    it('should remove non-digits', () => {
      expect(clampEmployeePhoneInput('050-123-4567')).toBe('0501234567');
      expect(clampEmployeePhoneInput('050 123 4567')).toBe('0501234567');
    });

    it('should handle null and undefined', () => {
      expect(clampEmployeePhoneInput(null)).toBe('');
      expect(clampEmployeePhoneInput(undefined)).toBe('');
    });

    it('should handle empty string', () => {
      expect(clampEmployeePhoneInput('')).toBe('');
    });
  });

  describe('isValidEmployeePhone', () => {
    it('should accept valid local numbers', () => {
      expect(isValidEmployeePhone('0501234567')).toBe(true);
      expect(isValidEmployeePhone('0551234567')).toBe(true);
      expect(isValidEmployeePhone('0591234567')).toBe(true);
    });

    it('should accept valid international numbers', () => {
      expect(isValidEmployeePhone('966501234567')).toBe(true);
      expect(isValidEmployeePhone('966551234567')).toBe(true);
    });

    it('should reject invalid local numbers', () => {
      expect(isValidEmployeePhone('050123456')).toBe(false);
      expect(isValidEmployeePhone('05012345678')).toBe(false);
      expect(isValidEmployeePhone('0401234567')).toBe(false);
    });

    it('should reject invalid international numbers', () => {
      expect(isValidEmployeePhone('96650123456')).toBe(false);
      expect(isValidEmployeePhone('9665012345678')).toBe(false);
      expect(isValidEmployeePhone('967501234567')).toBe(false);
    });

    it('should handle formatted input', () => {
      expect(isValidEmployeePhone('050-123-4567')).toBe(true);
      expect(isValidEmployeePhone('966 50 123 4567')).toBe(true);
    });

    it('should handle null and undefined', () => {
      expect(isValidEmployeePhone(null)).toBe(false);
      expect(isValidEmployeePhone(undefined)).toBe(false);
    });
  });

  describe('clampEmployeeNationalIdInput', () => {
    it('should clamp to 10 digits', () => {
      expect(clampEmployeeNationalIdInput('12345678901')).toBe('1234567890');
    });

    it('should remove non-digits', () => {
      expect(clampEmployeeNationalIdInput('1234-567890')).toBe('1234567890');
      expect(clampEmployeeNationalIdInput('1234 567 890')).toBe('1234567890');
    });

    it('should handle null and undefined', () => {
      expect(clampEmployeeNationalIdInput(null)).toBe('');
      expect(clampEmployeeNationalIdInput(undefined)).toBe('');
    });

    it('should handle empty string', () => {
      expect(clampEmployeeNationalIdInput('')).toBe('');
    });
  });

  describe('isValidEmployeeNationalId', () => {
    it('should accept valid IDs starting with 1', () => {
      expect(isValidEmployeeNationalId('1234567890')).toBe(true);
      expect(isValidEmployeeNationalId('1000000000')).toBe(true);
    });

    it('should accept valid IDs starting with 2', () => {
      expect(isValidEmployeeNationalId('2234567890')).toBe(true);
      expect(isValidEmployeeNationalId('2000000000')).toBe(true);
    });

    it('should reject IDs not starting with 1 or 2', () => {
      expect(isValidEmployeeNationalId('0234567890')).toBe(false);
      expect(isValidEmployeeNationalId('3234567890')).toBe(false);
      expect(isValidEmployeeNationalId('9234567890')).toBe(false);
    });

    it('should reject invalid length', () => {
      expect(isValidEmployeeNationalId('123456789')).toBe(false);
      expect(isValidEmployeeNationalId('12345678901')).toBe(false);
    });

    it('should handle formatted input', () => {
      expect(isValidEmployeeNationalId('1234-567890')).toBe(true);
      expect(isValidEmployeeNationalId('1234 567 890')).toBe(true);
    });

    it('should handle null and undefined', () => {
      expect(isValidEmployeeNationalId(null)).toBe(false);
      expect(isValidEmployeeNationalId(undefined)).toBe(false);
    });
  });
});
