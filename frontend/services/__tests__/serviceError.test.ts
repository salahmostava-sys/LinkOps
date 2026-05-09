import { describe, it, expect, vi } from 'vitest';
import { ServiceError, toServiceError, throwIfError, getErrorMessage } from '@services/serviceError';

vi.mock('@shared/lib/logger', () => ({
  logError: vi.fn(),
}));

vi.mock('@sentry/react', () => ({
  captureException: vi.fn(),
}));

describe('serviceError', () => {
  describe('ServiceError', () => {
    it('should create error with message', () => {
      const error = new ServiceError('Test error');
      expect(error.message).toBe('Test error');
      expect(error.name).toBe('ServiceError');
    });

    it('should store cause', () => {
      const cause = new Error('Original error');
      const error = new ServiceError('Wrapped error', cause);
      expect(error.cause).toBe(cause);
    });
  });

  describe('toServiceError', () => {
    it('should return ServiceError as-is', () => {
      const original = new ServiceError('Test');
      const result = toServiceError(original);
      expect(result).toBe(original);
    });

    it('should wrap Error objects', () => {
      const original = new Error('Original error');
      const result = toServiceError(original);
      expect(result).toBeInstanceOf(ServiceError);
      expect(result.message).toBe('Original error');
      expect(result.cause).toBe(original);
    });

    it('should extract message from objects', () => {
      const error = { message: 'Error message' };
      const result = toServiceError(error);
      expect(result.message).toBe('Error message');
    });

    it('should use context when provided', () => {
      const result = toServiceError(null, 'test.action');
      expect(result.message).toBe('Service failure: test.action');
    });

    it('should use default message when no context', () => {
      const result = toServiceError(null);
      expect(result.message).toBe('Service failure');
    });

    it('should handle Edge Function errors', () => {
      const error = {
        message: 'Edge Function returned a non-2xx status code',
        context: { error: 'Actual error message' },
      };
      const result = toServiceError(error);
      expect(result.message).toBe('Actual error message');
    });

    it('should fallback for Edge Function without context', () => {
      const error = {
        message: 'Edge Function returned a non-2xx status code',
      };
      const result = toServiceError(error);
      expect(result.message).toBe('Edge Function returned a non-2xx status code');
    });
  });

  describe('throwIfError', () => {
    it('should throw ServiceError if error exists', () => {
      const error = new Error('Test error');
      expect(() => throwIfError(error, 'test.action')).toThrow(ServiceError);
    });

    it('should not throw if error is null', () => {
      expect(() => throwIfError(null, 'test.action')).not.toThrow();
    });

    it('should not throw if error is undefined', () => {
      expect(() => throwIfError(undefined, 'test.action')).not.toThrow();
    });
  });

  describe('getErrorMessage', () => {
    it('should extract message from ServiceError', () => {
      const error = new ServiceError('Service error message');
      expect(getErrorMessage(error)).toBe('Service error message');
    });

    it('should extract message from Error', () => {
      const error = new Error('Error message');
      expect(getErrorMessage(error)).toBe('Error message');
    });

    it('should handle string errors', () => {
      expect(getErrorMessage('String error')).toBe('String error');
    });

    it('should use fallback for unknown errors', () => {
      expect(getErrorMessage(null)).toBe('حدث خطأ غير متوقع');
      expect(getErrorMessage(undefined)).toBe('حدث خطأ غير متوقع');
      expect(getErrorMessage({})).toBe('حدث خطأ غير متوقع');
    });

    it('should use custom fallback', () => {
      expect(getErrorMessage(null, 'Custom fallback')).toBe('Custom fallback');
    });

    it('should ignore empty strings', () => {
      expect(getErrorMessage('')).toBe('حدث خطأ غير متوقع');
      expect(getErrorMessage('   ')).toBe('حدث خطأ غير متوقع');
    });
  });
});
