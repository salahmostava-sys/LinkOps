-- REVIEW-ONLY CONSOLIDATION DRAFT. DO NOT APPLY TO PRODUCTION.
-- Inferred from migration history; compare with `supabase db dump --schema public`.
-- Table: public.employees

-- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
CREATE TABLE IF NOT EXISTS public.employees (
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  name TEXT NOT NULL,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  name_en TEXT,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  phone TEXT,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  national_id TEXT UNIQUE,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  iban TEXT,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  is_sponsored BOOLEAN NOT NULL DEFAULT false,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  dob DATE,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  residency_expiry DATE,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  license_has BOOLEAN NOT NULL DEFAULT false,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  license_expiry DATE,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  email TEXT,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  salary_type public.salary_type NOT NULL DEFAULT _const_work_orders(),
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  base_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  allowances JSONB DEFAULT '{}',
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  status public.employee_status NOT NULL DEFAULT _const_employee_active(),
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  job_title text,
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  bank_account_number text,
  -- Source: 20260404010000_cleanup_employee_code_and_employee_cities.sql
  city text,
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  join_date date,
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  license_status public.license_status_enum DEFAULT 'no_license',
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  sponsorship_status public.sponsorship_status_enum DEFAULT 'not_sponsored',
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  id_photo_url text,
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  license_photo_url text,
  -- Source: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
  personal_photo_url text,
  -- Source: 20260404010000_cleanup_employee_code_and_employee_cities.sql
  preferred_language text NOT NULL DEFAULT 'ar',
  -- Source: 20260308160244_08e17ad0-0a55-4ec5-b5f2-a2dc4ea0e6b0.sql
  nationality text,
  -- Source: 20260308160641_33fe96e5-0f81-4488-8186-8436064285db.sql
  birth_date date,
  -- Source: 20260309004512_08955870-3030-4d1b-841a-781651a23ca5.sql
  department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  -- Source: 20260309004512_08955870-3030-4d1b-841a-781651a23ca5.sql
  position_id UUID REFERENCES public.positions(id) ON DELETE SET NULL,
  -- Source: 20260318000852_1d17194a-ce8c-4d75-840d-0226be68a413.sql
  probation_end_date date NULL,
  -- Source: 20260318091031_ea72075a-49eb-4399-bdcb-7f2bb16bc19a.sql
  health_insurance_expiry date,
  -- Source: 20260324193000_erd_foundation_roles_salary_structure.sql
  role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL,
  -- Source: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  -- Source: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  -- Source: 20260403000000_add_commercial_record_to_employees.sql
  commercial_record TEXT,
  -- Source: 20260404010000_cleanup_employee_code_and_employee_cities.sql
  cities text[] DEFAULT '{}'::text[],
  -- Source: 20260407110000_employee_commercial_records_and_iqama_docs.sql
  iqama_photo_url text,
  -- Source: 20260325210500_employees_name_not_empty_check.sql
  CONSTRAINT employees_name_not_empty
  CHECK (name IS NOT NULL AND length(btrim(name)) > 0),
  -- Source: 20260404010000_cleanup_employee_code_and_employee_cities.sql
  CONSTRAINT employees_preferred_language_check
  CHECK (preferred_language IN ('ar', 'en'))
);

-- Source: 20260327130000_allow_attendance_viewers_to_read_employees.sql
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Trigger functions
-- Source: 20260330120000_salary_slip_templates.sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Source: 20260712051000_fix_alert_trigger_registration_number.sql
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  trade_cr TEXT;
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

    -- Use commercial_record name instead of the dropped company_id column
    trade_name := NEW.commercial_record;
    trade_cr := NULL;
    trade_json := '{}'::jsonb;

    IF NEW.commercial_record IS NOT NULL AND NEW.commercial_record <> '' THEN
      SELECT
        cr.name,
        cr.registration_number,
        JSONB_BUILD_OBJECT(
          'name', cr.name,
          'cr_number', cr.registration_number
        )
      INTO trade_name, trade_cr, trade_json
      FROM public.commercial_records cr
      WHERE cr.name = NEW.commercial_record
      LIMIT 1;
    END IF;

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
        'trade_register', trade_json,
        'trade_cr_number', trade_cr
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

-- Source: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
CREATE OR REPLACE FUNCTION public.set_audit_columns()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.created_by IS NULL THEN
      NEW.created_by := auth.uid();
    END IF;
    IF NEW.updated_by IS NULL THEN
      NEW.updated_by := auth.uid();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

-- Active policies
-- Source: 20260606000007_unified_rls_policies.sql
CREATE POLICY "unified_select_policy" ON "public"."employees" FOR SELECT
  USING (
    ((is_internal_user() AND (has_permission('employees'::text, 'view'::text) OR has_permission('attendance'::text, 'view'::text))))
  );

-- Source: 20260709224000_fix_all_rls_definitively.sql
CREATE POLICY "unified_insert_policy" ON public.employees FOR INSERT
WITH CHECK (
  is_active_user(auth.uid()) AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'hr'::app_role)
    OR has_role(auth.uid(), 'operations'::app_role)
    OR EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'employees'
        AND up.can_edit = true
    )
  )
);

-- Source: 20260709224000_fix_all_rls_definitively.sql
CREATE POLICY "unified_update_policy" ON public.employees FOR UPDATE
USING (
  is_active_user(auth.uid()) AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'hr'::app_role)
    OR has_role(auth.uid(), 'operations'::app_role)
    OR EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'employees'
        AND up.can_edit = true
    )
  )
)
WITH CHECK (
  is_active_user(auth.uid()) AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'hr'::app_role)
    OR has_role(auth.uid(), 'operations'::app_role)
    OR EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'employees'
        AND up.can_edit = true
    )
  )
);

-- Source: 20260709224000_fix_all_rls_definitively.sql
CREATE POLICY "unified_delete_policy" ON public.employees FOR DELETE
USING (
  is_active_user(auth.uid()) AND (
    has_role(auth.uid(), 'admin'::app_role)
    OR has_role(auth.uid(), 'hr'::app_role)
    OR has_role(auth.uid(), 'operations'::app_role)
    OR EXISTS (
      SELECT 1 FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.permission_key = 'employees'
        AND up.can_delete = true
    )
  )
);

-- Active triggers
-- Source: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
CREATE TRIGGER trg_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Source: 20260323170000_platform_accounts_employee_id_and_alerts_trigger.sql
CREATE TRIGGER trg_employee_sponsorship_alerts
  AFTER UPDATE OF sponsorship_status ON public.employees
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_handle_employee_sponsorship_alerts();

-- Source: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
CREATE TRIGGER trg_employees_set_audit_columns
  BEFORE INSERT OR UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.set_audit_columns();

-- Active indexes
-- Source: 20260324193000_erd_foundation_roles_salary_structure.sql
CREATE INDEX IF NOT EXISTS idx_employees_role_id ON public.employees(role_id);

-- Source: 20260407110000_employee_commercial_records_and_iqama_docs.sql
CREATE INDEX IF NOT EXISTS idx_employees_commercial_record
  ON public.employees (commercial_record)
  WHERE commercial_record IS NOT NULL;

-- Source: 20260407110000_employee_commercial_records_and_iqama_docs.sql
CREATE INDEX IF NOT EXISTS idx_employees_residency_expiry
  ON public.employees (residency_expiry)
  WHERE residency_expiry IS NOT NULL;

-- Source: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_employees_department_id" ON public."employees" ("department_id");

-- Source: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_employees_position_id" ON public."employees" ("position_id");

-- Source: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_employees_created_by" ON public."employees" ("created_by");

-- Source: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_employees_updated_by" ON public."employees" ("updated_by");

-- Source: 20260628135000_add_performance_indexes.sql
CREATE INDEX IF NOT EXISTS idx_employees_name ON public.employees(name);

-- MANUAL REVIEW REQUIRED
-- The statements below were not applied to the inferred state.
-- Source: 20260325154500_unify_company_id_on_employees.sql
-- Reason: DDL خاص بالجدول داخل كتلة إجرائية؛ لم يتم افتراض نتيجة التنفيذ
-- DO $$
-- BEGIN
--   IF NOT EXISTS (
--     SELECT 1
--     FROM pg_constraint
--     WHERE conname = 'employees_company_id_fkey'
--       AND conrelid = 'public.employees'::regclass
--   ) THEN
--     ALTER TABLE public.employees
--       ADD CONSTRAINT employees_company_id_fkey
--       FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
--   END IF;
-- END $$;
