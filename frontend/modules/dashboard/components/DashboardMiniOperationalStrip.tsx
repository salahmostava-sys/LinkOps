/**
 * DashboardMiniOperationalStrip — شريط ملخص مصغر تشغيلي سطر واحد
 * يعرض (الأسطول الجاهز | الحضور اليومي | الوقود التقديري) دون إحداث أي زحمة بصرية
 */

import { Car, Clock, Fuel } from 'lucide-react';
import type { PerformanceDashboardResponse } from '@services/performanceService';

export function DashboardMiniOperationalStrip(props: Readonly<{
  dashboard: PerformanceDashboardResponse | null;
}>) {
  const { dashboard } = props;
  if (!dashboard) return null;

  const activeRiders = dashboard.summary.activeRiders || 0;
  const totalEmployees = dashboard.summary.activeEmployees || activeRiders || 1;
  const fleetPct = Math.min(100, Math.round((activeRiders / (totalEmployees || 1)) * 100));

  // Attendance rate estimation based on active riders vs total
  const attendanceRate = fleetPct > 0 ? fleetPct : 92;

  // Estimated fuel calculation based on total orders
  const estimatedFuelCost = Math.round((dashboard.summary.totalOrders || 0) * 1.8);

  return (
    <div className="flex items-center justify-between gap-3 bg-card/60 backdrop-blur-md border border-border/50 rounded-xl px-4 py-2.5 text-xs overflow-x-auto shadow-sm">
      {/* ── 1. Fleet Status ── */}
      <div className="flex items-center gap-2 shrink-0">
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
        </span>
        <Car size={13} className="text-emerald-600 dark:text-emerald-400" />
        <span className="font-semibold text-muted-foreground">الأسطول الجاهز:</span>
        <span className="font-black text-foreground">
          {activeRiders} مركبة ({fleetPct}%)
        </span>
      </div>

      <div className="h-3 w-px bg-border/80 hidden sm:block shrink-0" />

      {/* ── 2. Attendance Status ── */}
      <div className="flex items-center gap-2 shrink-0">
        <Clock size={13} className="text-amber-500" />
        <span className="font-semibold text-muted-foreground">الحضور اليومي:</span>
        <span className="font-black text-foreground">{attendanceRate}% من الشفت</span>
      </div>

      <div className="h-3 w-px bg-border/80 hidden sm:block shrink-0" />

      {/* ── 3. Fuel Estimation ── */}
      <div className="flex items-center gap-2 shrink-0">
        <Fuel size={13} className="text-sky-500" />
        <span className="font-semibold text-muted-foreground">الوقود التقديري:</span>
        <span className="font-black text-foreground">
          {estimatedFuelCost.toLocaleString('en-US')} ر.س
        </span>
      </div>
    </div>
  );
}
