import { loadXlsx } from '@modules/orders/utils/xlsx';
import type { PerformanceDashboardResponse } from '@services/performanceService';

type ReportRow = Record<string, string | number>;

function summaryRows(report: PerformanceDashboardResponse): ReportRow[] {
  return [
    { المؤشر: 'إجمالي الطلبات', القيمة: report.summary.totalOrders },
    { المؤشر: 'المناديب النشطون', القيمة: report.summary.activeRiders },
    { المؤشر: 'متوسط الطلبات للمندوب', القيمة: report.summary.avgOrdersPerRider },
    { المؤشر: 'المستهدف', القيمة: report.targets.totalTargetOrders },
    { المؤشر: 'نسبة تحقيق المستهدف', القيمة: `${report.targets.targetAchievementPct.toFixed(1)}%` },
    { المؤشر: 'النمو عن الشهر السابق', القيمة: `${report.comparison.month.growthPct.toFixed(1)}%` },
  ];
}

function platformRows(report: PerformanceDashboardResponse): ReportRow[] {
  return report.ordersByApp.map((app) => ({
    المنصة: app.appName,
    الطلبات: app.orders,
    المناديب: app.riders,
    المستهدف: app.targetOrders,
    'تحقيق المستهدف': `${app.targetAchievementPct.toFixed(1)}%`,
    النمو: `${app.growthPct.toFixed(1)}%`,
  }));
}

function rankingRows(report: PerformanceDashboardResponse): ReportRow[] {
  return report.rankings.topPerformers.map((rider) => ({
    الترتيب: rider.rank,
    المندوب: rider.employeeName,
    المدينة: rider.city ?? 'غير محدد',
    الطلبات: rider.totalOrders,
    'متوسط يومي': rider.avgOrdersPerDay,
    'تحقيق المستهدف': `${rider.targetAchievementPct.toFixed(1)}%`,
    النمو: `${rider.growthPct.toFixed(1)}%`,
  }));
}

function alertRows(report: PerformanceDashboardResponse): ReportRow[] {
  return report.alerts.map((alert) => ({
    المندوب: alert.employeeName ?? 'عام',
    النوع: alert.alertType,
    الأولوية: alert.severity,
    الطلبات: alert.totalOrders ?? 0,
    'نسبة المستهدف': `${(alert.targetAchievementPct ?? 0).toFixed(1)}%`,
  }));
}

export async function exportExecutivePerformanceReport(
  report: PerformanceDashboardResponse,
  projectName: string,
) {
  const XLSX = await loadXlsx();
  const workbook = XLSX.utils.book_new();
  const sheets: Array<[string, ReportRow[]]> = [
    ['الملخص', [{ المؤشر: 'المنشأة', القيمة: projectName }, { المؤشر: 'الشهر', القيمة: report.monthYear }, ...summaryRows(report)]],
    ['المنصات', platformRows(report)],
    ['المراكز', rankingRows(report)],
    ['التنبيهات', alertRows(report)],
  ];
  sheets.forEach(([name, rows]) => {
    XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(rows), name);
  });
  XLSX.writeFile(workbook, `التقرير_التنفيذي_${report.monthYear}.xlsx`);
}
