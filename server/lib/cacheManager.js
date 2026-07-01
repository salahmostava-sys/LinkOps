/**
 * FIX #1: Safe cache manager that prevents data leakage on serverless.
 * 
 * Problem: Module-level caches like Map() are shared between all requests
 * on the same Vercel instance. Without user/company scoping, user A could
 * receive cached data from user B.
 * 
 * Solution: Always include user_id or company_id in cache keys.
 */

const PREVIEW_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

class CacheManager {
  constructor() {
    this.cache = new Map();
  }

  /**
   * Generate a user-scoped cache key.
   * CRITICAL: Always include user_id to prevent cross-user data leakage.
   */
  _makeKey(userId, resource, identifier) {
    if (!userId) throw new Error('userId is required for cache operations');
    return `${userId}:${resource}:${identifier}`;
  }

  get(userId, resource, identifier) {
    const key = this._makeKey(userId, resource, identifier);
    const entry = this.cache.get(key);

    if (!entry) return null;

    // Check expiration
    if (Date.now() - entry.timestamp > entry.ttl) {
      this.cache.delete(key);
      return null;
    }

    return entry.value;
  }

  set(userId, resource, identifier, value, ttlMs = PREVIEW_CACHE_TTL_MS) {
    const key = this._makeKey(userId, resource, identifier);
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
      ttl: ttlMs,
    });
  }

  /**
   * Clear all cache entries for a user (e.g., on logout).
   */
  clearUserCache(userId) {
    for (const key of this.cache.keys()) {
      if (key.startsWith(`${userId}:`)) {
        this.cache.delete(key);
      }
    }
  }

  /**
   * Clear all cache (for testing or emergency cache flush).
   */
  clearAll() {
    this.cache.clear();
  }
}

module.exports = new CacheManager();
