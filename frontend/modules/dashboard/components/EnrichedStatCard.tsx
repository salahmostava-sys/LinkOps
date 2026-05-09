/**
 * EnrichedStatCard — Stat card that displays a value WITH its comparison delta.
 */

import type { LucideIcon } from 'lucide-react';
import {
  type ComparisonResult,
  type PerformanceTier,
  tierColorClass,
  tierBgClass,
} from '@modules/dashboard/lib/performanceEngine';
import { cn } from '@shared/lib/utils';

interface EnrichedStatCardProps {
  label: string;
  value: string;
  delta?: ComparisonResult | null;
  sub?: string;
  icon: LucideIcon;
  tier?: PerformanceTier | null;
}

const tierDecorationBg: Record<PerformanceTier, string> = {
  excellent: 'rgba(16, 185, 129, 0.08)',
  good: 'rgba(59, 130, 246, 0.08)',
  average: 'rgba(245, 158, 11, 0.08)',
  weak: 'rgba(239, 68, 68, 0.08)',
};

export function EnrichedStatCard({
  label,
  value,
  delta,
  sub,
  icon: Icon,
  tier,
}: Readonly<EnrichedStatCardProps>) {
  const iconBg = tier ? tierBgClass(tier) : 'bg-muted/40';
  const iconColor = tier ? tierColorClass(tier) : 'text-foreground';
  const decorationBg = tier ? tierDecorationBg[tier] : 'rgba(21, 101, 192, 0.06)';

  let deltaClass = 'text-muted-foreground';
  if (delta?.direction === '↑') deltaClass = 'text-emerald-600';
  else if (delta?.direction === '↓') deltaClass = 'text-rose-500';

  return (
    <div
      className="bg-card border border-border rounded-2xl p-5 shadow-sm hover:shadow-md transition-all duration-200 cursor-default relative overflow-hidden group hover:-translate-y-0.5"
    >
      {/* Decorative background circle */}
      <div 
        className="absolute bottom-0 right-0 w-24 h-24 rounded-full translate-x-6 translate-y-6 pointer-events-none transition-transform duration-300 group-hover:scale-110"
        style={{ background: decorationBg }}
      />

      <div className="flex items-center justify-between mb-4 relative z-10">
        <div className="text-xs font-semibold text-muted-foreground">{label}</div>
        <div
          className={cn(
            'w-10 h-10 rounded-xl flex items-center justify-center transition-transform duration-200 group-hover:scale-105 shadow-sm',
            iconBg,
            iconColor
          )}
        >
          <Icon size={18} />
        </div>
      </div>

      <div className="relative z-10">
        <p className={cn('text-3xl font-extrabold leading-none mb-2.5', iconColor)}>{value}</p>
        
        {delta ? (
          <div className={cn('text-[11px] font-bold flex items-center gap-1.5', deltaClass)}>
            <span>{delta.formattedDelta}</span>
            <span className="opacity-70 font-medium">مقارنة بالشهر الماضي</span>
          </div>
        ) : sub ? (
          <div className="text-[11px] text-muted-foreground font-medium">{sub}</div>
        ) : null}
      </div>
    </div>
  );
}
