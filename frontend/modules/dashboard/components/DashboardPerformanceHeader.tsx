import { Calendar, LayoutDashboard, LayoutGrid, Medal, TrendingUp } from 'lucide-react';
import { format } from 'date-fns';
import { ar } from 'date-fns/locale';

import { useTemporalContext } from '@app/providers/TemporalContext';
import { cn } from '@shared/lib/utils';

export type DashboardPerformanceTabKey = 'overview' | 'analytics' | 'ranking' | 'platforms';

type DashboardPerformanceHeaderProps = {
  activeTab: DashboardPerformanceTabKey;
  onTabChange: (tab: DashboardPerformanceTabKey) => void;
  onPrefetchIntent?: () => void;
};

const TAB_LABELS: Record<DashboardPerformanceTabKey, string> = {
  overview: 'النظرة العامة',
  analytics: 'التحليلات',
  ranking: 'التصنيف',
  platforms: 'المنصات',
};

export function DashboardPerformanceHeader({
  activeTab,
  onTabChange,
  onPrefetchIntent,
}: Readonly<DashboardPerformanceHeaderProps>) {
  const { selectedMonth } = useTemporalContext();

  return (
    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-surface border-b border-border px-6 py-4 sticky top-0 z-10 shadow-sm -mx-4 lg:-mx-6 -mt-4 lg:-mt-6 mb-6">
      <div>
        <div className="text-lg font-extrabold text-foreground">{TAB_LABELS[activeTab]}</div>
        <div className="text-xs text-muted-foreground mt-0.5">
          {format(new Date(), 'EEEE، d MMMM yyyy', { locale: ar })}
        </div>
      </div>

      <div className="flex-1 flex items-center justify-center">
        <div className="flex items-center bg-secondary rounded-xl p-1 gap-1 border border-border">
          {(['overview', 'analytics', 'ranking', 'platforms'] as const).map((tab) => (
            <button
              key={tab}
              type="button"
              onClick={() => onTabChange(tab)}
              onFocus={tab === 'overview' ? undefined : onPrefetchIntent}
              onMouseEnter={tab === 'overview' ? undefined : onPrefetchIntent}
              onTouchStart={tab === 'overview' ? undefined : onPrefetchIntent}
              className={cn(
                'px-4 py-1.5 rounded-lg text-sm font-semibold transition-all flex items-center gap-1.5 whitespace-nowrap',
                activeTab === tab
                  ? 'bg-card text-primary shadow-sm ring-1 ring-border'
                  : 'text-muted-foreground hover:text-foreground',
              )}
            >
              {tab === 'overview' ? <LayoutDashboard size={14} /> : null}
              {tab === 'analytics' ? <TrendingUp size={14} /> : null}
              {tab === 'ranking' ? <Medal size={14} /> : null}
              {tab === 'platforms' ? <LayoutGrid size={14} /> : null}
              {TAB_LABELS[tab]}
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 bg-secondary border border-border rounded-lg px-4 py-1.5 text-sm font-bold text-foreground cursor-pointer hover:border-primary transition-colors">
          <Calendar size={14} className="text-muted-foreground" />
          {format(new Date(`${selectedMonth}-01`), 'MMMM yyyy', { locale: ar })}
        </div>
      </div>
    </div>
  );
}
