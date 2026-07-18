import {
  addMonths,
  addYears,
  differenceInCalendarDays,
  differenceInCalendarMonths,
  differenceInCalendarYears,
  format,
  isBefore,
  isValid,
  parseISO,
  startOfDay,
} from "date-fns";
import { getNextMonthlyRentalDueDate } from "@shared/lib/vehicleRental";

const ISO_DATE_FORMAT = "yyyy-MM-dd";

export interface Alert {
  id: string;
  type: string;
  entityName: string;
  dueDate: string;
  daysLeft: number;
  severity: "urgent" | "warning" | "info";
  resolved: boolean;
  persisted?: boolean;
  persistedId?: string;
  sourceKey?: string;
  entityId?: string | null;
  entityType?: string | null;
  workflowStatus?: "open" | "in_progress" | "snoozed" | "resolved";
  assignedTo?: string | null;
  assignedName?: string | null;
  estimatedCost?: number | null;
  resolutionNote?: string | null;
  snoozedUntil?: string | null;
  residencyRenewalCost?: number | null;
  residencyRenewalCostPeriod?: "monthly" | "yearly" | null;
  commercialRecordName?: string | null;
  renewalDurationLabel?: string | null;
  description?: string | null;
}

export type EmployeeAlertRow = {
  id: string;
  name: string;
  commercial_record?: string | null;
  residency_expiry: string | null;
  probation_end_date: string | null;
  health_insurance_expiry?: string | null;
  license_expiry?: string | null;
  sponsorship_status?: string | null;
  status?: string | null;
};

export type AbscondedEmployeeAlertRow = {
  id: string;
  name: string;
  sponsorship_status?: string | null;
  vehicle_assignments?: {
    end_date: string | null;
    vehicles: { plate_number: string; type: string } | null;
  }[] | null;
  employee_apps?: {
    status: string | null;
    apps: { name: string | null } | null;
  }[] | null;
};

export type VehicleExpiryRow = {
  id: string;
  plate_number: string;
  insurance_expiry: string | null;
  authorization_expiry: string | null;
};

export type VehicleRentalAlertRow = {
  id: string;
  plate_number: string;
  rental_start_date: string | null;
  rental_monthly_amount: number | null;
  status: string;
};

export type PlatformAccountAlertRow = {
  id: string;
  account_username: string;
  iqama_expiry_date: string | null;
  app_id: string;
  apps?: { name?: string | null } | null;
};

export type PersistedAlertRow = {
  id: string;
  type: string;
  due_date: string | null;
  is_resolved: boolean | null;
  message: string | null;
  details: Record<string, unknown> | null;
  entity_id?: string | null;
  entity_type?: string | null;
  source_key?: string | null;
  status?: "open" | "in_progress" | "snoozed" | "resolved" | null;
  assigned_to?: string | null;
  estimated_cost?: number | null;
  resolution_note?: string | null;
  snoozed_until?: string | null;
  assigned_profile?: { name?: string | null; email?: string | null } | null;
};

export type LowStockSparePartAlertRow = {
  id: string;
  name_ar: string;
  stock_quantity: number;
  min_stock_alert: number;
  unit: string;
};

export type CommercialRecordRenewalCostRow = {
  name: string;
  residency_renewal_monthly_cost: number | null;
  residency_renewal_cost_period?: "monthly" | "yearly" | null;
};

const commercialRecordKey = (value: string | null | undefined) => (value ?? "").trim().toLocaleLowerCase();

type ResidencyRenewalQuote = {
  cost: number | null;
  period: "monthly" | "yearly" | null;
  durationLabel: string | null;
};

const getRequiredMonthlyRenewalMonths = (expiryDate: Date, today: Date) => {
  const elapsedCalendarMonths = Math.max(0, differenceInCalendarMonths(today, expiryDate));
  const renewalBoundary = addMonths(expiryDate, elapsedCalendarMonths);
  const monthsUntilValid = isBefore(renewalBoundary, startOfDay(today))
    ? elapsedCalendarMonths + 1
    : Math.max(1, elapsedCalendarMonths);
  return Math.max(3, Math.ceil(monthsUntilValid / 3) * 3);
};

const getRequiredYearlyRenewals = (expiryDate: Date, today: Date) => {
  const elapsedCalendarYears = Math.max(0, differenceInCalendarYears(today, expiryDate));
  const renewalBoundary = addYears(expiryDate, elapsedCalendarYears);
  return isBefore(renewalBoundary, startOfDay(today))
    ? elapsedCalendarYears + 1
    : Math.max(1, elapsedCalendarYears);
};

const getDaysLeft = (dateValue: string, today: Date): number | null => {
  const date = parseISO(dateValue);
  if (!isValid(date)) return null;
  return differenceInCalendarDays(date, startOfDay(today));
};

const getYearDurationLabel = (years: number) => {
  if (years === 1) return "سنة واحدة";
  if (years === 2) return "سنتان";
  return `${years} سنوات`;
};

const getResidencyRenewalCost = (
  emp: EmployeeAlertRow,
  renewalCostByRecord: Map<string, CommercialRecordRenewalCostRow>,
  today: Date,
): ResidencyRenewalQuote => {
  const record = renewalCostByRecord.get(commercialRecordKey(emp.commercial_record));
  const rawCost = record?.residency_renewal_monthly_cost ?? null;
  if (rawCost === null || !Number.isFinite(rawCost) || rawCost < 0 || !emp.residency_expiry) {
    return { cost: null, period: null, durationLabel: null };
  }

  const period = record?.residency_renewal_cost_period === "yearly" ? "yearly" : "monthly";
  const expiryDate = parseISO(emp.residency_expiry);
  if (period === "yearly") {
    const renewalYears = getRequiredYearlyRenewals(expiryDate, today);
    return {
      cost: rawCost * renewalYears,
      period,
      durationLabel: getYearDurationLabel(renewalYears),
    };
  }

  const renewalMonths = getRequiredMonthlyRenewalMonths(expiryDate, today);
  return {
    cost: rawCost * renewalMonths,
    period,
    durationLabel: `${renewalMonths} شهر`,
  };
};

const getStandardSeverity = (daysLeft: number): Alert["severity"] => {
  if (daysLeft <= 7) return "urgent";
  if (daysLeft <= 14) return "warning";
  return "info";
};

const getProbationSeverity = (daysLeft: number): Alert["severity"] => {
  if (daysLeft < 0) return "info";
  if (daysLeft <= 7) return "urgent";
  return "warning";
};

const shouldSkipEmployeeExpiryAlerts = (emp: EmployeeAlertRow) => {
  if (emp.status && emp.status.toLowerCase() !== 'active') {
    return true;
  }

  const invalidStatuses = ['absconded', 'expired', 'terminated', 'inactive', 'canceled', 'final_exit'];
  return Boolean(emp.sponsorship_status && invalidStatuses.includes(emp.sponsorship_status.toLowerCase()));
};

const buildResidencyAlert = (
  emp: EmployeeAlertRow,
  today: Date,
  renewalCostByRecord: Map<string, CommercialRecordRenewalCostRow>
): Alert | null => {
  if (!emp.residency_expiry) return null;
  const daysLeft = getDaysLeft(emp.residency_expiry, today);
  if (daysLeft === null) return null;
  const renewal = getResidencyRenewalCost(emp, renewalCostByRecord, today);
  return {
    id: `res-${emp.id}`,
    sourceKey: `res-${emp.id}`,
    entityId: emp.id,
    entityType: "employee",
    type: "residency",
    entityName: emp.name,
    dueDate: emp.residency_expiry,
    daysLeft,
    severity: getStandardSeverity(daysLeft),
    resolved: false,
    residencyRenewalCost: renewal.cost,
    residencyRenewalCostPeriod: renewal.period,
    commercialRecordName: emp.commercial_record?.trim() || null,
    renewalDurationLabel: renewal.durationLabel,
  };
};

type EmployeeDateAlertInput = {
  id: string;
  type: string;
  employee: EmployeeAlertRow;
  dueDate: string | null | undefined;
  today: Date;
  severityForDays: (daysLeft: number) => Alert["severity"];
};

const buildEmployeeDateAlert = ({
  id,
  type,
  employee,
  dueDate,
  today,
  severityForDays,
}: EmployeeDateAlertInput): Alert | null => {
  if (!dueDate) return null;
  const daysLeft = getDaysLeft(dueDate, today);
  if (daysLeft === null) return null;
  return {
    id,
    sourceKey: id,
    entityId: id.slice(id.indexOf("-") + 1),
    entityType: "employee",
    type,
    entityName: employee.name,
    dueDate,
    daysLeft,
    severity: severityForDays(daysLeft),
    resolved: false,
    commercialRecordName: employee.commercial_record?.trim() || null,
  };
};

const pushIfDue = (out: Alert[], alert: Alert | null, threshold: string) => {
  if (alert && alert.dueDate <= threshold) {
    out.push(alert);
  }
};

/** عدد الأيام قبل تاريخ استحقاق الإيجار لإظهار التنبيه */
const RENTAL_ALERT_LEAD_DAYS = 5;

const getRentalSeverity = (daysLeft: number): Alert["severity"] => {
  if (daysLeft <= 1) return "urgent";
  if (daysLeft <= 3) return "warning";
  return "info";
};

const pushVehicleRentalAlerts = (
  out: Alert[],
  vehicles: VehicleRentalAlertRow[] | null | undefined,
  today: Date
) => {
  if (!vehicles?.length) return;
  for (const v of vehicles) {
    if (v.status !== "rental" || !v.rental_start_date) continue;
    const dueDate = getNextMonthlyRentalDueDate(v.rental_start_date, today);
    if (!dueDate) continue;
    const dueDateStr = format(dueDate, ISO_DATE_FORMAT);
    const daysLeft = differenceInCalendarDays(dueDate, today);
    // إظهار التنبيه فقط متى كان الاستحقاق خلال نافذة RENTAL_ALERT_LEAD_DAYS
    if (daysLeft > RENTAL_ALERT_LEAD_DAYS) continue;
    out.push({
      id: `rental-${v.id}`,
      sourceKey: `rental-${v.id}`,
      entityId: v.id,
      entityType: "vehicle",
      type: "vehicle_rental",
      entityName: `مركبة ${v.plate_number}`,
      description: "استحقاق الإيجار الشهري",
      dueDate: dueDateStr,
      daysLeft,
      severity: getRentalSeverity(daysLeft),
      resolved: false,
      estimatedCost: v.rental_monthly_amount,
    });
  }
};

const pushEmployeeExpiryAlerts = (
  generatedAlerts: Alert[],
  emp: EmployeeAlertRow,
  threshold: string,
  today: Date,
  renewalCostByRecord: Map<string, CommercialRecordRenewalCostRow>
) => {
  if (shouldSkipEmployeeExpiryAlerts(emp)) return;

  pushIfDue(generatedAlerts, buildResidencyAlert(emp, today, renewalCostByRecord), threshold);
  pushIfDue(generatedAlerts, buildEmployeeDateAlert({ id: `prob-${emp.id}`, type: "probation", employee: emp, dueDate: emp.probation_end_date, today, severityForDays: getProbationSeverity }), threshold);
  pushIfDue(generatedAlerts, buildEmployeeDateAlert({ id: `hi-${emp.id}`, type: "health_insurance", employee: emp, dueDate: emp.health_insurance_expiry, today, severityForDays: getStandardSeverity }), threshold);
  pushIfDue(generatedAlerts, buildEmployeeDateAlert({ id: `lic-${emp.id}`, type: "driving_license", employee: emp, dueDate: emp.license_expiry, today, severityForDays: getStandardSeverity }), threshold);
};

const vehicleTypeLabelAr = (type: string | null | undefined): string => {
  if (type === "motorcycle") return "دباب";
  if (type === "car") return "سيارة";
  return type?.trim() ? type : "مركبة";
};

const pushAbscondedSummaryAlerts = (
  out: Alert[],
  rows: AbscondedEmployeeAlertRow[] | null | undefined,
  today: Date
) => {
  if (!rows?.length) return;
  const dueDate = format(today, ISO_DATE_FORMAT);
  for (const emp of rows) {
    const openAssignments = (emp.vehicle_assignments ?? []).filter((va) => !va.end_date);
    const custodyParts = openAssignments
      .map((va) => va.vehicles)
      .filter((v): v is NonNullable<typeof v> => Boolean(v))
      .map((v) => `${vehicleTypeLabelAr(v.type)} ${v.plate_number}`);
    const custody = custodyParts.length ? custodyParts.join("، ") : "لا عهدة مركبة مفتوحة";

    const platformNames = (emp.employee_apps ?? [])
      .filter((ea) => (ea.status ?? "").toLowerCase() === "active")
      .map((ea) => ea.apps?.name)
      .filter((n): n is string => Boolean(n?.trim()));
    const platforms =
      platformNames.length > 0 ? `حسابات منصات نشطة: ${platformNames.join("، ")}` : "لا يوجد ربط منصة نشط";

    out.push({
      id: `absconded-${emp.id}`,
      sourceKey: `absconded-${emp.id}`,
      entityId: emp.id,
      entityType: "employee",
      type: "employee_absconded",
      entityName: emp.name,
      description: `حالة هروب. العهدة: ${custody}. ${platforms}.`,
      dueDate,
      daysLeft: 0,
      severity: "urgent",
      resolved: false,
    });
  }
};

const pushVehicleExpiryAlerts = (
  out: Alert[],
  vehicles: VehicleExpiryRow[] | null | undefined,
  threshold: string,
  today: Date
) => {
  if (!vehicles?.length) return;
  for (const v of vehicles) {
    if (v.insurance_expiry && v.insurance_expiry <= threshold) {
      const days = getDaysLeft(v.insurance_expiry, today);
      if (days === null) continue;
      out.push({
        id: `ins-${v.id}`,
        sourceKey: `ins-${v.id}`,
        entityId: v.id,
        entityType: "vehicle",
        type: "insurance",
        entityName: `مركبة ${v.plate_number}`,
        dueDate: v.insurance_expiry,
        daysLeft: days,
        severity: getStandardSeverity(days),
        resolved: false,
      });
    }
    if (v.authorization_expiry && v.authorization_expiry <= threshold) {
      const days = getDaysLeft(v.authorization_expiry, today);
      if (days === null) continue;
      out.push({
        id: `auth-${v.id}`,
        sourceKey: `auth-${v.id}`,
        entityId: v.id,
        entityType: "vehicle",
        type: "authorization",
        entityName: `مركبة ${v.plate_number}`,
        dueDate: v.authorization_expiry,
        daysLeft: days,
        severity: getStandardSeverity(days),
        resolved: false,
      });
    }
  }
};

const pushPlatformAccountAlerts = (out: Alert[], rows: PlatformAccountAlertRow[], today: Date) => {
  for (const acc of rows) {
    if (!acc.iqama_expiry_date) continue;
    const days = getDaysLeft(acc.iqama_expiry_date, today);
    if (days === null) continue;
    const appName = acc.apps?.name ?? "منصة";
    const expiryFormatted = format(parseISO(acc.iqama_expiry_date), "dd/MM/yyyy");
    out.push({
      id: `pla-${acc.id}`,
      sourceKey: `pla-${acc.id}`,
      entityId: acc.id,
      entityType: "platform_account",
      type: "platform_account",
      entityName: `${acc.account_username} — ${appName}`,
      description: `تنتهي إقامة الحساب في ${expiryFormatted} وقد يتوقف الحساب.`,
      dueDate: acc.iqama_expiry_date,
      daysLeft: days,
      severity: getStandardSeverity(days),
      resolved: false,
    });
  }
};

const pushPersistedDbAlerts = (out: Alert[], rows: PersistedAlertRow[], today: Date) => {
  for (const a of rows) {
    const dueDate = a.due_date ?? format(today, ISO_DATE_FORMAT);
    const daysLeft = getDaysLeft(dueDate, today) ?? 0;
    const details = a.details ?? {};
    const detailsEmployeeName = typeof details.employee_name === "string" ? details.employee_name : null;
    const entityName = detailsEmployeeName ?? a.message ?? "—";
    const workflowStatus = a.status ?? (a.is_resolved ? "resolved" : "open");
    const generatedAlert = a.source_key
      ? out.find((candidate) => candidate.sourceKey === a.source_key)
      : undefined;
    const workflowFields = {
      persisted: true,
      persistedId: a.id,
      workflowStatus,
      assignedTo: a.assigned_to ?? null,
      assignedName: a.assigned_profile?.name ?? a.assigned_profile?.email ?? null,
      estimatedCost: a.estimated_cost ?? null,
      resolutionNote: a.resolution_note ?? null,
      snoozedUntil: a.snoozed_until ?? null,
      resolved: workflowStatus === "resolved" || !!a.is_resolved,
    };

    const isLegacySnooze = workflowStatus === "snoozed" && a.snoozed_until === a.due_date;
    const isSameOccurrence = !a.due_date || a.due_date === generatedAlert?.dueDate || isLegacySnooze;

    if (generatedAlert && isSameOccurrence) {
      Object.assign(generatedAlert, workflowFields, {
        estimatedCost: a.estimated_cost ?? generatedAlert.estimatedCost ?? null,
      });
      continue;
    }

    out.push({
      id: generatedAlert ? a.id : (a.source_key ?? a.id),
      sourceKey: a.source_key ?? undefined,
      entityId: a.entity_id ?? null,
      entityType: a.entity_type ?? null,
      type: a.type,
      entityName,
      dueDate,
      daysLeft,
      severity: getStandardSeverity(daysLeft),
      ...workflowFields,
    });
  }
};

export type AlertSourceResponses = {
  employeesRes: { data: EmployeeAlertRow[] | null };
  vehiclesRes: { data: VehicleExpiryRow[] | null };
  platformAccountsRes: { data: PlatformAccountAlertRow[] | null };
  dbAlertsRes: { data: PersistedAlertRow[] | null };
  sparePartsRes: { data: LowStockSparePartAlertRow[] | null };
  abscondedRes: { data: AbscondedEmployeeAlertRow[] | null };
  commercialRecordsRes: { data: CommercialRecordRenewalCostRow[] | null };
  rentalVehiclesRes: { data: VehicleRentalAlertRow[] | null };
};

export function buildAlertsFromResponses(
  responses: AlertSourceResponses,
  threshold: string,
  today: Date
): Alert[] {
  const { employeesRes, vehiclesRes, platformAccountsRes, dbAlertsRes, sparePartsRes: _sparePartsRes, abscondedRes, commercialRecordsRes, rentalVehiclesRes } = responses;
  const generatedAlerts: Alert[] = [];
  const employees = employeesRes.data ?? [];
  const platformAccounts = platformAccountsRes.data ?? [];
  const dbAlerts = dbAlertsRes.data ?? [];
  const absconded = abscondedRes.data ?? [];
  const renewalCostByRecord = new Map(
    (commercialRecordsRes.data ?? [])
      .filter((record) => record.name?.trim())
      .map((record) => [commercialRecordKey(record.name), record] as const)
  );
  employees.forEach((emp) => pushEmployeeExpiryAlerts(generatedAlerts, emp, threshold, today, renewalCostByRecord));
  pushVehicleExpiryAlerts(generatedAlerts, vehiclesRes.data, threshold, today);
  pushVehicleRentalAlerts(generatedAlerts, rentalVehiclesRes.data, today);
  pushPlatformAccountAlerts(generatedAlerts, platformAccounts, today);
  // Inventory alerts disabled per user request
  pushPersistedDbAlerts(generatedAlerts, dbAlerts, today);
  pushAbscondedSummaryAlerts(generatedAlerts, absconded, today);
  generatedAlerts.sort((a, b) => a.daysLeft - b.daysLeft);
  return generatedAlerts;
}
