import { supabase } from '@services/supabase/client';
import { sanitizeStoragePath } from '@shared/lib/storagePath';
import { toServiceError } from '@services/serviceError';

export const storageService = {
  sanitizePathOrThrow: (path: string) => {
    const safePath = sanitizeStoragePath(path);

    if (!safePath) {
      throw toServiceError(new Error('Invalid storage path'), 'storageService.sanitizePathOrThrow.invalid');
    }

    if (safePath.includes('..') || safePath.startsWith('/') || !/^[A-Za-z0-9/_\-.]+$/.test(safePath)) {
      throw toServiceError(new Error('Unsafe storage path'), 'storageService.sanitizePathOrThrow.unsafe');
    }

    return safePath;
  },

  createSignedUrl: async (bucket: string, path: string, expiresInSeconds = 300) => {
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(bucket).createSignedUrl(safePath, expiresInSeconds);

    if (error) {
      throw toServiceError(error, 'storageService.createSignedUrl');
    }

    return data.signedUrl;
  },

  createSignedDownloadUrl: async (bucket: string, path: string, expiresInSeconds = 300) => {
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(bucket).createSignedUrl(safePath, expiresInSeconds, { download: true });

    if (error) {
      throw toServiceError(error, 'storageService.createSignedDownloadUrl');
    }

    return data.signedUrl;
  },

  uploadFile: async (bucket: string, path: string, file: File, options?: { upsert?: boolean }) => {
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(bucket).upload(safePath, file, {
      cacheControl: '3600',
      upsert: options?.upsert ?? false,
    });

    if (error) {
      throw toServiceError(error, 'storageService.uploadFile');
    }

    return data.path;
  },
};
