import { LayoutDashboard, Medal } from 'lucide-react';

import { useTemporalContext } from '@app/providers/TemporalContext';
import {
  DashboardBreadcrumbTitle,
  SelectedMonthBadge,
  dashboardTabButtonClass,
} from '@modules/dashboard/components/DashboardHeaderShared';

export type DashboardPerformanceTabKey = 'overview_analytics' | 'ranking_platforms';

type DashboardPerformanceHeaderProps = {
  activeTab: DashboardPerformanceTabKey;
  onTabChange: (tab: DashboardPerformanceTabKey) => void;
  onPrefetchIntent?: () => void;
};

const TAB_LABELS: Record<DashboardPerformanceTabKey, string> = {
  overview_analytics: 'النظرة العامة والتحليلات',
  ranking_platforms: 'التصنيف والمنصات',
};

export function DashboardPerformanceHeader({
  activeTab,
  onTabChange,
  onPrefetchIntent,
}: Readonly<DashboardPerformanceHeaderProps>) {
  const { selectedMonth } = useTemporalContext();

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <DashboardBreadcrumbTitle />

        <div className="flex items-center bg-muted rounded-xl p-1 gap-1 overflow-x-auto">
          {(['overview_analytics', 'ranking_platforms'] as const).map((tab) => (
            <button
              key={tab}
              type="button"
              onClick={() => onTabChange(tab)}
              onFocus={tab === 'overview_analytics' ? undefined : onPrefetchIntent}
              onMouseEnter={tab === 'overview_analytics' ? undefined : onPrefetchIntent}
              onTouchStart={tab === 'overview_analytics' ? undefined : onPrefetchIntent}
              className={dashboardTabButtonClass(activeTab === tab)}
            >
              {tab === 'overview_analytics' ? <LayoutDashboard size={13} /> : null}
              {tab === 'ranking_platforms' ? <Medal size={13} /> : null}
              {TAB_LABELS[tab]}
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between sm:gap-4">
        <SelectedMonthBadge selectedMonth={selectedMonth} />
      </div>
    </div>
  );
}
