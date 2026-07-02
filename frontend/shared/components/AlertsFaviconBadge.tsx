import { useAlerts } from '@shared/hooks/useAlerts';
import { useFaviconBadge } from '@shared/hooks/useFaviconBadge';

/**
 * AlertsFaviconBadge — يحدّث أيقونة المتصفح وعنوان الصفحة بعدد التنبيهات غير المحلولة.
 *
 * يعتمد على useAlerts (نفس مصدر بيانات صفحة التنبيهات ونفس مفتاح الكاش)،
 * ويتحدث كل دقيقة تلقائياً ويعيد الجلب عند التركيز على النافذة.
 */
export function AlertsFaviconBadge() {
  const { data: alerts } = useAlerts();
  const unresolvedCount = alerts?.filter((a) => !a.resolved).length ?? 0;

  useFaviconBadge(unresolvedCount);
  return null;
}
