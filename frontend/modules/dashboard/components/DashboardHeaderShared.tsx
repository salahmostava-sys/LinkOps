import { Calendar } from 'lucide-react';
import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { cn } from '@shared/lib/utils';

/**
 * عنوان لوحة التحكم مع مسار التنقل (breadcrumb) والتاريخ الحالي — مشترك بين
 * DashboardHeader و DashboardPerformanceHeader.
 */
export function DashboardBreadcrumbTitle() {
  return (
    <div>
      <nav className="flex items-center gap-1 text-xs text-muted-foreground/80 mb-1">
        <span>الرئيسية</span>
        <span>/</span>
        <span className="text-muted-foreground font-medium">لوحة التحكم</span>
      </nav>
      <h1 className="text-xl font-black text-foreground">لوحة التحكم</h1>
      <p className="text-xs text-muted-foreground/80 mt-0.5">
        {format(new Date(), 'EEEE، d MMMM yyyy', { locale: ar })}
      </p>
    </div>
  );
}

/** شارة تعرض الشهر المختار حالياً — مشتركة بين رأسي لوحة التحكم. */
export function SelectedMonthBadge({ selectedMonth }: Readonly<{ selectedMonth: string }>) {
  return (
    <div className="flex items-center gap-2 text-xs font-semibold text-muted-foreground bg-muted/30 px-3 py-1.5 rounded-lg border border-border/50">
      <Calendar size={14} className="text-primary/70" />
      <span>بيانات شهر:</span>
      <span className="text-foreground font-bold">
        {format(new Date(`${selectedMonth}-01`), 'MMMM yyyy', { locale: ar })}
      </span>
    </div>
  );
}

/** فئات Tailwind المشتركة لأزرار تبويبات رأس لوحة التحكم. */
export function dashboardTabButtonClass(isActive: boolean): string {
  return cn(
    'px-4 py-1.5 rounded-lg text-sm font-semibold transition-all flex items-center gap-1.5 whitespace-nowrap',
    isActive ? 'bg-card text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground/75',
  );
}
