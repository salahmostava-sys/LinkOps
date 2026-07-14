import { supabase } from "./supabase/client";
import { throwIfError } from "./serviceError";

type QueryError = { message?: string } | null;

export interface ResolveAlertResult {
  id: string;
}

export interface DeferAlertResult {
  id: string;
}

export interface AlertsSummary {
  unresolvedCount: number;
  urgentCount: number;
}

export type AlertWorkflowStatus = "open" | "in_progress" | "snoozed" | "resolved";

export type AlertWorkflowTarget = {
  persistedId?: string;
  sourceKey?: string;
  type: string;
  entityId?: string | null;
  entityType?: string | null;
  message: string;
  dueDate: string;
};

export type AlertWorkflowUpdate = {
  status: AlertWorkflowStatus;
  assignedTo: string | null;
  estimatedCost: number | null;
  resolutionNote: string | null;
  dueDate: string;
  actorId: string | null;
};

export type AssignableAlertUser = {
  id: string;
  name: string | null;
  email: string | null;
};

type AlertsFetchResult = [
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
  { data: unknown[] | null; error: QueryError },
];

export const alertsService = {
  fetchSummary: async (
    expiryHorizon: string,
    urgentHorizon: string,
  ): Promise<AlertsSummary> => {
    const { data, error } = await supabase.rpc("alerts_summary_rpc", {
      p_expiry_horizon: expiryHorizon,
      p_urgent_horizon: urgentHorizon,
    });
    throwIfError(error, "alertsService.fetchSummary");

    const summary = data as { unresolved_count?: unknown; urgent_count?: unknown } | null;
    return {
      unresolvedCount: Number(summary?.unresolved_count ?? 0),
      urgentCount: Number(summary?.urgent_count ?? 0),
    };
  },

  /**
   * @param expiryHorizon تاريخ ISO (yyyy-MM-dd): تنبيه لكل ما ينتهي قبل هذا التاريخ (حسب «أيام التنبيه» في الإعدادات)
   */
  fetchAlertsDataWithTimeout: async (
    expiryHorizon: string,
    timeoutMs: number
  ): Promise<AlertsFetchResult> => {
    const fetchAll = Promise.all([
      supabase
        .from("employees")
        .select("id, name, commercial_record, residency_expiry, probation_end_date, health_insurance_expiry, license_expiry, sponsorship_status, status")
        .eq("status", "active")
        .or(
          `residency_expiry.lte.${expiryHorizon},probation_end_date.lte.${expiryHorizon},health_insurance_expiry.lte.${expiryHorizon},license_expiry.lte.${expiryHorizon}`,
        ),
      supabase
        .from("vehicles")
        .select("id, plate_number, insurance_expiry, authorization_expiry")
        .in("status", ["active", "maintenance", "rental"])
        .or(`insurance_expiry.lte.${expiryHorizon},authorization_expiry.lte.${expiryHorizon}`),
      supabase
        .from("platform_accounts")
        .select("id, account_username, iqama_expiry_date, app_id, apps(name)")
        .eq("status", "active")
        .not("iqama_expiry_date", "is", null)
        .lte("iqama_expiry_date", expiryHorizon),
      supabase
        .from("alerts")
        .select("id, type, due_date, is_resolved, message, details, entity_id, entity_type, source_key, status, assigned_to, estimated_cost, resolution_note, snoozed_until, assigned_profile:profiles!alerts_assigned_to_fkey(name,email)")
        .order("created_at", { ascending: false })
        .limit(500),
      Promise.resolve({ data: [], error: null }), // Disabled spare_parts query per user request
      supabase
        .from("employees")
        .select(
          `
          id, name, sponsorship_status,
          vehicle_assignments(end_date, vehicles(plate_number, type)),
          employee_apps(status, apps(name))
        `,
        )
        .eq("sponsorship_status", "absconded")
        .eq("status", "active"),
      supabase
        .from("commercial_records")
        .select("name, residency_renewal_monthly_cost, residency_renewal_cost_period"),
      supabase
        .from("vehicles")
        .select("id, plate_number, rental_start_date, rental_monthly_amount, status")
        .eq("status", "rental")
        .not("rental_start_date", "is", null)
    ]);

    const timeoutError = () =>
      new Error("انتهت مهلة تحميل البيانات. تحقق من الاتصال ثم أعد فتح الصفحة.");

    let timeoutId: ReturnType<typeof setTimeout> | undefined;
    let results: AlertsFetchResult;
    try {
      results = await Promise.race([
        fetchAll,
        new Promise<never>((_, reject) => {
          timeoutId = setTimeout(() => reject(timeoutError()), timeoutMs);
        }),
      ]);
    } finally {
      if (timeoutId) clearTimeout(timeoutId);
    }

    const [employeesRes, vehiclesRes, platformAccountsRes, dbAlertsRes, sparePartsRes, abscondedRes, commercialRecordsRes, rentalVehiclesRes] = results;
    throwIfError(employeesRes.error, "alertsService.fetchAlertsDataWithTimeout.employees");
    throwIfError(vehiclesRes.error, "alertsService.fetchAlertsDataWithTimeout.vehicles");
    throwIfError(platformAccountsRes.error, "alertsService.fetchAlertsDataWithTimeout.platformAccounts");
    throwIfError(dbAlertsRes.error, "alertsService.fetchAlertsDataWithTimeout.alerts");
    throwIfError(abscondedRes.error, "alertsService.fetchAlertsDataWithTimeout.absconded");
    throwIfError(commercialRecordsRes.error, "alertsService.fetchAlertsDataWithTimeout.commercialRecords");
    throwIfError(rentalVehiclesRes.error, "alertsService.fetchAlertsDataWithTimeout.rentalVehicles");
    
    if (sparePartsRes.error) {
      results[4] = { data: [], error: null };
    }
    return results;
  },

  // Critical fix: resolve action persists in DB.
  resolveAlert: async (alertId: string, resolvedBy: string | null): Promise<ResolveAlertResult> => {
    const { data, error } = await supabase
      .from("alerts")
      .update({
        is_resolved: true,
        resolved_by: resolvedBy,
        status: "resolved",
        snoozed_until: null,
      })
      .eq("id", alertId)
      .select("id")
      .maybeSingle();
    throwIfError(error, "alertsService.resolveAlert");
    if (!data?.id) {
      throw new Error("alertsService.resolveAlert: alert not found");
    }
    return { id: data.id };
  },

  // Critical fix: defer action persists in DB.
  deferAlert: async (alertId: string, dueDate: string): Promise<DeferAlertResult> => {
    const { data, error } = await supabase
      .from("alerts")
      .update({
        due_date: dueDate,
        is_resolved: false,
        resolved_by: null,
        status: "snoozed",
        snoozed_until: dueDate,
      })
      .eq("id", alertId)
      .select("id")
      .maybeSingle();
    throwIfError(error, "alertsService.deferAlert");
    if (!data?.id) {
      throw new Error("alertsService.deferAlert: alert not found");
    }
    return { id: data.id };
  },

  fetchAssignableUsers: async (): Promise<AssignableAlertUser[]> => {
    const { data, error } = await supabase
      .from("profiles")
      .select("id, name, email")
      .eq("is_active", true)
      .order("name")
      .limit(200);
    throwIfError(error, "alertsService.fetchAssignableUsers");
    return data ?? [];
  },

  saveWorkflow: async (
    target: AlertWorkflowTarget,
    workflow: AlertWorkflowUpdate,
  ): Promise<{ id: string }> => {
    const isResolved = workflow.status === "resolved";
    const payload = {
      status: workflow.status,
      assigned_to: workflow.assignedTo,
      estimated_cost: workflow.estimatedCost,
      resolution_note: workflow.resolutionNote,
      due_date: workflow.dueDate,
      snoozed_until: workflow.status === "snoozed" ? workflow.dueDate : null,
      is_resolved: isResolved,
      resolved_by: isResolved ? workflow.actorId : null,
    };

    const query = target.persistedId
      ? supabase.from("alerts").update(payload).eq("id", target.persistedId)
      : supabase.from("alerts").upsert({
          ...payload,
          source_key: target.sourceKey,
          type: target.type,
          entity_id: target.entityId,
          entity_type: target.entityType,
          message: target.message,
        }, { onConflict: "source_key" });

    const { data, error } = await query.select("id").maybeSingle();
    throwIfError(error, "alertsService.saveWorkflow");
    if (!data?.id) throw new Error("alertsService.saveWorkflow: alert not found");
    return { id: data.id };
  },
};
