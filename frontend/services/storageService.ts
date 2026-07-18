import { supabase } from '@services/supabase/client';
import { sanitizeStoragePath } from '@shared/lib/storagePath';
import { toServiceError } from '@services/serviceError';

const STORAGE_BUCKETS = [
  'advance-attachments',
  'employee-documents',
  'invoice-attachments',
  'vehicle-documents',
] as const;

export type StorageBucket = (typeof STORAGE_BUCKETS)[number];

function assertStorageBucket(bucket: StorageBucket): StorageBucket {
  if (!STORAGE_BUCKETS.includes(bucket)) {
    throw toServiceError(new Error('Invalid storage bucket'), 'storageService.assertStorageBucket');
  }
  return bucket;
}

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

  createSignedUrl: async (bucket: StorageBucket, path: string, expiresInSeconds = 300) => {
    const safeBucket = assertStorageBucket(bucket);
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(safeBucket).createSignedUrl(safePath, expiresInSeconds);

    if (error) {
      throw toServiceError(error, 'storageService.createSignedUrl');
    }

    return data.signedUrl;
  },

  createSignedDownloadUrl: async (bucket: StorageBucket, path: string, expiresInSeconds = 300) => {
    const safeBucket = assertStorageBucket(bucket);
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(safeBucket).createSignedUrl(safePath, expiresInSeconds, { download: true });

    if (error) {
      throw toServiceError(error, 'storageService.createSignedDownloadUrl');
    }

    return data.signedUrl;
  },

  uploadFile: async (bucket: StorageBucket, path: string, file: File, options?: { upsert?: boolean }) => {
    const safeBucket = assertStorageBucket(bucket);
    const safePath = storageService.sanitizePathOrThrow(path);
    const { data, error } = await supabase.storage.from(safeBucket).upload(safePath, file, {
      cacheControl: '3600',
      upsert: options?.upsert ?? false,
    });

    if (error) {
      throw toServiceError(error, 'storageService.uploadFile');
    }

    return data.path;
  },
};
