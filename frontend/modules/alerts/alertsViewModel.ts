import type { Alert } from '@shared/lib/alertsBuilder';
import type { AlertWorkflowTarget } from '@services/alertsService';

export const alertTypeLabels: Record<string, string> = {
  residency: 'إقامة',
  insurance: 'تأمين',
  authorization: 'تفويض',
  probation: 'فترة التجربة',
  health_insurance: 'تأمين صحي',
  driving_license: 'رخصة قيادة',
  platform_account: 'حساب منصة',
  employee_absconded: 'موظف مسجل هروب',
  vehicle_rental: 'إيجار مركبة',
};

export const workflowLabels = {
  open: 'مفتوح',
  in_progress: 'قيد التنفيذ',
  snoozed: 'مؤجل',
  resolved: 'محسوم',
} as const;

export const ALERT_TYPE_FILTERS = [
  'all',
  'expired_residency_cost',
  'missing_residency_cost',
  'residency',
  'health_insurance',
  'driving_license',
  'probation',
  'insurance',
  'authorization',
  'vehicle_rental',
  'platform_account',
  'employee_absconded',
] as const;

const ALERT_SEVERITY_FILTERS = ['all', 'urgent', 'warning', 'info'] as const;
const ALERT_WORKFLOW_FILTERS = ['all', 'open', 'in_progress', 'snoozed'] as const;
const ALERT_ATTENTION_FILTERS = ['all', 'overdue', 'due_7_days', 'unassigned'] as const;
const ALERT_SEVERITY_ORDER: Record<string, number> = { urgent: 0, warning: 1, info: 2 };

export type AlertTypeFilter = (typeof ALERT_TYPE_FILTERS)[number];
export type AlertSeverityFilter = (typeof ALERT_SEVERITY_FILTERS)[number];
export type AlertWorkflowFilter = (typeof ALERT_WORKFLOW_FILTERS)[number];
export type AlertAttentionFilter = (typeof ALERT_ATTENTION_FILTERS)[number];

export type AlertFilters = {
  type: AlertTypeFilter;
  severity: AlertSeverityFilter;
  workflow: AlertWorkflowFilter;
  attention: AlertAttentionFilter;
  commercialRecord: string;
  search: string;
};

export type AlertStats = {
  activeCount: number;
  overdueCount: number;
  dueWithinWeekCount: number;
  unassignedCount: number;
  expiredResidencyCost: number;
  expiredResidencyMissingCostCount: number;
};

const isFilterOption = <T extends string>(options: readonly T[]) =>
  (value: unknown): value is T => typeof value === 'string' && options.includes(value as T);

export const isAlertTypeFilter = isFilterOption(ALERT_TYPE_FILTERS);
export const isAlertSeverityFilter = isFilterOption(ALERT_SEVERITY_FILTERS);
export const isAlertWorkflowFilter = isFilterOption(ALERT_WORKFLOW_FILTERS);
export const isAlertAttentionFilter = isFilterOption(ALERT_ATTENTION_FILTERS);

export const getAlertTypeFilterLabel = (type: string): string => {
  if (type === 'all') return 'كل الأنواع';
  if (type === 'expired_residency_cost') return 'تكلفة الإقامات المنتهية';
  if (type === 'missing_residency_cost') return 'إقامات بتكلفة غير محددة';
  return alertTypeLabels[type] || type;
};

export const getWorkflowStatus = (alert: Alert): keyof typeof workflowLabels => {
  if (alert.resolved) return 'resolved';
  return alert.workflowStatus ?? 'open';
};

export const getWorkflowTarget = (alert: Alert): AlertWorkflowTarget => ({
  persistedId: alert.persistedId,
  sourceKey: alert.sourceKey ?? alert.id,
  type: alert.type,
  entityId: alert.entityId,
  entityType: alert.entityType,
  message: alert.entityName,
  dueDate: alert.dueDate,
});

export const getAlertCost = (alert: Alert): number | null =>
  alert.residencyRenewalCost ?? alert.estimatedCost ?? null;

export const formatAlertCost = (cost: number): string =>
  `${cost.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ر.س`;

export const getAlertDueLabel = (daysLeft: number): string => {
  if (daysLeft < 0) return `منتهي منذ ${Math.abs(daysLeft).toLocaleString('en-US')} يوم`;
  if (daysLeft === 0) return 'مستحق اليوم';
  if (daysLeft === 1) return 'متبقي يوم واحد';
  return `متبقي ${daysLeft.toLocaleString('en-US')} يوم`;
};

export const formatAlertDate = (dateValue: string): string => {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateValue);
  return match ? `${match[3]}/${match[2]}/${match[1]}` : dateValue;
};

const matchesAlertSearch = (alert: Alert, search: string): boolean => {
  const query = search.trim().toLocaleLowerCase();
  if (!query) return true;
  return [
    alert.entityName,
    alert.description,
    alert.commercialRecordName,
    alertTypeLabels[alert.type],
    alert.dueDate,
  ].some((value) => value?.toLocaleLowerCase().includes(query));
};

export const compareAlerts = (a: Alert, b: Alert): number => {
  const severityDifference = (ALERT_SEVERITY_ORDER[a.severity] ?? 3)
    - (ALERT_SEVERITY_ORDER[b.severity] ?? 3);
  return severityDifference || a.daysLeft - b.daysLeft || a.entityName.localeCompare(b.entityName, 'ar');
};

export const canOpenAlertEntity = (alert: Alert): boolean =>
  Boolean(alert.entityId && (alert.entityType === 'employee' || alert.entityType === 'vehicle'));

export const workflowSummaryLine = (alert: Alert): string => {
  const cost = getAlertCost(alert);
  const details = [
    workflowLabels[getWorkflowStatus(alert)],
    `المسؤول: ${alert.assignedName || 'غير مسند'}`,
    cost === null ? null : `التكلفة: ${formatAlertCost(cost)}`,
    alert.resolutionNote || null,
  ].filter(Boolean).join(' | ');
  return `- ${alertTypeLabels[alert.type] || alert.type}: ${alert.entityName} | ${details}`;
};

const matchesTypeFilter = (alert: Alert, filter: AlertTypeFilter): boolean =>
  filter === 'all'
  || alert.type === filter
  || (filter === 'expired_residency_cost'
    && alert.type === 'residency'
    && alert.daysLeft < 0
    && (alert.residencyRenewalCost ?? 0) > 0)
  || (filter === 'missing_residency_cost'
    && alert.type === 'residency'
    && alert.residencyRenewalCost === null);

const matchesAttentionFilter = (alert: Alert, filter: AlertAttentionFilter): boolean =>
  filter === 'all'
  || (filter === 'overdue' && alert.daysLeft < 0)
  || (filter === 'due_7_days' && alert.daysLeft >= 0 && alert.daysLeft <= 7)
  || (filter === 'unassigned' && !alert.assignedTo);

export const filterAlerts = (alerts: Alert[], filters: AlertFilters): Alert[] => alerts.filter((alert) =>
  matchesTypeFilter(alert, filters.type)
  && (filters.severity === 'all' || alert.severity === filters.severity)
  && (filters.workflow === 'all' || getWorkflowStatus(alert) === filters.workflow)
  && matchesAttentionFilter(alert, filters.attention)
  && (filters.commercialRecord === 'all' || alert.commercialRecordName === filters.commercialRecord)
  && matchesAlertSearch(alert, filters.search));

export const getCommercialRecords = (alerts: Alert[]): string[] => [...new Set(
  alerts
    .map((alert) => alert.commercialRecordName)
    .filter((record): record is string => Boolean(record)),
)].sort((a, b) => a.localeCompare(b, 'ar'));

export const hasActiveAlertFilters = (filters: AlertFilters): boolean => Boolean(
  filters.search.trim()
  || filters.type !== 'all'
  || filters.severity !== 'all'
  || filters.workflow !== 'all'
  || filters.attention !== 'all'
  || filters.commercialRecord !== 'all',
);

export const calculateAlertStats = (alerts: Alert[]): AlertStats => {
  const expiredResidencyAlerts = alerts.filter((alert) => alert.type === 'residency' && alert.daysLeft < 0);
  return {
    activeCount: alerts.length,
    overdueCount: alerts.filter((alert) => alert.daysLeft < 0).length,
    dueWithinWeekCount: alerts.filter((alert) => alert.daysLeft >= 0 && alert.daysLeft <= 7).length,
    unassignedCount: alerts.filter((alert) => !alert.assignedTo).length,
    expiredResidencyCost: expiredResidencyAlerts
      .reduce((total, alert) => total + (alert.residencyRenewalCost ?? 0), 0),
    expiredResidencyMissingCostCount: expiredResidencyAlerts
      .filter((alert) => alert.residencyRenewalCost === null).length,
  };
};
