import type { ReactNode } from 'react';
import { Activity, Calendar } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { FUEL_PAGE_MONTHS } from '@modules/fuel/lib/fuelMonthOptions';

type FuelView = 'monthly' | 'daily' | 'spreadsheet';

type FuelPageHeaderProps = {
  view: FuelView;
  onViewChange: (v: FuelView) => void;
  selectedMonth: string;
  selectedYear: string;
  toolbarEnd?: ReactNode;
  title?: string;
  subtitle?: string;
};

export function FuelPageHeader({
  selectedMonth,
  selectedYear,
  toolbarEnd,
  title,
  subtitle,
}: Readonly<FuelPageHeaderProps>) {
  const { t } = useTranslation();
  const monthLabel = FUEL_PAGE_MONTHS.find(m => m.v === selectedMonth)?.l || selectedMonth;
  const pageTitle = title || t('fuelPageTitle');
  const pageSubtitle = subtitle || t('fuelPageSubtitle');

  return (
    <div className="flex items-center justify-between flex-wrap gap-3">
      <div>
        <nav className="page-breadcrumb">
          <span>الرئيسية</span>
          <span className="page-breadcrumb-sep">/</span>
          <span>{pageTitle}</span>
        </nav>
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
            <Activity size={20} />
          </div>
          <div>
            <h1 className="text-xl font-bold text-foreground">{pageTitle}</h1>
            <p className="text-sm text-muted-foreground">{pageSubtitle}</p>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 flex-wrap">
        <div className="inline-flex items-center rounded-xl bg-muted/40 p-1 px-3 border border-border/50 text-[11px] font-bold text-muted-foreground ms-1">
          <Calendar size={13} className="me-1.5 text-primary/70" />
          <span>فترة: {monthLabel} {selectedYear}</span>
        </div>

        <div className="flex items-center gap-1">
          {toolbarEnd}
        </div>
      </div>
    </div>
  );
}
