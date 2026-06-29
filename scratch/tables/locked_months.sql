CREATE TABLE IF NOT EXISTS public.locked_months (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  month_year TEXT NOT NULL UNIQUE,
  locked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_by UUID REFERENCES auth.users(id)
);
ALTER TABLE public.locked_months ENABLE ROW LEVEL SECURITY;

-- FILE: 20260323170000_platform_accounts_employee_id_and_alerts_trigger.sql
CREATE TABLE IF NOT EXISTS public.locked_months (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  month_year  TEXT        NOT NULL UNIQUE,
  locked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_by   UUID        REFERENCES public.profiles(id) ON DELETE SET NULL
);
ALTER TABLE public.locked_months ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324120000_dashboard_alerts_realtime_publication.sql
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'employees',
    'attendance',
    'daily_orders',
    'audit_log',
    'vehicles',
    'alerts',
    'apps',
    'app_targets',
    'platform_accounts'
  ];
BEGIN
  FOREACH t IN ARRAY tables
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END
$$;

-- FILE: 20260324120001_vehicle_mileage_daily_rls_finance.sql
﻿-- Allow finance (and HR) to read/write daily fuel/km entries alongside ops/admin

-- FILE: 20260324123500_signup_pii_rls_fix.sql
ALTER TABLE public.locked_months ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.locked_months ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.locked_months ADD CONSTRAINT locked_months_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_settings_company_id_fkey') THEN
ALTER TABLE public.locked_months
  DROP CONSTRAINT IF EXISTS locked_months_locked_by_fkey;
ALTER TABLE public.locked_months
  ADD CONSTRAINT locked_months_locked_by_fkey
  FOREIGN KEY (locked_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- FILE: 20260410030000_fix_salary_engine_ambiguous_column.sql
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260410040000_fix_security_definer_views.sql
ALTER VIEW public.v_rider_daily_platform_orders SET (security_invoker = true);
ALTER VIEW public.v_rider_daily_performance SET (security_invoker = true);
ALTER VIEW public.v_rider_monthly_performance SET (security_invoker = true);

-- FILE: 20260410050000_fix_search_path_and_security_invoker.sql
ALTER FUNCTION public.is_salary_admin_job_title(TEXT)
  SET search_path = 'public';
ALTER FUNCTION public.check_no_overlap_orders_shifts()
  SET search_path = 'public';
ALTER FUNCTION public.update_daily_shifts_updated_at()
  SET search_path = 'public';
ALTER FUNCTION public.update_salary_drafts_updated_at()
  SET search_path = 'public';
ALTER FUNCTION public.increment_salary_record_version()
  SET search_path = 'public';
ALTER FUNCTION public.update_updated_at_column()
  SET search_path = 'public';
ALTER FUNCTION public.calc_tier_salary(INTEGER)
  SET search_path = 'public';
ALTER FUNCTION public.fn_handle_employee_sponsorship_alerts()
  SET search_path = 'public';

-- FILE: 20260410060000_fix_sponsorship_alerts_company_id.sql
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
    trade_name := NEW.commercial_record;
    trade_cr := NULL;
    trade_json := '{}'::jsonb;
    IF NEW.commercial_record IS NOT NULL AND NEW.commercial_record <> '' THEN
      SELECT
        cr.name,
        cr.cr_number,
        JSONB_BUILD_OBJECT(
          'name', cr.name,
          'cr_number', cr.cr_number
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
$$ LANGUAGE plpgsql
SET search_path = 'public';

-- FILE: 20260411000000_attendance_status_configs.sql