import { formatStandardDateTime } from '@shared/lib/formatters';

import { useEffect, useMemo, useState } from 'react';
import {
  Bell,
  CalendarClock,
  CheckCircle,
  CircleDollarSign,
  ClipboardCopy,
  Clock,
  Download,
  ExternalLink,
  Search,
  UserRoundCog,
  UserRoundX,
  X,
} from 'lucide-react';
import { Input } from '@shared/components/ui/input';
import { Button } from '@shared/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@shared/components/ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@shared/components/ui/dropdown-menu';
import { Textarea } from '@shared/components/ui/textarea';
import { Label } from '@shared/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@shared/components/ui/select';
import { useToast } from '@shared/hooks/use-toast';
import { escapeHtml } from '@shared/lib/security';
import { addDays, format } from 'date-fns';
import { QueryErrorRetry } from '@shared/components/QueryErrorRetry';
import { loadXlsx } from '@modules/orders/utils/xlsx';
import { useAlerts } from '@shared/hooks/useAlerts';
import type { Alert } from '@shared/lib/alertsBuilder';
import {
  alertsService,
  type AlertWorkflowTarget,
} from '@services/alertsService';
import { getErrorMessage } from '@services/serviceError';
import { useAuth } from '@app/providers/AuthContext';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { usePermissions } from '@shared/hooks/usePermissions';
import { usePersistentState } from '@shared/hooks/usePersistentState';
import {
  AlertWorkflowDialog,
  type AlertWorkflowForm,
} from '@modules/alerts/components/AlertWorkflowDialog';

function severityColor(severity: string): string {
  if (severity === 'urgent') return 'hsl(var(--destructive))';
  if (severity === 'warning') return 'hsl(var(--warning))';
  return 'hsl(var(--primary))';
}

function severityBorderClass(severity: string): string {
  if (severity === 'urgent') return 'border-destructive/30';
  if (severity === 'warning') return 'border-warning/30';
  return 'border-border/50';
}

function severityBgClass(severity: string): string {
  if (severity === 'urgent') return 'bg-destructive/10';
  if (severity === 'warning') return 'bg-warning/10';
  return 'bg-info/10';
}

function daysLeftClass(daysLeft: number): string {
  if (daysLeft <= 7) return 'text-destructive';
  if (daysLeft <= 30) return 'text-warning';
  return 'text-muted-foreground';
}

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

const severityStyles: Record<string, string> = { urgent: 'badge-urgent', warning: 'badge-warning', info: 'badge-info' };
const severityLabels: Record<string, string> = { urgent: 'عاجل', warning: 'تحذير', info: 'معلومات' };
const ALERT_SEVERITY_ORDER: Record<string, number> = { urgent: 0, warning: 1, info: 2 };

const typeIcons: Record<string, string> = {
  residency: '🪪', insurance: '🛡️', authorization: '📋', probation: '⏳',
  health_insurance: '🏥', driving_license: '🪪', platform_account: '📱', employee_absconded: '⚠️',
  vehicle_rental: '🚙',
};

function getAlertTypeFilterLabel(type: string): string {
  if (type === 'all') return 'كل الأنواع';
  if (type === 'expired_residency_cost') return 'تكلفة الإقامات المنتهية';
  if (type === 'missing_residency_cost') return 'إقامات بتكلفة غير محددة';
  return alertTypeLabels[type] || type;
}

const workflowLabels = {
  open: 'مفتوح',
  in_progress: 'قيد التنفيذ',
  snoozed: 'مؤجل',
  resolved: 'محسوم',
} as const;

const workflowStyles = {
  open: 'bg-muted text-foreground',
  in_progress: 'bg-info/15 text-info',
  snoozed: 'bg-warning/15 text-warning',
  resolved: 'bg-success/15 text-success',
} as const;

function getWorkflowStatus(alert: Alert): keyof typeof workflowLabels {
  if (alert.resolved) return 'resolved';
  return alert.workflowStatus ?? 'open';
}

function getWorkflowTarget(alert: Alert): AlertWorkflowTarget {
  return {
    persistedId: alert.persistedId,
    sourceKey: alert.sourceKey ?? alert.id,
    type: alert.type,
    entityId: alert.entityId,
    entityType: alert.entityType,
    message: alert.entityName,
    dueDate: alert.dueDate,
  };
}

function getAlertCost(alert: Alert): number | null {
  return alert.residencyRenewalCost ?? alert.estimatedCost ?? null;
}

function formatAlertCost(cost: number): string {
  return `${cost.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ر.س`;
}

function getAlertDueLabel(daysLeft: number): string {
  if (daysLeft < 0) return `منتهي منذ ${Math.abs(daysLeft).toLocaleString('en-US')} يوم`;
  if (daysLeft === 0) return 'مستحق اليوم';
  if (daysLeft === 1) return 'متبقي يوم واحد';
  return `متبقي ${daysLeft.toLocaleString('en-US')} يوم`;
}

function formatAlertDate(dateValue: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateValue);
  return match ? `${match[3]}/${match[2]}/${match[1]}` : dateValue;
}

function matchesAlertSearch(alert: Alert, search: string): boolean {
  const query = search.trim().toLocaleLowerCase();
  if (!query) return true;
  return [
    alert.entityName,
    alert.description,
    alert.commercialRecordName,
    alertTypeLabels[alert.type],
    alert.dueDate,
  ].some((value) => value?.toLocaleLowerCase().includes(query));
}

function compareAlerts(a: Alert, b: Alert): number {
  const severityDifference = (ALERT_SEVERITY_ORDER[a.severity] ?? 3) - (ALERT_SEVERITY_ORDER[b.severity] ?? 3);
  return severityDifference || a.daysLeft - b.daysLeft || a.entityName.localeCompare(b.entityName, 'ar');
}

function canOpenAlertEntity(alert: Alert): boolean {
  return Boolean(alert.entityId && (alert.entityType === 'employee' || alert.entityType === 'vehicle'));
}

function workflowSummaryLine(alert: Alert): string {
  const cost = getAlertCost(alert);
  const details = [
    workflowLabels[getWorkflowStatus(alert)],
    `المسؤول: ${alert.assignedName || 'غير مسند'}`,
    cost === null ? null : `التكلفة: ${formatAlertCost(cost)}`,
    alert.resolutionNote || null,
  ].filter(Boolean).join(' | ');
  return `- ${alertTypeLabels[alert.type] || alert.type}: ${alert.entityName} | ${details}`;
}

const ALERT_TYPE_FILTERS = [
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
];
const ALERT_SEVERITY_FILTERS = ['all', 'urgent', 'warning', 'info'];
const ALERT_WORKFLOW_FILTERS = ['all', 'open', 'in_progress', 'snoozed'];
const ALERT_ATTENTION_FILTERS = ['all', 'overdue', 'due_7_days', 'unassigned'];
const isFilterOption = (options: string[]) =>
  (value: unknown): value is string => typeof value === 'string' && options.includes(value);
const isAlertTypeFilter = isFilterOption(ALERT_TYPE_FILTERS);
const isAlertSeverityFilter = isFilterOption(ALERT_SEVERITY_FILTERS);
const isAlertWorkflowFilter = isFilterOption(ALERT_WORKFLOW_FILTERS);
const isAlertAttentionFilter = isFilterOption(ALERT_ATTENTION_FILTERS);

const Alerts = () => {
  const [typeFilter, setTypeFilter] = usePersistentState('list:alerts:type:v1', 'all', isAlertTypeFilter);
  const [severityFilter, setSeverityFilter] = usePersistentState('list:alerts:severity:v1', 'all', isAlertSeverityFilter);
  const [workflowFilter, setWorkflowFilter] = usePersistentState('list:alerts:workflow:v1', 'all', isAlertWorkflowFilter);
  const [attentionFilter, setAttentionFilter] = usePersistentState('list:alerts:attention:v1', 'all', isAlertAttentionFilter);
  const [crFilter, setCrFilter] = usePersistentState('list:alerts:commercial-record:v1', 'all', (value): value is string => typeof value === 'string');
  const [search, setSearch] = usePersistentState('list:alerts:search:v1', '', (value): value is string => typeof value === 'string');
  const [resolveDialog, setResolveDialog] = useState<Alert | null>(null);
  const [deferDialog, setDeferDialog] = useState<Alert | null>(null);
  const [deferDays, setDeferDays] = useState('7');
  const [resolveNote, setResolveNote] = useState('');
  const [workflowDialog, setWorkflowDialog] = useState<Alert | null>(null);
  const [workflowSaving, setWorkflowSaving] = useState(false);

  const { toast } = useToast();
  const { user } = useAuth();
  const { permissions } = usePermissions('alerts');
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const alertsQuery = useAlerts();
  const assigneesQuery = useQuery({
    queryKey: ['alerts', 'assignable-users'],
    queryFn: alertsService.fetchAssignableUsers,
    enabled: permissions.can_edit,
    staleTime: 5 * 60_000,
  });

  const localAlerts = useMemo<Alert[]>(() => alertsQuery.data ?? [], [alertsQuery.data]);

  // ── Derived state ─────────────────────────────────────────────────────────
  const activeAlerts = useMemo(() => localAlerts.filter((alert) => !alert.resolved), [localAlerts]);
  const resolved = useMemo(() => localAlerts.filter((alert) => alert.resolved), [localAlerts]);
  const commercialRecords = useMemo(() => [...new Set(
    activeAlerts
      .map((alert) => alert.commercialRecordName)
      .filter((record): record is string => Boolean(record))
  )].sort((a, b) => a.localeCompare(b, 'ar')), [activeAlerts]);

  useEffect(() => {
    if (alertsQuery.data && crFilter !== 'all' && !commercialRecords.includes(crFilter)) {
      setCrFilter('all');
    }
  }, [alertsQuery.data, commercialRecords, crFilter, setCrFilter]);

  const filtered = activeAlerts.filter(a => {
    const matchType =
      typeFilter === 'all' ||
      a.type === typeFilter ||
      (typeFilter === 'expired_residency_cost' && a.type === 'residency' && a.daysLeft < 0 && (a.residencyRenewalCost ?? 0) > 0) ||
      (typeFilter === 'missing_residency_cost' && a.type === 'residency' && a.residencyRenewalCost === null);
    const matchSeverity = severityFilter === 'all' || a.severity === severityFilter;
    const matchWorkflow = workflowFilter === 'all' || getWorkflowStatus(a) === workflowFilter;
    const matchAttention =
      attentionFilter === 'all'
      || (attentionFilter === 'overdue' && a.daysLeft < 0)
      || (attentionFilter === 'due_7_days' && a.daysLeft >= 0 && a.daysLeft <= 7)
      || (attentionFilter === 'unassigned' && !a.assignedTo);
    const matchCr = crFilter === 'all' || a.commercialRecordName === crFilter;
    return matchType && matchSeverity && matchWorkflow && matchAttention && matchesAlertSearch(a, search) && matchCr;
  });

  const visibleAlerts = [...filtered].sort(compareAlerts);
  const activeAlertsCount = activeAlerts.length;
  const hasActiveFilters = Boolean(
    search.trim()
      || typeFilter !== 'all'
      || severityFilter !== 'all'
      || workflowFilter !== 'all'
      || attentionFilter !== 'all'
      || crFilter !== 'all',
  );
  const resetFilters = () => {
    setSearch('');
    setTypeFilter('all');
    setSeverityFilter('all');
    setWorkflowFilter('all');
    setAttentionFilter('all');
    setCrFilter('all');
  };

  const overdueCount = activeAlerts.filter((alert) => alert.daysLeft < 0).length;
  const dueWithinWeekCount = activeAlerts.filter((alert) => alert.daysLeft >= 0 && alert.daysLeft <= 7).length;
  const unassignedCount = activeAlerts.filter((alert) => !alert.assignedTo).length;
  const expiredResidencyCost = activeAlerts
    .filter((alert) => alert.type === 'residency' && alert.daysLeft < 0)
    .reduce((total, alert) => total + (alert.residencyRenewalCost ?? 0), 0);
  const missingResidencyCostCount = activeAlerts
    .filter((alert) => alert.type === 'residency' && alert.residencyRenewalCost === null)
    .length;

  // ── Handlers ──────────────────────────────────────────────────────────────
  const handleResolve = async () => {
    if (!resolveDialog) return;
    try {
      await alertsService.saveWorkflow(getWorkflowTarget(resolveDialog), {
        status: 'resolved',
        assignedTo: resolveDialog.assignedTo ?? user?.id ?? null,
        estimatedCost: getAlertCost(resolveDialog),
        resolutionNote: resolveNote.trim() || resolveDialog.resolutionNote || null,
        dueDate: resolveDialog.dueDate,
        actorId: user?.id ?? null,
      });
      await queryClient.invalidateQueries({ queryKey: ['alerts'] });
      toast({ title: 'تم الحسم', description: `تم حسم تنبيه: ${resolveDialog.entityName}` });
      setResolveDialog(null);
      setResolveNote('');
    } catch (error) {
      toast({ title: 'تعذر حسم التنبيه', description: getErrorMessage(error), variant: 'destructive' });
    }
  };

  const handleDefer = async () => {
    if (!deferDialog) return;
    const days = Number.parseInt(deferDays, 10);
    if (!Number.isInteger(days) || days < 1 || days > 365) {
      toast({ title: 'مدة التأجيل غير صحيحة', description: 'أدخل عدداً من 1 إلى 365 يوماً.', variant: 'destructive' });
      return;
    }
    const dueDate = format(addDays(new Date(), days), 'yyyy-MM-dd');

    try {
      await alertsService.saveWorkflow(getWorkflowTarget(deferDialog), {
        status: 'snoozed',
        assignedTo: deferDialog.assignedTo ?? null,
        estimatedCost: getAlertCost(deferDialog),
        resolutionNote: deferDialog.resolutionNote ?? null,
        dueDate,
        actorId: user?.id ?? null,
      });
      await queryClient.invalidateQueries({ queryKey: ['alerts'] });
      toast({ title: 'تم التأجيل', description: `تم تأجيل التنبيه ${days} يوم` });
      setDeferDialog(null);
      setDeferDays('7');
    } catch (error) {
      toast({ title: 'تعذر تأجيل التنبيه', description: getErrorMessage(error), variant: 'destructive' });
    }
  };

  const handleWorkflowSave = async (alert: Alert, form: AlertWorkflowForm) => {
    setWorkflowSaving(true);
    try {
      await alertsService.saveWorkflow(getWorkflowTarget(alert), {
        status: form.status,
        assignedTo: form.assignedTo,
        estimatedCost: form.estimatedCost,
        resolutionNote: form.note,
        dueDate: alert.dueDate,
        actorId: user?.id ?? null,
      });
      await queryClient.invalidateQueries({ queryKey: ['alerts'] });
      setWorkflowDialog(null);
      toast({ title: 'تم حفظ متابعة التنبيه' });
    } catch (error) {
      toast({ title: 'تعذر حفظ المتابعة', description: getErrorMessage(error), variant: 'destructive' });
    } finally {
      setWorkflowSaving(false);
    }
  };

  const openAlertEntity = (alert: Alert) => {
    if (!alert.entityId) return;
    if (alert.entityType === 'employee') {
      navigate(`/employees?employee=${encodeURIComponent(alert.entityId)}`);
    } else if (alert.entityType === 'vehicle') {
      navigate('/motorcycles');
    }
  };

  const handlePrint = () => {
    const rows = visibleAlerts.map(a => `<tr><td>${escapeHtml(alertTypeLabels[a.type] || a.type)}</td><td>${escapeHtml(a.entityName)}</td><td>${escapeHtml(a.commercialRecordName || '—')}</td><td>${escapeHtml(formatAlertDate(a.dueDate))}</td><td style="text-align:center">${escapeHtml(String(a.daysLeft ?? '—'))}</td><td style="text-align:center;font-weight:700;color:${severityColor(a.severity)}">${escapeHtml(severityLabels[a.severity] || a.severity)}</td></tr>`).join('');
    const printWindow = globalThis.open('', '_blank');
    if (!printWindow) return;
    const htmlContent = `<!DOCTYPE html><html dir="rtl" lang="ar"><head><meta charset="UTF-8"/><title>تقرير التنبيهات</title><style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:"Droid Arabic Kufi","Tajawal",Arial,sans-serif;font-size:11px;direction:rtl;color:#061735;background:#fff}h2{text-align:center;margin-bottom:8px;font-size:15px}p.sub{text-align:center;color:#061735;font-size:11px;margin-bottom:12px}table{width:100%;border-collapse:collapse}th{background:#1f54ad;color:#fff;padding:6px 8px;text-align:right;font-size:10px}td{padding:5px 8px;border-bottom:1px solid #e0e0e0;text-align:right}tr:nth-child(even) td{background:#f9f9f9}@media print{body{-webkit-print-color-adjust:exact;print-color-adjust:exact}}</style></head><body><h2>تقرير التنبيهات التلقائية</h2><p class="sub">المجموع: ${visibleAlerts.length} تنبيه — ${formatStandardDateTime(new Date())}</p><table><thead><tr><th>النوع</th><th>الكيان</th><th>السجل التجاري</th><th>تاريخ الاستحقاق</th><th>المتبقي (يوم)</th><th>الأولوية</th></tr></thead><tbody>${rows}</tbody></table></body></html>`;
    printWindow.document.body.innerHTML = htmlContent;
    printWindow.focus();
    // Use setTimeout to ensure content is loaded before printing
    setTimeout(() => {
      printWindow.print();
    }, 500);
  };

  const handleExport = async () => {
    const XLSX = await loadXlsx();
    const rows = visibleAlerts.map(a => ({
        'الأولوية': severityLabels[a.severity] || a.severity,
        'النوع': alertTypeLabels[a.type] || a.type,
        'الكيان': a.entityName,
        'السجل التجاري': a.commercialRecordName ?? '',
        'تاريخ الاستحقاق': a.dueDate,
        'المتبقي (يوم)': a.daysLeft,
        'حالة المتابعة': workflowLabels[getWorkflowStatus(a)],
        'المسؤول': a.assignedName || 'غير مسند',
        'التكلفة المتوقعة': getAlertCost(a) ?? '',
        'ملاحظة المتابعة': a.resolutionNote ?? '',
    }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'التنبيهات');
    XLSX.writeFile(wb, `التنبيهات_${format(new Date(), 'yyyy-MM-dd')}.xlsx`);
  };

  const copyWorkflowSummary = async () => {
    try {
      const visibleAlerts = filtered.slice(0, 50);
      const lines = visibleAlerts.map(workflowSummaryLine);
      const remaining = filtered.length - visibleAlerts.length;
      const footer = remaining > 0 ? `\n... و${remaining} تنبيه إضافي` : '';
      await navigator.clipboard.writeText(`ملخص متابعة التنبيهات (${filtered.length})\n${lines.join('\n')}${footer}`);
      toast({ title: 'تم نسخ ملخص المتابعة' });
    } catch (error) {
      toast({ title: 'تعذر نسخ الملخص', description: getErrorMessage(error), variant: 'destructive' });
    }
  };

  const handleDownloadTemplate = async () => {
    const XLSX = await loadXlsx();
    const rows = visibleAlerts.map((alert) => [
        alertTypeLabels[alert.type] || alert.type,
        alert.entityName,
        alert.commercialRecordName ?? '',
        alert.dueDate,
        alert.daysLeft,
        severityLabels[alert.severity] || alert.severity,
    ]);
    const headers = ['النوع', 'الكيان', 'السجل التجاري', 'تاريخ الاستحقاق', 'المتبقي (يوم)', 'الأولوية'];
    const ws = XLSX.utils.aoa_to_sheet([headers, ...rows]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'قالب');
    XLSX.writeFile(wb, 'template_alerts.xlsx');
  };

  const typeOptions = ALERT_TYPE_FILTERS;

  let alertsContent = null;
  if (alertsQuery.isLoading) {
    alertsContent = (
      <div className="space-y-2" aria-label="جارٍ تحميل التنبيهات">
        {[1, 2, 3].map((row) => (
          <div key={row} className="h-28 animate-pulse rounded-lg border border-border/50 bg-muted/40" />
        ))}
      </div>
    );
  } else if (filtered.length === 0) {
    alertsContent = (
      <div className="bg-card border border-border/50 p-12 text-center rounded-lg">
        <CheckCircle size={40} className="mx-auto text-success mb-3" />
        <p className="font-semibold text-foreground">
          {hasActiveFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد تنبيهات مفعّلة'}
        </p>
        <p className="text-sm text-muted-foreground mt-1">
          {hasActiveFilters ? 'غيّر الفلاتر أو امسحها لعرض التنبيهات.' : 'لا توجد استحقاقات تحتاج متابعة حالياً.'}
        </p>
        {hasActiveFilters && (
          <Button type="button" variant="outline" size="sm" className="mt-3" onClick={resetFilters}>
            مسح الفلاتر
          </Button>
        )}
      </div>
    );
  } else {
    alertsContent = visibleAlerts.map(a => {
      const workflowStatus = getWorkflowStatus(a);
      const alertCost = getAlertCost(a);
      return (
      <article key={a.id} className={`bg-card rounded-lg border shadow-card p-4 transition-shadow hover:shadow-card-hover ${severityBorderClass(a.severity)}`}>
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
          <div className={`w-10 h-10 rounded-lg flex items-center justify-center text-lg flex-shrink-0 ${severityBgClass(a.severity)}`} aria-hidden="true">
            {typeIcons[a.type] || '🔔'}
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-xs font-semibold text-muted-foreground">{alertTypeLabels[a.type] || a.type}</span>
              <span className={severityStyles[a.severity]}>{severityLabels[a.severity]}</span>
              <span className={`rounded-md px-2 py-0.5 text-xs font-semibold ${workflowStyles[workflowStatus]}`}>
                {workflowLabels[workflowStatus]}
              </span>
            </div>
            <h2 className="mt-1 text-base font-bold text-foreground">{a.entityName}</h2>
            {a.description && <p className="mt-1 text-sm text-foreground">{a.description}</p>}

            <dl className="mt-3 grid grid-cols-2 gap-x-6 gap-y-2 text-xs sm:grid-cols-3 xl:grid-cols-6">
              <div>
                <dt className="text-muted-foreground">تاريخ الاستحقاق</dt>
                <dd className="mt-0.5 font-semibold tabular-nums text-foreground">{formatAlertDate(a.dueDate)}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">الحالة الزمنية</dt>
                <dd className={`mt-0.5 font-bold tabular-nums ${daysLeftClass(a.daysLeft)}`}>{getAlertDueLabel(a.daysLeft)}</dd>
              </div>
              {a.commercialRecordName && (
                <div>
                  <dt className="text-muted-foreground">السجل التجاري</dt>
                  <dd className="mt-0.5 font-semibold text-foreground">{a.commercialRecordName}</dd>
                </div>
              )}
              {a.renewalDurationLabel && (
                <div>
                  <dt className="text-muted-foreground">مدة التجديد المطلوبة</dt>
                  <dd className="mt-0.5 font-semibold text-foreground">{a.renewalDurationLabel}</dd>
                </div>
              )}
              {alertCost !== null && (
                <div>
                  <dt className="text-muted-foreground">التكلفة المتوقعة</dt>
                  <dd className="mt-0.5 font-bold tabular-nums text-foreground">{formatAlertCost(alertCost)}</dd>
                </div>
              )}
              {a.type === 'residency' && alertCost === null && (
                <div>
                  <dt className="text-muted-foreground">التكلفة المتوقعة</dt>
                  <dd className="mt-0.5 font-bold text-warning">غير محددة في السجل التجاري</dd>
                </div>
              )}
              <div>
                <dt className="text-muted-foreground">المسؤول</dt>
                <dd className="mt-0.5 font-semibold text-foreground">{a.assignedName || 'غير مسند'}</dd>
              </div>
              {a.snoozedUntil && (
                <div>
                  <dt className="text-muted-foreground">مؤجل حتى</dt>
                  <dd className="mt-0.5 font-semibold tabular-nums text-foreground">{formatAlertDate(a.snoozedUntil)}</dd>
                </div>
              )}
            </dl>
          </div>
          <div className="flex flex-wrap items-center gap-2 lg:flex-shrink-0">
            {canOpenAlertEntity(a) && (
              <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => openAlertEntity(a)} title="فتح السجل المرتبط" aria-label="فتح السجل المرتبط">
                <ExternalLink size={14} />
              </Button>
            )}
            {permissions.can_edit && (
              <>
                <Button size="sm" variant="outline" className="gap-1 text-xs h-8" onClick={() => setWorkflowDialog(a)}>
                  <UserRoundCog size={12} /> إدارة
                </Button>
                <Button size="sm" variant="outline" className="gap-1 text-xs h-8" onClick={() => setDeferDialog(a)}>
                  <Clock size={12} /> تأجيل
                </Button>
                <Button size="sm" className="gap-1 text-xs h-8 bg-success hover:bg-success/90" onClick={() => setResolveDialog(a)}>
                  <CheckCircle size={12} /> حسم
                </Button>
              </>
            )}
          </div>
        </div>
      </article>
      );
    });
  }

  return (
    <div className="ds-page alerts-page space-y-4">
      <div className="page-header">
        <nav className="page-breadcrumb">
          <span>الرئيسية</span>
          <span className="page-breadcrumb-sep">/</span>
          <span>التنبيهات</span>
        </nav>
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div>
            <h1 className="page-title flex items-center gap-2"><Bell size={20} /> التنبيهات التلقائية</h1>
            <p className="page-subtitle">
              {alertsQuery.isLoading
                ? 'جارٍ التحميل...'
                : `${activeAlertsCount.toLocaleString('en-US')} تنبيه نشط — ${overdueCount.toLocaleString('en-US')} متأخر`}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {alertsQuery.isFetching && !alertsQuery.isLoading && (
              <span className="text-xs text-muted-foreground animate-pulse">جارٍ التحديث…</span>
            )}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="sm" className="gap-1.5 h-9"><Download size={14} /> البيانات ▾</Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={handleExport}>📊 تصدير Excel (مرتب حسب الأولوية)</DropdownMenuItem>
                <DropdownMenuItem onClick={() => void copyWorkflowSummary()}><ClipboardCopy size={14} className="ml-2" /> نسخ ملخص المتابعة</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleDownloadTemplate}>📥 تحميل القالب</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handlePrint}>🖨️ طباعة التقرير</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => alertsQuery.refetch().catch(() => {})}>
                  🔄 تحديث الآن
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>

      {/* Error state */}
      {alertsQuery.isError && !alertsQuery.isLoading && (
        <QueryErrorRetry
          error={alertsQuery.error}
          onRetry={() => alertsQuery.refetch().catch(() => {})}
          title="تعذر تحميل بيانات التنبيهات"
          hint="تحقق من الاتصال بالإنترنت أو أعد المحاولة."
        />
      )}

      <section className="grid grid-cols-2 gap-3 lg:grid-cols-5" aria-label="ملخص التنبيهات">
        <button type="button"
          className="stat-card text-start w-full cursor-pointer hover:shadow-card-hover transition-shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
          onClick={() => setAttentionFilter('all')}
          aria-pressed={attentionFilter === 'all'}
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-foreground">التنبيهات النشطة</p>
            <Bell size={17} className="text-primary" />
          </div>
          <p className="mt-2 text-2xl font-bold tabular-nums text-foreground">{activeAlertsCount.toLocaleString('en-US')}</p>
          <p className="mt-1 text-xs text-muted-foreground">كل الاستحقاقات المفتوحة</p>
        </button>
        <button type="button"
          className="stat-card text-start w-full cursor-pointer hover:shadow-card-hover transition-shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
          onClick={() => setAttentionFilter(attentionFilter === 'overdue' ? 'all' : 'overdue')}
          aria-pressed={attentionFilter === 'overdue'}
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-foreground">متأخرة</p>
            <CalendarClock size={17} className="text-destructive" />
          </div>
          <p className="mt-2 text-2xl font-bold tabular-nums text-destructive">{overdueCount.toLocaleString('en-US')}</p>
          <p className="mt-1 text-xs text-muted-foreground">تجاوزت تاريخ الاستحقاق</p>
        </button>
        <button type="button"
          className="stat-card text-start w-full cursor-pointer hover:shadow-card-hover transition-shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
          onClick={() => setAttentionFilter(attentionFilter === 'due_7_days' ? 'all' : 'due_7_days')}
          aria-pressed={attentionFilter === 'due_7_days'}
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-foreground">خلال 7 أيام</p>
            <Clock size={17} className="text-warning" />
          </div>
          <p className="mt-2 text-2xl font-bold tabular-nums text-warning">{dueWithinWeekCount.toLocaleString('en-US')}</p>
          <p className="mt-1 text-xs text-muted-foreground">تشمل المستحق اليوم</p>
        </button>
        <button type="button"
          className="stat-card text-start w-full cursor-pointer hover:shadow-card-hover transition-shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
          onClick={() => setAttentionFilter(attentionFilter === 'unassigned' ? 'all' : 'unassigned')}
          aria-pressed={attentionFilter === 'unassigned'}
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-foreground">غير مسندة</p>
            <UserRoundX size={17} className="text-muted-foreground" />
          </div>
          <p className="mt-2 text-2xl font-bold tabular-nums text-foreground">{unassignedCount.toLocaleString('en-US')}</p>
          <p className="mt-1 text-xs text-muted-foreground">تحتاج تحديد مسؤول</p>
        </button>
        <button type="button"
          className="stat-card col-span-2 text-start w-full cursor-pointer hover:shadow-card-hover transition-shadow focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50 lg:col-span-1"
          onClick={() => setTypeFilter(typeFilter === 'expired_residency_cost' ? 'all' : 'expired_residency_cost')}
          aria-pressed={typeFilter === 'expired_residency_cost'}
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-foreground">تكلفة الإقامات المنتهية</p>
            <CircleDollarSign size={17} className="text-success" />
          </div>
          <p className="mt-2 text-xl font-bold tabular-nums text-success">{formatAlertCost(expiredResidencyCost)}</p>
          <p className="mt-1 text-xs text-muted-foreground">
            حسب السجل والدورية · {missingResidencyCostCount.toLocaleString('en-US')} بدون تكلفة محددة
          </p>
        </button>
      </section>

      <section className="bg-card border border-border/50 p-3 space-y-3 rounded-lg" aria-label="فلاتر التنبيهات">
        <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-7">
          <div className="relative sm:col-span-2 xl:col-span-2">
            <Search size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <Input placeholder="بحث بالاسم أو السجل أو التاريخ..." className="pr-9" value={search} onChange={e => setSearch(e.target.value)} />
          </div>
          <Select value={typeFilter} onValueChange={setTypeFilter}>
            <SelectTrigger aria-label="نوع التنبيه"><SelectValue placeholder="نوع التنبيه" /></SelectTrigger>
            <SelectContent>
              {typeOptions.map((type) => <SelectItem key={type} value={type}>{getAlertTypeFilterLabel(type)}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={severityFilter} onValueChange={setSeverityFilter}>
            <SelectTrigger aria-label="الأولوية"><SelectValue placeholder="الأولوية" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">كل الأولويات</SelectItem>
              <SelectItem value="urgent">عاجل</SelectItem>
              <SelectItem value="warning">تحذير</SelectItem>
              <SelectItem value="info">معلومات</SelectItem>
            </SelectContent>
          </Select>
          <Select value={workflowFilter} onValueChange={setWorkflowFilter}>
            <SelectTrigger aria-label="حالة المتابعة"><SelectValue placeholder="حالة المتابعة" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">كل حالات المتابعة</SelectItem>
              <SelectItem value="open">مفتوح</SelectItem>
              <SelectItem value="in_progress">قيد التنفيذ</SelectItem>
              <SelectItem value="snoozed">مؤجل</SelectItem>
            </SelectContent>
          </Select>
          <Select value={attentionFilter} onValueChange={setAttentionFilter}>
            <SelectTrigger aria-label="حالة الاستحقاق"><SelectValue placeholder="حالة الاستحقاق" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">كل الاستحقاقات</SelectItem>
              <SelectItem value="overdue">متأخرة</SelectItem>
              <SelectItem value="due_7_days">خلال 7 أيام</SelectItem>
              <SelectItem value="unassigned">غير مسندة</SelectItem>
            </SelectContent>
          </Select>
          {commercialRecords.length > 0 && (
            <Select value={crFilter} onValueChange={setCrFilter}>
              <SelectTrigger aria-label="السجل التجاري"><SelectValue placeholder="السجل التجاري" /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">كل السجلات التجارية</SelectItem>
                {commercialRecords.map((record) => <SelectItem key={record} value={record}>{record}</SelectItem>)}
              </SelectContent>
            </Select>
          )}
        </div>
        <div className="flex items-center justify-between gap-3 border-t border-border/40 pt-2">
          <span className="text-xs font-medium text-foreground">
            {filtered.length.toLocaleString('en-US')} من {activeAlertsCount.toLocaleString('en-US')} تنبيه نشط
          </span>
          {hasActiveFilters && (
            <Button type="button" variant="ghost" size="sm" className="gap-1.5" onClick={resetFilters}>
              <X size={14} /> مسح الفلاتر
            </Button>
          )}
        </div>
      </section>

      <div className="space-y-3">
        {alertsContent}
      </div>

      {resolved.length > 0 && (
        <details className="rounded-lg border border-border/50 bg-card">
          <summary className="flex cursor-pointer list-none items-center gap-2 px-4 py-3 text-sm font-semibold text-foreground focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50">
            <CheckCircle size={16} className="text-success" />
            التنبيهات المحسومة
            <span className="tabular-nums text-muted-foreground">({resolved.length.toLocaleString('en-US')})</span>
          </summary>
          <div className="max-h-96 divide-y divide-border/40 overflow-y-auto border-t border-border/40">
            {[...resolved].sort(compareAlerts).map((alert) => (
              <div key={alert.id} className="flex items-center gap-3 px-4 py-3">
                <span className="text-base" aria-hidden="true">{typeIcons[alert.type] || '🔔'}</span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-foreground">{alert.entityName}</p>
                  <p className="text-xs text-muted-foreground">
                    {alertTypeLabels[alert.type] || alert.type} · {formatAlertDate(alert.dueDate)}
                  </p>
                </div>
                <span className="text-xs font-semibold text-success">محسوم</span>
              </div>
            ))}
          </div>
        </details>
      )}

      <Dialog open={!!resolveDialog} onOpenChange={(open) => !open && setResolveDialog(null)}>
        <DialogContent dir="rtl" className="max-w-md">
          <DialogHeader><DialogTitle>حسم التنبيه</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div className="bg-muted/50 rounded-lg p-3">
              <p className="text-sm font-medium">{resolveDialog && (alertTypeLabels[resolveDialog.type] || resolveDialog.type)}</p>
              <p className="text-sm text-muted-foreground mt-1">{resolveDialog?.entityName}</p>
            </div>
            <div className="space-y-2">
              <Label>ملاحظة (اختياري)</Label>
              <Textarea placeholder="اكتب ملاحظة..." value={resolveNote} onChange={e => setResolveNote(e.target.value)} rows={3} />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setResolveDialog(null)}>إلغاء</Button>
            <Button className="bg-success hover:bg-success/90" onClick={handleResolve}>
              <CheckCircle size={14} className="ml-1" /> تأكيد الحسم
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!deferDialog} onOpenChange={(open) => !open && setDeferDialog(null)}>
        <DialogContent dir="rtl" className="max-w-md">
          <DialogHeader><DialogTitle>تأجيل التنبيه</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div className="bg-muted/50 rounded-lg p-3">
              <p className="text-sm font-medium">{deferDialog && (alertTypeLabels[deferDialog.type] || deferDialog.type)}</p>
              <p className="text-sm text-muted-foreground mt-1">{deferDialog?.entityName}</p>
            </div>
            <div className="space-y-2">
              <Label>مدة التأجيل (أيام)</Label>
              <div className="flex gap-2">
                {['7', '14', '30', '60'].map(d => (
                  <button type="button" key={d} onClick={() => setDeferDays(d)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors flex-1 ${deferDays === d ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-accent'}`}>
                    {d} يوم
                  </button>
                ))}
              </div>
              <Input type="number" value={deferDays} onChange={e => setDeferDays(e.target.value)} placeholder="أو اكتب عدد مخصص" />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDeferDialog(null)}>إلغاء</Button>
            <Button onClick={handleDefer}><Clock size={14} className="ml-1" /> تأجيل {deferDays} يوم</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertWorkflowDialog
        alert={workflowDialog}
        users={assigneesQuery.data ?? []}
        saving={workflowSaving}
        onClose={() => setWorkflowDialog(null)}
        onSave={handleWorkflowSave}
      />
    </div>
  );
};

export default Alerts;
