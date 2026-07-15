import type { App, DailyData, Employee } from '@modules/orders/types';

export const ALL_APPS_REPORT_ID = 'all';

export type DailyAppReportTarget = {
  app_id: string;
  target_orders: number;
  employee_target_orders?: number | null;
};

export type DailyAppReportRow = {
  empId: string;
  empName: string;
  dailyVals: number[];
  total: number;
  employeeTarget: number | null;
  remaining: number | null;
  achievementPercentage: number | null;
  projectedTotal: number | null;
  expectedToReachTarget: boolean | null;
  note: string;
};

type BuildDailyAppReportParams = {
  employees: Employee[];
  apps: App[];
  selectedAppId: string;
  data: DailyData;
  targets: DailyAppReportTarget[];
  year: number;
  month: number;
  startDay: number;
  endDay: number;
  today?: Date;
};

type ReportPeriod = Pick<BuildDailyAppReportParams, 'year' | 'month' | 'startDay' | 'endDay'> & {
  today: Date;
};

type BuildEmployeeReportRowParams = {
  employee: Employee;
  appIds: string[];
  data: DailyData;
  dayNumbers: number[];
  employeeTarget: number | null;
  elapsedDays: number;
};

const getSelectedAppIds = (apps: App[], selectedAppId: string) =>
  selectedAppId === ALL_APPS_REPORT_ID ? apps.map((app) => app.id) : [selectedAppId];

const getCombinedEmployeeTarget = (targets: DailyAppReportTarget[], appIds: string[]) => {
  const selectedTargets = targets.filter((target) => appIds.includes(target.app_id));
  const configuredTargets = selectedTargets
    .map((target) => target.employee_target_orders)
    .filter((target): target is number => target != null);
  return configuredTargets.length > 0
    ? configuredTargets.reduce((sum, target) => sum + target, 0)
    : null;
};

const getElapsedDaysInRange = ({ year, month, startDay, endDay, today }: ReportPeriod) => {
  const reportMonth = year * 12 + month;
  const currentMonth = today.getFullYear() * 12 + today.getMonth() + 1;
  if (reportMonth < currentMonth) return endDay - startDay + 1;
  if (reportMonth > currentMonth) return 0;
  return Math.max(0, Math.min(endDay, today.getDate()) - startDay + 1);
};

const getTargetProgress = (
  total: number,
  employeeTarget: number | null,
  elapsedDays: number,
  rangeDays: number,
) => {
  if (employeeTarget === null || employeeTarget <= 0) {
    return { remaining: null, achievementPercentage: null, projectedTotal: null, expectedToReachTarget: null };
  }

  const remaining = Math.max(employeeTarget - total, 0);
  const achievementPercentage = (total / employeeTarget) * 100;
  const projectedTotal = total >= employeeTarget
    ? total
    : elapsedDays > 0 ? Math.round((total / elapsedDays) * rangeDays) : null;
  const expectedToReachTarget = projectedTotal === null ? null : projectedTotal >= employeeTarget;
  return { remaining, achievementPercentage, projectedTotal, expectedToReachTarget };
};

const buildEmployeeReportRow = ({
  employee,
  appIds,
  data,
  dayNumbers,
  employeeTarget,
  elapsedDays,
}: BuildEmployeeReportRowParams): DailyAppReportRow | null => {
  const dailyVals = dayNumbers.map((day) => appIds.reduce(
    (sum, appId) => sum + (data[`${employee.id}::${appId}::${day}`] ?? 0),
    0,
  ));
  const total = dailyVals.reduce((sum, orders) => sum + orders, 0);
  if (total === 0) return null;

  return {
    empId: employee.id,
    empName: employee.name,
    dailyVals,
    total,
    employeeTarget,
    ...getTargetProgress(total, employeeTarget, elapsedDays, dayNumbers.length),
    note: '',
  };
};

export function buildDailyAppReportRows({
  employees,
  apps,
  selectedAppId,
  data,
  targets,
  year,
  month,
  startDay,
  endDay,
  today = new Date(),
}: BuildDailyAppReportParams): DailyAppReportRow[] {
  if (!selectedAppId) return [];

  const appIds = getSelectedAppIds(apps, selectedAppId);
  const employeeTarget = getCombinedEmployeeTarget(targets, appIds);
  const dayNumbers = Array.from({ length: endDay - startDay + 1 }, (_, index) => startDay + index);
  const elapsedDays = getElapsedDaysInRange({ year, month, startDay, endDay, today });

  return employees
    .map((employee) => buildEmployeeReportRow({ employee, appIds, data, dayNumbers, employeeTarget, elapsedDays }))
    .filter((row): row is DailyAppReportRow => row !== null)
    .sort((first, second) => second.total - first.total);
}

export const getDailyAppReportName = (apps: App[], selectedAppId: string) =>
  selectedAppId === ALL_APPS_REPORT_ID
    ? 'كل المنصات'
    : apps.find((app) => app.id === selectedAppId)?.name ?? 'غير معروف';
