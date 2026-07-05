import { Link } from 'react-router-dom';
import { Medal, TrendingUp } from 'lucide-react';

import { useTemporalContext } from '@app/providers/TemporalContext';
import {
  DashboardBreadcrumbTitle,
  SelectedMonthBadge,
  dashboardTabButtonClass,
} from '@modules/dashboard/components/DashboardHeaderShared';

export type DashboardTabKey = 'overview' | 'analytics' | 'ranking';

const DASHBOARD_SHORTCUTS = [
  { to: '/orders', label: 'الطلبات' },
  { to: '/attendance', label: 'الحضور' },
  { to: '/alerts', label: 'التنبيهات' },
  { to: '/fuel', label: 'الوقود' },
] as const;

type DashboardHeaderProps = {
  activeTab: DashboardTabKey;
  onTabChange: (tab: DashboardTabKey) => void;
  onAnalyticsIntent?: () => void;
};

export function DashboardHeader({
  activeTab,
  onTabChange,
  onAnalyticsIntent,
}: Readonly<DashboardHeaderProps>) {
  const { selectedMonth } = useTemporalContext();

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <DashboardBreadcrumbTitle />

        <div className="flex items-center bg-muted rounded-xl p-1 gap-1 overflow-x-auto">
          {(['overview', 'analytics', 'ranking'] as const).map((tab) => {
            const isAnalyticsTab = tab === 'analytics';
            const isRankingTab = tab === 'ranking';

            const tabLabels = {
              overview: 'النظرة العامة',
              analytics: 'التحليلات والتوقعات',
              ranking: 'التصنيفات',
            };
            const tabLabel = tabLabels[tab];

            return (
              <button
                key={tab}
                type="button"
                onClick={() => onTabChange(tab)}
                onFocus={isAnalyticsTab || isRankingTab ? onAnalyticsIntent : undefined}
                onMouseEnter={isAnalyticsTab || isRankingTab ? onAnalyticsIntent : undefined}
                onTouchStart={isAnalyticsTab || isRankingTab ? onAnalyticsIntent : undefined}
                className={dashboardTabButtonClass(activeTab === tab)}
              >
                {isAnalyticsTab && <TrendingUp size={13} />}
                {isRankingTab && <Medal size={13} />}
                {tabLabel}
              </button>
            );
          })}
        </div>
      </div>

      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between sm:gap-4">
        <SelectedMonthBadge selectedMonth={selectedMonth} />

        <nav className="flex flex-wrap items-center gap-2" aria-label="اختصارات تشغيلية">
          {DASHBOARD_SHORTCUTS.map((shortcut) => (
            <Link
              key={shortcut.to}
              to={shortcut.to}
              className="border border-border/70 bg-card px-3 py-1.5 text-xs font-semibold text-foreground shadow-sm transition-colors hover:bg-muted/60 rounded-2xl"
            >
              {shortcut.label}
            </Link>
          ))}
        </nav>
      </div>
    </div>
  );
}
