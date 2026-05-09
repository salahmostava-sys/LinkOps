import { describe, it, expect } from 'vitest';
import { escapeHtml, sanitizeLikeQuery, isValidUUID } from '@shared/lib/security';

describe('security', () => {
  describe('escapeHtml', () => {
    it('should escape HTML special characters', () => {
      expect(escapeHtml('<div>test</div>')).toBe('&lt;div&gt;test&lt;/div&gt;');
    });

    it('should escape ampersands', () => {
      expect(escapeHtml('A & B')).toBe('A &amp; B');
    });

    it('should escape quotes', () => {
      expect(escapeHtml('"quoted"')).toBe('&quot;quoted&quot;');
      expect(escapeHtml("'single'")).toBe('&#39;single&#39;');
    });

    it('should handle null and undefined', () => {
      expect(escapeHtml(null)).toBe('');
      expect(escapeHtml(undefined)).toBe('');
    });

    it('should convert objects to JSON', () => {
      const result = escapeHtml({ key: 'value' });
      expect(result).toContain('key');
      expect(result).toContain('value');
    });

    it('should convert numbers', () => {
      expect(escapeHtml(123)).toBe('123');
    });

    it('should handle empty string', () => {
      expect(escapeHtml('')).toBe('');
    });
  });

  describe('sanitizeLikeQuery', () => {
    it('should escape percent signs', () => {
      expect(sanitizeLikeQuery('50%')).toBe(String.raw`50\%`);
    });

    it('should escape underscores', () => {
      expect(sanitizeLikeQuery('test_value')).toBe(String.raw`test\_value`);
    });

    it('should escape backslashes', () => {
      expect(sanitizeLikeQuery(String.raw`path\to\file`)).toBe(String.raw`path\\to\\file`);
    });

    it('should escape multiple special characters', () => {
      expect(sanitizeLikeQuery('50%_test')).toBe(String.raw`50\%\_test`);
    });

    it('should handle empty string', () => {
      expect(sanitizeLikeQuery('')).toBe('');
    });

    it('should handle normal text', () => {
      expect(sanitizeLikeQuery('normal text')).toBe('normal text');
    });
  });

  describe('isValidUUID', () => {
    it('should accept valid v4 UUIDs', () => {
      expect(isValidUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
      expect(isValidUUID('f47ac10b-58cc-4372-a567-0e02b2c3d479')).toBe(true);
    });

    it('should reject invalid format', () => {
      expect(isValidUUID('not-a-uuid')).toBe(false);
      expect(isValidUUID('550e8400-e29b-41d4-a716')).toBe(false);
    });

    it('should reject non-v4 UUIDs', () => {
      expect(isValidUUID('550e8400-e29b-11d4-a716-446655440000')).toBe(false);
      expect(isValidUUID('550e8400-e29b-51d4-a716-446655440000')).toBe(false);
    });

    it('should reject empty string', () => {
      expect(isValidUUID('')).toBe(false);
    });

    it('should be case insensitive', () => {
      expect(isValidUUID('550E8400-E29B-41D4-A716-446655440000')).toBe(true);
    });
  });
});
