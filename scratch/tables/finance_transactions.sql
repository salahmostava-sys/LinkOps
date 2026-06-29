CREATE TABLE IF NOT EXISTS public.finance_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense')),
  category TEXT NOT NULL,
  description TEXT,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  month_year TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  is_auto BOOLEAN NOT NULL DEFAULT false,
  reference_type TEXT,
  reference_id UUID,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_month ON public.finance_transactions(month_year);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_type ON public.finance_transactions(type);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_date ON public.finance_transactions(date);
ALTER TABLE public.finance_transactions ENABLE ROW LEVEL SECURITY;

-- FILE: 20260413000000_fix_sponsorship_alert_cr_number.sql
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  msg TEXT;
  accounts_json JSONB;
  vehicles_json JSONB;
  trade_json JSONB;
BEGIN
  status := NEW.sponsorship_status::TEXT;
  IF (NEW.sponsorship_status IS DISTINCT FROM OLD.sponsorship_status)
     AND (status IN ('absconded', 'terminated')) THEN
    IF status = 'terminated' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.platform_accounts WHERE employee_id = NEW.id
      ) THEN
        RETURN NEW;
      END IF;
    END IF;
    SELECT
      STRING_AGG(format('%s: %s', a.name, pa.account_username), ', ' ORDER BY a.name),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'app', a.name,
          'username', pa.account_username,
          'account_id_on_platform', pa.account_id_on_platform,
          'iqama_number', pa.iqama_number
        )
      ), '[]'::jsonb)
    INTO account_list, accounts_json
    FROM public.platform_accounts pa
    JOIN public.apps a ON a.id = pa.app_id
    WHERE pa.employee_id = NEW.id;
    SELECT
      COUNT(*)::int,
      STRING_AGG(v.plate_number, ', ' ORDER BY v.plate_number),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT('vehicle_id', v.id, 'plate_number', v.plate_number)
      ), '[]'::jsonb)
    INTO vehicle_count, vehicle_plate_list, vehicles_json
    FROM public.vehicle_assignments va
    JOIN public.vehicles v ON v.id = va.vehicle_id
    WHERE va.employee_id = NEW.id
      AND va.end_date IS NULL
      AND va.returned_at IS NULL;
    trade_name := NEW.commercial_record;
    trade_json := JSONB_BUILD_OBJECT('name', COALESCE(NEW.commercial_record, ''));
    msg :=
      format(
        'الموظف: %s (الهوية: %s) | منصات: %s | مركبات: %s | سجل تجاري: %s',
        COALESCE(NEW.name, '—'),
        COALESCE(NEW.national_id, '—'),
        COALESCE(account_list, '—'),
        COALESCE(vehicle_plate_list, CASE WHEN vehicle_count IS NULL THEN '—' ELSE vehicle_count::TEXT || ' مركبة' END),
        COALESCE(trade_name, '—')
      );
    INSERT INTO public.alerts (
      type,
      entity_id,
      entity_type,
      due_date,
      message,
      details
    )
    VALUES (
      CASE WHEN status = 'absconded' THEN 'employee_absconded' ELSE 'employee_terminated' END,
      NEW.id,
      'employee',
      CURRENT_DATE,
      msg,
      JSONB_BUILD_OBJECT(
        'employee_id', NEW.id,
        'employee_name', NEW.name,
        'national_id', NEW.national_id,
        'sponsorship_status', status,
        'platform_accounts', accounts_json,
        'vehicle_count', COALESCE(vehicle_count, 0),
        'vehicle_plates', COALESCE(vehicle_plate_list, ''),
        'vehicles', vehicles_json,
        'trade_register', trade_json
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = 'public';

-- FILE: 20260413090000_fix_salary_preview_skip_unlinked_platforms.sql
BEGIN;
COMMENT ON FUNCTION public.preview_salary_for_month IS
  'Preview salary while ignoring apps that no longer have a linked salary scheme.';
COMMIT;

-- FILE: 20260413100000_fix_salary_rpc_flat_rate_and_scheme.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(INTEGER) CASCADE;

-- FILE: 20260414000000_add_salary_slip_template_columns.sql
ALTER TABLE public.finance_transactions
  DROP CONSTRAINT IF EXISTS finance_transactions_created_by_fkey;
ALTER TABLE public.finance_transactions
  ADD CONSTRAINT finance_transactions_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- FILE: 20260504000001_fix_security_warnings_v3.sql
﻿-- ============================================================
ALTER FUNCTION public.is_salary_admin_job_title(text) SET search_path = public;
CREATE OR REPLACE FUNCTION public.is_admin_or_hr(uid uuid) RETURNS boolean AS $$
BEGIN
  RETURN is_active_user(uid) AND (has_role(uid, _const_role_admin()) OR has_role(uid, _const_role_hr()));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.dashboard_overview_rpc(text, integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(text, text, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(text, date) SECURITY INVOKER;
ALTER FUNCTION public.performance_dashboard_rpc(text, date) SECURITY INVOKER;
ALTER FUNCTION public.rider_profile_performance_rpc(uuid, text, date) SECURITY INVOKER;
ALTER FUNCTION public.calculate_salary_for_month(text, text) SECURITY INVOKER;
ALTER FUNCTION public.capture_salary_month_snapshot(text) SECURITY INVOKER;
ALTER FUNCTION public.preview_salary_for_month(text) SECURITY INVOKER;
ALTER FUNCTION public.advance_in_my_company(uuid) SECURITY INVOKER;
ALTER FUNCTION public.calculate_employee_salary(uuid, text, text, numeric, text) SECURITY INVOKER;
ALTER FUNCTION public.calculate_order_salary_for_app(uuid, integer, integer, uuid[], boolean) SECURITY INVOKER;
ALTER FUNCTION public.calculate_salary(uuid, text, text, numeric, text) SECURITY INVOKER;
ALTER FUNCTION public.check_employee_operational_records(uuid) SECURITY INVOKER;
ALTER FUNCTION public.check_in(uuid, timestamp with time zone) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(text, integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(text, text, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.employee_in_my_company(uuid) SECURITY INVOKER;
ALTER FUNCTION public.is_salary_month_visible_employee(uuid, text, text, text, text) SECURITY INVOKER;
ALTER FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) SECURITY INVOKER;

-- FILE: 20260504000002_fix_logo_upload.sql
UPDATE storage.buckets
SET 
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/gif'],
  file_size_limit = 5242880
WHERE id = 'avatars';

-- FILE: 20260504000003_fix_remaining_security_warnings.sql
ALTER FUNCTION public.is_salary_month_visible_employee(uuid, text, text, text, text) SECURITY INVOKER;

-- FILE: 20260510000000_fix_employee_status_cast.sql
BEGIN;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_cast
    WHERE castsource = 'text'::regtype
      AND casttarget = 'public.employee_status'::regtype
      AND castcontext = 'i'  -- 'i' = implicit
  ) THEN
    CREATE CAST (text AS public.employee_status)
      WITH FUNCTION public.text_to_employee_status(text)
      AS IMPLICIT;
  END IF;
END $$;
COMMIT;

-- FILE: 20260510010000_fix_security_warnings.sql
﻿-- =============================================================================
COMMIT;

-- FILE: 20260511000000_auto_enum_operators.sql
DO $$
DECLARE
  e record;
  func_eq1 text;
  func_eq2 text;
  func_neq1 text;
  func_neq2 text;
BEGIN
  FOR e IN 
    SELECT t.typname
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typtype = 'e' AND n.nspname = 'public'
  LOOP
    func_eq1 := 'eq_' || e.typname || '_text';
    func_eq2 := 'eq_text_' || e.typname;
    func_neq1 := 'neq_' || e.typname || '_text';
    func_neq2 := 'neq_text_' || e.typname;
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a::text = b; $f$;', func_eq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a = b::text; $f$;', func_eq2, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a::text <> b; $f$;', func_neq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a <> b::text; $f$;', func_neq2, e.typname);
    EXECUTE format('DROP OPERATOR IF EXISTS public.= (public.%I, text)', e.typname);
    EXECUTE format('CREATE OPERATOR public.= (LEFTARG = public.%I, RIGHTARG = text, PROCEDURE = public.%I, COMMUTATOR = ''='')', e.typname, func_eq1);
    EXECUTE format('DROP OPERATOR IF EXISTS public.= (text, public.%I)', e.typname);
    EXECUTE format('CREATE OPERATOR public.= (LEFTARG = text, RIGHTARG = public.%I, PROCEDURE = public.%I, COMMUTATOR = ''='')', e.typname, func_eq2);
    EXECUTE format('DROP OPERATOR IF EXISTS public.<> (public.%I, text)', e.typname);
    EXECUTE format('CREATE OPERATOR public.<> (LEFTARG = public.%I, RIGHTARG = text, PROCEDURE = public.%I, COMMUTATOR = ''<>'')', e.typname, func_neq1);
    EXECUTE format('DROP OPERATOR IF EXISTS public.<> (text, public.%I)', e.typname);
    EXECUTE format('CREATE OPERATOR public.<> (LEFTARG = text, RIGHTARG = public.%I, PROCEDURE = public.%I, COMMUTATOR = ''<>'')', e.typname, func_neq2);
  END LOOP;
END $$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260605000000_fix_rpc_security_definer.sql
WITH ranked AS (
  SELECT
    id,
    user_id,
    role,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY CASE role
        WHEN 'admin'      THEN 1
        WHEN 'finance'    THEN 2
        WHEN 'hr'         THEN 3
        WHEN 'operations' THEN 4
        WHEN 'viewer'     THEN 5
        ELSE 99
      END
    ) AS rn
  FROM public.user_roles
)
DELETE FROM public.user_roles
WHERE id IN (
  SELECT id FROM ranked WHERE rn > 1
);
ALTER FUNCTION public.performance_dashboard_rpc(text, date)
  SECURITY DEFINER
  SET search_path = public;
ALTER FUNCTION public.rider_profile_performance_rpc(uuid, text, date)
  SECURITY DEFINER
  SET search_path = public;

-- FILE: 20260606000000_fix_ambiguous_column_references.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: ambiguous employee_id column reference in daily_shifts query (lint error 42702)';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS
  'Fixed: ambiguous employee_id column reference in daily_shifts query (lint error 42702)';
COMMENT ON FUNCTION public.preview_salary_for_month_v2(TEXT) IS
  'Fixed: removed unused variable c_days_per_month (lint warning)';

-- FILE: 20260606000001_fix_advance_due_date_and_unused_vars.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: ai.due_date → ai.month_year (advance_installments has no due_date column)';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS
  'Fixed: removed unused v_tier variable (lint warning)';

-- FILE: 20260606000002_fix_external_deductions_columns.sql
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: external_deductions uses apply_month + approval_status (not month_year/status)';

-- FILE: 20260606000003_fix_enum_search_path_and_duplicate_indexes.sql
DO $$
DECLARE
  e record;
  func_eq1 text;
  func_eq2 text;
  func_neq1 text;
  func_neq2 text;
BEGIN
  FOR e IN
    SELECT t.typname
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typtype = 'e' AND n.nspname = 'public'
  LOOP
    func_eq1 := 'eq_' || e.typname || '_text';
    func_eq2 := 'eq_text_' || e.typname;
    func_neq1 := 'neq_' || e.typname || '_text';
    func_neq2 := 'neq_text_' || e.typname;
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a::text = b; $f$;', func_eq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a = b::text; $f$;', func_eq2, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a::text <> b; $f$;', func_neq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a <> b::text; $f$;', func_neq2, e.typname);
  END LOOP;
END $$;
DROP INDEX IF EXISTS public.uq_attendance_employee_date;
DROP INDEX IF EXISTS public.salary_slip_templates_one_default_idx;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000004_fix_emp_status_search_path.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000006_consolidate_rls_policies.sql
﻿-- Migration to consolidate multiple permissive RLS policies
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000007_unified_rls_policies.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_salary_scheme_tiers_scheme_id" ON public."salary_scheme_tiers" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_employee_id" ON public."employee_scheme" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_scheme_id" ON public."employee_scheme" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_vehicle_id" ON public."vehicle_assignments" ("vehicle_id");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_employee_id" ON public."vehicle_assignments" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_vehicle_id" ON public."maintenance_logs_legacy_pre_fleet" ("vehicle_id");
CREATE INDEX IF NOT EXISTS "idx_advances_employee_id" ON public."advances" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_advance_id" ON public."advance_installments" ("advance_id");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_employee_id" ON public."external_deductions" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_source_app_id" ON public."external_deductions" ("source_app_id");
CREATE INDEX IF NOT EXISTS "idx_apps_scheme_id" ON public."apps" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_positions_department_id" ON public."positions" ("department_id");
CREATE INDEX IF NOT EXISTS "idx_employees_department_id" ON public."employees" ("department_id");
CREATE INDEX IF NOT EXISTS "idx_employees_position_id" ON public."employees" ("position_id");
CREATE INDEX IF NOT EXISTS "idx_employee_tiers_employee_id" ON public."employee_tiers" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_assigned_by" ON public."employee_scheme" ("assigned_by");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_created_by" ON public."vehicle_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_platform_accounts_app_id" ON public."platform_accounts" ("app_id");
CREATE INDEX IF NOT EXISTS "idx_platform_accounts_employee_id" ON public."platform_accounts" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_roles_assigned_by" ON public."employee_roles" ("assigned_by");
CREATE INDEX IF NOT EXISTS "idx_leave_requests_reviewer_id" ON public."leave_requests" ("reviewer_id");
CREATE INDEX IF NOT EXISTS "idx_leave_requests_created_by" ON public."leave_requests" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_attendance_created_by" ON public."attendance" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_daily_orders_created_by" ON public."daily_orders" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advances_approved_by" ON public."advances" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_approved_by" ON public."external_deductions" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_approved_by" ON public."salary_records" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_pl_records_created_by" ON public."pl_records" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_alerts_resolved_by" ON public."alerts" ("resolved_by");
CREATE INDEX IF NOT EXISTS "idx_audit_log_user_id" ON public."audit_log" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_admin_action_log_user_id" ON public."admin_action_log" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_employees_created_by" ON public."employees" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_employees_updated_by" ON public."employees" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_daily_orders_updated_by" ON public."daily_orders" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_attendance_updated_by" ON public."attendance" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_advances_created_by" ON public."advances" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advances_updated_by" ON public."advances" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_created_by" ON public."advance_installments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_updated_by" ON public."advance_installments" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_created_by" ON public."external_deductions" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_updated_by" ON public."external_deductions" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_created_by" ON public."salary_records" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_updated_by" ON public."salary_records" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_pl_records_updated_by" ON public."pl_records" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_user_roles_created_by" ON public."user_roles" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_user_roles_updated_by" ON public."user_roles" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_locked_months_locked_by" ON public."locked_months" ("locked_by");
CREATE INDEX IF NOT EXISTS "idx_supervisor_employee_assignments_created_by" ON public."supervisor_employee_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_supervisor_targets_created_by" ON public."supervisor_targets" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_slip_templates_created_by" ON public."salary_slip_templates" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_employee_id" ON public."maintenance_logs_legacy_pre_fleet" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_hr_performance_reviews_reviewer_id" ON public."hr_performance_reviews" ("reviewer_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_employee_id" ON public."maintenance_logs" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_account_assignments_created_by" ON public."account_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_finance_transactions_created_by" ON public."finance_transactions" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_month_snapshots_captured_by" ON public."salary_month_snapshots" ("captured_by");
CREATE INDEX IF NOT EXISTS "idx_employee_targets_created_by" ON public."employee_targets" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_order_import_batches_target_app_id" ON public."order_import_batches" ("target_app_id");
CREATE INDEX IF NOT EXISTS "idx_order_import_batches_started_by" ON public."order_import_batches" ("started_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");

-- FILE: 20260606000012_fix_remaining_fkeys.sql
CREATE INDEX IF NOT EXISTS "idx_employee_apps_app_id" ON public."employee_apps" ("app_id");
CREATE INDEX IF NOT EXISTS "idx_salary_drafts_employee_id" ON public."salary_drafts" ("employee_id");

-- FILE: 20260606000013_restore_rls_security_definer.sql
ALTER FUNCTION public.has_role(_user_id uuid, _role app_role) SECURITY DEFINER;
ALTER FUNCTION public.get_my_role() SECURITY DEFINER;
ALTER FUNCTION public.has_permission(p_resource text, p_action text) SECURITY DEFINER;
ALTER FUNCTION public.is_internal_user() SECURITY DEFINER;
ALTER FUNCTION public.is_admin_or_hr(uid uuid) SECURITY DEFINER;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000014_fix_rls_performance_timeouts.sql
ALTER FUNCTION public.employee_in_my_company(_employee_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.advance_in_my_company(_advance_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.is_active_user(_user_id uuid) SET search_path = public;
ALTER FUNCTION public.has_role(_user_id uuid, _role app_role) SET search_path = public;
ALTER FUNCTION public.get_my_role() SET search_path = public;
ALTER FUNCTION public.has_permission(p_resource text, p_action text) SET search_path = public;
ALTER FUNCTION public.is_internal_user() SET search_path = public;
ALTER FUNCTION public.is_admin_or_hr(uid uuid) SET search_path = public;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000015_fix_rpc_performance_timeouts.sql
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT p.oid::regprocedure::text AS func_signature
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname IN (
            'dashboard_overview_rpc',
            'dashboard_overview',
            'performance_dashboard_rpc',
            'rider_profile_performance_rpc',
            'preview_salary_for_month',
            'preview_salary_for_month_v2',
            'calculate_employee_salary',
            'calculate_order_salary_for_app',
            'calculate_salary',
            'calculate_salary_for_month',
            'capture_salary_month_snapshot',
            'assign_platform_account',
            'replace_daily_orders_month_rpc'
          )
    LOOP
        EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER SET search_path = public;', rec.func_signature);
    END LOOP;
END
$$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628000003_fix_database_linter_warnings.sql
ALTER FUNCTION public.calc_tier_salary(integer, uuid) SET search_path = public;

-- FILE: 20260628000004_prioritize_app_scheme_over_pricing_rules.sql
BEGIN;
COMMIT;

-- FILE: 20260628000005_fix_preview_salary_for_month_to_use_app_salary.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
COMMIT;

-- FILE: 20260628000006_fix_recursive_role_const_functions.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628130000_fix_rls_policies_with_constants.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628135000_add_performance_indexes.sql
CREATE INDEX IF NOT EXISTS idx_employees_name ON public.employees(name);
CREATE INDEX IF NOT EXISTS idx_daily_orders_date ON public.daily_orders(date);

-- FILE: 20260628170000_fix_performance_dashboard_rpc_500.sql
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260629171000_restore_performance_dashboard_rpc_real.sql
NOTIFY pgrst, 'reload schema';
