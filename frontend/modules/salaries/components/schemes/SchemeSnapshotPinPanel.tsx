import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@shared/components/ui/select';
import { Button } from '@shared/components/ui/button';
import { Pin, Lock, Loader2 } from 'lucide-react';
import { cn } from '@shared/lib/utils';
import { TierType, Tier } from '../types/scheme.ui.types';

export const arabicMonths: Record<string, string> = {
  '01': 'يناير', '02': 'فبراير', '03': 'مارس', '04': 'أبريل',
  '05': 'مايو', '06': 'يونيو', '07': 'يوليو', '08': 'أغسطس',
  '09': 'سبتمبر', '10': 'أكتوبر', '11': 'نوفمبر', '12': 'ديسمبر',
};
export const monthLabel = (my: string) => {
  const [yr, mo] = my.split('-');
  return `${arabicMonths[mo] || mo} ${yr}`;
};

export const monthNameOnly = (my: string) => {
  const mo = my.split('-')[1];
  return arabicMonths[mo] || my;
};

export const buildMonthsOfYear = (year: number) =>
  Array.from({ length: 12 }, (_, i) => `${year}-${String(i + 1).padStart(2, '0')}`);

/** نطاق السنوات الثابت في واجهة تثبيت الشهور */
export const SNAPSHOT_YEAR_MIN = 2025;
export const SNAPSHOT_YEAR_MAX = 2030;

export const snapshotYearOptions = (): number[] =>
  Array.from({ length: SNAPSHOT_YEAR_MAX - SNAPSHOT_YEAR_MIN + 1 }, (_, i) => SNAPSHOT_YEAR_MIN + i);

export const clampSnapshotYear = (y: number) =>
  Math.min(SNAPSHOT_YEAR_MAX, Math.max(SNAPSHOT_YEAR_MIN, y));

export const tierTypeLabels: Record<TierType, string> = {
  total_multiplier: 'تراكمي (نطاق × سعر)',
  per_order_band: 'شريحة واحدة (الكل × سعر)',
  fixed_amount: 'مبلغ ثابت',
  base_plus_incremental: 'أساس + زيادي',
};

/** مثال: 400→1600، 401→2005، 450–470→2500، 480→2500+10×5 */
export const EXAMPLE_BAND_TIERS: Tier[] = [
  { from: 1, to: 300, pricePerOrder: 3, tierType: 'per_order_band' },
  { from: 301, to: 400, pricePerOrder: 4, tierType: 'per_order_band' },
  { from: 401, to: 449, pricePerOrder: 5, tierType: 'per_order_band' },
  { from: 450, to: 470, pricePerOrder: 2500, tierType: 'fixed_amount' },
  {
    from: 471,
    to: 99999,
    pricePerOrder: 2500,
    tierType: 'base_plus_incremental',
    incrementalThreshold: 470,
    incrementalPrice: 5,
  },
];

export function schemeSnapshotMonthTitle(pinned: boolean, selected: boolean): string {
  if (pinned) return 'مثبت — انقر لإزالة التثبيت';
  if (selected) return 'محدد للتثبيت — انقر لإلغاء التحديد';
  return 'انقر لتحديده ثم اضغط «تثبيت المحدد»';
}

export type SchemeSnapshotPinPanelProps = Readonly<{
  year: number;
  onYearChange: (year: number) => void;
  yearMonths: string[];
  selectedMonths: string[];
  pinnedMonthYears: string[];
  snapshotBusy: boolean;
  onMonthActivate: (monthYear: string, pinned: boolean) => void;
  onPinSelected: () => void;
  onClearSelection: () => void;
  totalPinnedLabelCount: number;
}>;

export function SchemeSnapshotPinPanel({
  year,
  onYearChange,
  yearMonths,
  selectedMonths,
  pinnedMonthYears,
  snapshotBusy,
  onMonthActivate,
  onPinSelected,
  onClearSelection,
  totalPinnedLabelCount,
}: SchemeSnapshotPinPanelProps) {
  const pinnedSet = new Set(pinnedMonthYears);
  const sel = selectedMonths;
  const busy = snapshotBusy;

  return (
    <div className="border-t border-border/30 pt-3 mt-2 space-y-2.5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-xs font-medium text-muted-foreground">
          تثبيت شرائح الراتب للشهور (للرواتب حسب الطلبات)
        </p>
        <div className="flex items-center gap-2 shrink-0">
          <span className="text-xs text-muted-foreground whitespace-nowrap">السنة</span>
          <Select value={String(year)} onValueChange={(v) => onYearChange(Number.parseInt(v, 10))}>
            <SelectTrigger className="h-8 w-[88px] text-xs">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {snapshotYearOptions().map((yr) => (
                <SelectItem key={yr} value={String(yr)}>
                  {yr}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="flex flex-wrap gap-1.5">
        {yearMonths.map((my) => {
          const pinned = pinnedSet.has(my);
          const selected = sel.includes(my);
          return (
            <button
              key={my}
              type="button"
              disabled={busy}
              title={schemeSnapshotMonthTitle(pinned, selected)}
              onClick={() => onMonthActivate(my, pinned)}
              className={cn(
                'inline-flex items-center justify-center gap-1 rounded-lg px-2 py-1.5 text-[11px] font-medium border transition-colors min-w-[4.25rem]',
                pinned && 'bg-primary text-primary-foreground border-primary shadow-sm hover:bg-primary/90',
                !pinned && selected && 'bg-primary/15 text-primary border-primary/40 ring-1 ring-primary/30',
                !pinned && !selected && 'bg-background text-muted-foreground border-border/70 hover:border-primary/40 hover:text-foreground',
              )}
            >
              {pinned && <Lock size={11} className="shrink-0" />}
              {!pinned && selected && <Pin size={11} className="shrink-0" />}
              <span className="whitespace-nowrap">{monthNameOnly(my)}</span>
            </button>
          );
        })}
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <Button size="sm" className="gap-1 h-8 text-xs" onClick={onPinSelected} disabled={busy || sel.length === 0}>
          {busy ? <Loader2 size={12} className="animate-spin" /> : <Pin size={12} />}
          تثبيت المحدد{sel.length > 0 ? ` (${sel.length})` : ''}
        </Button>
        {sel.length > 0 && (
          <button
            type="button"
            className="text-xs text-muted-foreground hover:text-foreground underline-offset-2 hover:underline disabled:opacity-50"
            disabled={busy}
            onClick={onClearSelection}
          >
            مسح التحديد
          </button>
        )}
        {totalPinnedLabelCount > 0 && (
          <span className="text-[10px] text-muted-foreground ms-auto">
            إجمالي {totalPinnedLabelCount} شهر مثبت عبر السنوات
          </span>
        )}
      </div>
    </div>
  );
}
