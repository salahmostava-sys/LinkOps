import { useAlertSummary } from '@shared/hooks/useAlerts';
import { useFaviconBadge } from '@shared/hooks/useFaviconBadge';

/** Keeps the favicon badge synced through the lightweight alert summary query. */
export function AlertsFaviconBadge() {
  const { data: summary } = useAlertSummary();
  const unresolvedCount = summary?.unresolvedCount ?? 0;

  useFaviconBadge(unresolvedCount);
  return null;
}
