CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  phone TEXT,
  national_id TEXT UNIQUE,
  iban TEXT,
  is_sponsored BOOLEAN NOT NULL DEFAULT false,
  dob DATE,
  residency_expiry DATE,
  license_has BOOLEAN NOT NULL DEFAULT false,
  license_expiry DATE,
  email TEXT,
  salary_type public.salary_type NOT NULL DEFAULT _const_work_orders(),
  base_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
  allowances JSONB DEFAULT '{}',
  trade_register_id UUID REFERENCES public.trade_registers(id),
  status public.employee_status NOT NULL DEFAULT _const_employee_active(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS job_title text,
  ADD COLUMN IF NOT EXISTS bank_account_number text,
  ADD COLUMN IF NOT EXISTS city public.city_enum,
  ADD COLUMN IF NOT EXISTS join_date date,
  ADD COLUMN IF NOT EXISTS license_status public.license_status_enum DEFAULT 'no_license',
  ADD COLUMN IF NOT EXISTS sponsorship_status public.sponsorship_status_enum DEFAULT 'not_sponsored',
  ADD COLUMN IF NOT EXISTS id_photo_url text,
  ADD COLUMN IF NOT EXISTS license_photo_url text,
  ADD COLUMN IF NOT EXISTS personal_photo_url text;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'employee-documents', -- NOSONAR
  'employee-documents',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- FILE: 20260308070643_7e8e693c-d0d3-4d54-bb98-f628d77acadb.sql
﻿
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS preferred_language text NOT NULL DEFAULT 'ar' CHECK (preferred_language IN ('ar', 'en', 'ur'));

-- FILE: 20260308160244_08e17ad0-0a55-4ec5-b5f2-a2dc4ea0e6b0.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS nationality text;

-- FILE: 20260308160641_33fe96e5-0f81-4488-8186-8436064285db.sql
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS employee_code text,
  ADD COLUMN IF NOT EXISTS birth_date date;
CREATE UNIQUE INDEX IF NOT EXISTS employees_employee_code_unique
  ON public.employees (employee_code)
  WHERE employee_code IS NOT NULL;

-- FILE: 20260309003853_b312456a-78bf-413c-be9d-7ebb91748221.sql
﻿

-- FILE: 20260309003904_4ac0abf0-9134-4156-9456-1e4dd05dc643.sql
UPDATE storage.buckets SET public = FALSE WHERE id = 'employee-documents'; -- NOSONAR

-- FILE: 20260309004512_08955870-3030-4d1b-841a-781651a23ca5.sql
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES public.positions(id) ON DELETE SET NULL;

-- FILE: 20260318000852_1d17194a-ce8c-4d75-840d-0226be68a413.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS probation_end_date date NULL;

-- FILE: 20260318003456_618c1cf7-60bf-4c42-8470-74109a9f6d45.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS health_insurance_expiry date;

-- FILE: 20260320000001_vehicle_mileage_daily.sql
﻿
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_employees_role_id ON public.employees(role_id);
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325154500_unify_company_id_on_employees.sql
﻿-- ============================================================================
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.employees
SET company_id = trade_register_id
WHERE company_id IS NULL
  AND trade_register_id IS NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'employees_company_id_fkey'
      AND conrelid = 'public.employees'::regclass
  ) THEN
    ALTER TABLE public.employees
      ADD CONSTRAINT employees_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_employees_company_id
  ON public.employees (company_id);
ALTER TABLE public.employees
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();

-- FILE: 20260325160000_drop_legacy_trade_register_id_on_employees.sql
UPDATE public.employees
SET company_id = trade_register_id
WHERE company_id IS NULL
  AND trade_register_id IS NOT NULL;
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
    SELECT
      tr.name,
      tr.cr_number,
      COALESCE(JSONB_BUILD_OBJECT(
        'company_id', tr.id,
        'name', tr.name,
        'cr_number', tr.cr_number,
        'notes', tr.notes
      ), '{}'::jsonb)
    INTO trade_name, trade_cr, trade_json
    FROM public.trade_registers tr
    WHERE tr.id = NEW.company_id;
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
$$ LANGUAGE plpgsql;
DROP FUNCTION IF EXISTS public.sync_employees_company_columns();
ALTER TABLE public.employees
  DROP CONSTRAINT IF EXISTS employees_trade_register_id_fkey;
ALTER TABLE public.employees
  DROP COLUMN IF EXISTS trade_register_id;

-- FILE: 20260325163000_tenant_rls_platform_accounts_and_employee_links.sql
﻿-- ============================================================================
ALTER TABLE public.employees
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.employees
  ADD CONSTRAINT employees_name_not_empty
  CHECK (name IS NOT NULL AND length(btrim(name)) > 0);

-- FILE: 20260325211000_edge_rate_limit_guard.sql
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325234500_admin_action_log.sql
﻿-- Dedicated admin action log (application-level audit trail).
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees            ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.employees            ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260327124500_assert_no_company_id_leftovers.sql
DO $$
DECLARE
  v_count integer;
  v_sample text;
BEGIN
  SELECT COUNT(*)::int
  INTO v_count
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND lower(c.column_name) = 'company_id';
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I', c.table_schema, c.table_name), ', ' ORDER BY c.table_name)
    INTO v_sample
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND lower(c.column_name) = 'company_id';
    RAISE EXCEPTION 'Assertion failed: company_id columns still exist (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
  SELECT COUNT(*)::int
  INTO v_count
  FROM pg_constraint pc
  JOIN pg_class tbl ON tbl.oid = pc.conrelid
  JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
  WHERE ns.nspname = 'public'
    AND pg_get_constraintdef(pc.oid) ILIKE '%company_id%';
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I (%s)', ns.nspname, tbl.relname, pc.conname), ', ' ORDER BY tbl.relname, pc.conname)
    INTO v_sample
    FROM pg_constraint pc
    JOIN pg_class tbl ON tbl.oid = pc.conrelid
    JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
    WHERE ns.nspname = 'public'
      AND pg_get_constraintdef(pc.oid) ILIKE '%company_id%';
    RAISE EXCEPTION 'Assertion failed: constraints still reference company_id (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
  SELECT COUNT(*)::int
  INTO v_count
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND (
      COALESCE(p.qual, '') ILIKE '%company_id%'
      OR COALESCE(p.with_check, '') ILIKE '%company_id%'
    );
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I [%I]', p.schemaname, p.tablename, p.policyname), ', ' ORDER BY p.tablename, p.policyname)
    INTO v_sample
    FROM pg_policies p
    WHERE p.schemaname = 'public'
      AND (
        COALESCE(p.qual, '') ILIKE '%company_id%'
        OR COALESCE(p.with_check, '') ILIKE '%company_id%'
      );
    RAISE EXCEPTION 'Assertion failed: RLS policies still reference company_id (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
END
$$;

-- FILE: 20260327130000_allow_attendance_viewers_to_read_employees.sql
BEGIN;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260328100000_single_org_platform_accounts_triggers_and_rls.sql
﻿-- Single-organization: remove platform_accounts / account_assignments sync triggers
BEGIN;
DROP FUNCTION IF EXISTS public.sync_platform_accounts_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_account_assignments_company_id() CASCADE;
ALTER TABLE public.employees
ADD COLUMN IF NOT EXISTS commercial_record TEXT;
COMMENT ON COLUMN public.employees.commercial_record IS 'رقم السجل التجاري للمندوب - يستخدم في التنبيهات والتقارير';

-- FILE: 20260403000001_update_salary_engine_for_shifts.sql
BEGIN;
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_month(TEXT, TEXT);
COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS 'v4: Calculates salary supporting orders, shift, and hybrid work types';
COMMIT;

-- FILE: 20260404000000_remove_company_id_from_platform_accounts.sql
﻿-- ══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.sync_platform_accounts_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_account_assignments_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.platform_account_in_my_company(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.assignment_in_my_company(uuid) CASCADE;
DROP INDEX IF EXISTS idx_platform_accounts_company_id;
DROP INDEX IF EXISTS idx_account_assignments_company_id;
ALTER TABLE public.employees
  DROP CONSTRAINT IF EXISTS employees_preferred_language_check;
ALTER TABLE public.employees
  ALTER COLUMN preferred_language SET DEFAULT 'ar';
ALTER TABLE public.employees
  ADD CONSTRAINT employees_preferred_language_check
  CHECK (preferred_language IN ('ar', 'en'));
DROP VIEW IF EXISTS public.v_rider_daily_platform_orders CASCADE;
ALTER TABLE public.employees
  ALTER COLUMN city TYPE text
  USING city::text;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS cities text[];
UPDATE public.employees
SET cities = CASE
  WHEN cities IS NOT NULL AND array_length(cities, 1) > 0 THEN cities
  WHEN city IS NULL THEN '{}'::text[]
  ELSE ARRAY[city]
END;
UPDATE public.employees
SET cities = COALESCE(
  (
    SELECT array_agg(DISTINCT normalized_city)
    FROM (
      SELECT NULLIF(trim(value), '') AS normalized_city
      FROM unnest(COALESCE(cities, '{}'::text[])) AS value
    ) AS normalized
    WHERE normalized_city IS NOT NULL
  ),
  '{}'::text[]
);
UPDATE public.employees
SET city = NULLIF(cities[1], '');
ALTER TABLE public.employees
  ALTER COLUMN cities SET DEFAULT '{}'::text[];
DROP INDEX IF EXISTS public.employees_employee_code_unique;
ALTER TABLE public.employees
  DROP COLUMN IF EXISTS employee_code;
COMMENT ON COLUMN public.employees.cities IS
  'قائمة المدن المسموح للموظف العمل فيها، وأول عنصر منها يمثل المدينة الرئيسية.';
COMMIT;

-- FILE: 20260405000000_add_shifts_and_hybrid_work_types.sql
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS iqama_photo_url text;
CREATE INDEX IF NOT EXISTS idx_employees_commercial_record
  ON public.employees (commercial_record)
  WHERE commercial_record IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_employees_residency_expiry
  ON public.employees (residency_expiry)
  WHERE residency_expiry IS NOT NULL;
INSERT INTO public.commercial_records (name)
SELECT DISTINCT btrim(commercial_record)
FROM public.employees
WHERE NULLIF(btrim(commercial_record), '') IS NOT NULL
ON CONFLICT DO NOTHING;
UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
WHERE id = 'employee-documents';
COMMIT;

-- FILE: 20260408000000_align_salary_engine_with_sheet_and_admin_titles.sql
BEGIN;
DROP FUNCTION IF EXISTS public.is_salary_admin_job_title(TEXT);
DROP FUNCTION IF EXISTS public.calculate_order_salary_for_app(UUID, INTEGER, INTEGER, UUID[], BOOLEAN);
DROP FUNCTION IF EXISTS public.is_salary_month_visible_employee(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_month(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS
  'v5: Sheet-aligned salary calculation using app pricing rules, salary schemes, and admin-title visibility';
COMMENT ON FUNCTION public.preview_salary_for_month IS
  'v4: Sheet-aligned preview with per-platform breakdown and admin-title visibility';
COMMIT;

-- FILE: 20260409000000_salary_record_sheet_snapshot.sql