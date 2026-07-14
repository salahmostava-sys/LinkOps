import { useEffect, useRef } from 'react';
import { realtimeService, type RealtimeTableChange } from '@services/realtimeService';

type RealtimeSubscriptionOptions = {
  debounceMs?: number;
  shouldHandle?: (change: RealtimeTableChange) => boolean;
};

/** Tables backing Dashboard KPIs + analytics (invalidate on change; read-heavy). */
export const REALTIME_TABLES_DASHBOARD = [
  'employees',
  'attendance',
  'daily_orders',
  'vehicles',
  'alerts',
  'apps',
  'app_targets',
] as const;

/** Tables that can change the employee list or app labels shown inside it. */
export const REALTIME_TABLES_EMPLOYEES = [
  'employees',
  'apps',
] as const;

/** Subscribe to postgres_changes on the given tables; cleanup on unmount. */
export function useRealtimePostgresChanges(
  channelName: string,
  tables: readonly string[],
  onEvent: (change: RealtimeTableChange) => void,
  options: RealtimeSubscriptionOptions = {},
): void {
  const onEventRef = useRef(onEvent);
  onEventRef.current = onEvent;

  const timeoutRef = useRef<NodeJS.Timeout | null>(null);
  const latestChangeRef = useRef<RealtimeTableChange | null>(null);
  const tablesKey = tables.join('\0');
  const debounceMs = options.debounceMs ?? 2000;
  const shouldHandleRef = useRef(options.shouldHandle);
  shouldHandleRef.current = options.shouldHandle;

  useEffect(() => {
    if (tables.length === 0) return;

    const debouncedEvent = (change: RealtimeTableChange) => {
      if (shouldHandleRef.current && !shouldHandleRef.current(change)) return;
      latestChangeRef.current = change;
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      timeoutRef.current = setTimeout(() => {
        if (latestChangeRef.current) onEventRef.current(latestChangeRef.current);
      }, debounceMs);
    };

    const unsubscribe = realtimeService.subscribeToTables(channelName, tables, debouncedEvent);

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      unsubscribe();
    };
  }, [channelName, tables, tablesKey, debounceMs]);
}
