/** بعد نشر نسخة جديدة قد يطلب المتصفح chunk قديمًا — إعادة تحميل الصفحة تجلب `index.html` وأسماء الملفات الصحيحة. */

const RELOAD_TS_KEY = '__chunk_reload_ts__';

function safeUnknownToText(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  try {
    return JSON.stringify(value);
  } catch {
    return '';
  }
}

function reasonToString(reason: unknown): string {
  if (reason instanceof Error) {
    return `${reason.message} ${reason.stack ?? ''}`;
  }
  if (reason && typeof reason === 'object' && 'message' in reason) {
    return safeUnknownToText((reason as { message?: unknown }).message);
  }
  return safeUnknownToText(reason);
}

export function isLikelyStaleChunkError(message: string): boolean {
  const m = message.toLowerCase();
  return (
    m.includes('failed to fetch dynamically imported module') ||
    m.includes('dynamically imported module') ||
    m.includes('chunkloaderror') ||
    m.includes('loading chunk') ||
    m.includes('importing a module script failed') ||
    m.includes('error loading dynamically imported module')
  );
}

export function isLikelyStaleChunkReason(reason: unknown): boolean {
  return isLikelyStaleChunkError(reasonToString(reason));
}

/**
 * يعيد تحميل الصفحة مرة واحدة خلال نافذة زمنية قصيرة لتفادي حلقة لا نهائية عند فشل دائم.
 * يعيد `true` إذا بدأ التحميل.
 */
export function reloadOnceForStaleChunk(): boolean {
  const now = Date.now();
  try {
    const last = sessionStorage.getItem(RELOAD_TS_KEY);
    if (last && now - Number(last) < 8000) {
      return false;
    }
    sessionStorage.setItem(RELOAD_TS_KEY, String(now));
  } catch {
    /* ignore */
  }
  globalThis.location.reload();
  return true;
}

/** يُستدعى بعد تمهيد الواجهة بنجاح لإزالة القفل حتى يعمل الاسترداد بعد نشر لاحق. */
export function clearStaleChunkReloadGuard(): void {
  try {
    sessionStorage.removeItem(RELOAD_TS_KEY);
  } catch {
    /* ignore */
  }
}
