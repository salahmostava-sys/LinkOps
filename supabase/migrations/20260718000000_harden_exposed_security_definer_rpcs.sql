BEGIN;

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

COMMENT ON SCHEMA private IS
  'Internal implementation schema. It must not be exposed through the Data API.';

-- RLS helpers retain their object identity so existing policy dependencies move
-- with them. Public wrappers are recreated only where application code needs an
-- RPC-compatible entry point.
ALTER FUNCTION public.advance_in_my_company(uuid) SET SCHEMA private;
ALTER FUNCTION public.employee_in_my_company(uuid) SET SCHEMA private;
ALTER FUNCTION public.get_my_role() SET SCHEMA private;
ALTER FUNCTION public.has_permission(text, text) SET SCHEMA private;
ALTER FUNCTION public.has_role(uuid, public.app_role) SET SCHEMA private;
ALTER FUNCTION public.has_settings_management_access() SET SCHEMA private;
ALTER FUNCTION public.is_active_user(uuid) SET SCHEMA private;
ALTER FUNCTION public.is_admin_or_hr(uuid) SET SCHEMA private;
ALTER FUNCTION public.is_internal_user() SET SCHEMA private;

-- Privileged RPC implementations move outside the exposed public schema. Their
-- authorization checks and SECURITY DEFINER behavior remain unchanged.
ALTER FUNCTION public.alerts_summary_rpc(date, date) SET SCHEMA private;
ALTER FUNCTION public.assign_platform_account(uuid, uuid, date, text, uuid) SET SCHEMA private;
ALTER FUNCTION public.performance_dashboard_rpc(text, date) SET SCHEMA private;
ALTER FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) SET SCHEMA private;
ALTER FUNCTION public.rider_profile_performance_rpc(uuid, text, date) SET SCHEMA private;

REVOKE ALL ON FUNCTION private.advance_in_my_company(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.employee_in_my_company(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.get_my_role() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.has_permission(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.has_role(uuid, public.app_role) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.has_settings_management_access() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.is_active_user(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.is_admin_or_hr(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.is_internal_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.alerts_summary_rpc(date, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.assign_platform_account(uuid, uuid, date, text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.performance_dashboard_rpc(text, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.rider_profile_performance_rpc(uuid, text, date) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION private.advance_in_my_company(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.employee_in_my_company(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.get_my_role() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.has_permission(text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.has_role(uuid, public.app_role) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.has_settings_management_access() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_active_user(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin_or_hr(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_internal_user() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.alerts_summary_rpc(date, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.assign_platform_account(uuid, uuid, date, text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.performance_dashboard_rpc(text, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.rider_profile_performance_rpc(uuid, text, date) TO authenticated, service_role;

CREATE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.get_my_role();
$$;

CREATE FUNCTION public.has_permission(p_resource text, p_action text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.has_permission(p_resource, p_action);
$$;

CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT CASE
    WHEN auth.role() = 'service_role' OR _user_id = auth.uid()
      THEN private.has_role(_user_id, _role)
    ELSE false
  END;
$$;

CREATE FUNCTION public.has_settings_management_access()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.has_settings_management_access();
$$;

CREATE FUNCTION public.is_active_user(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT CASE
    WHEN auth.role() = 'service_role' OR _user_id = auth.uid()
      THEN private.is_active_user(_user_id)
    ELSE false
  END;
$$;

CREATE FUNCTION public.is_admin_or_hr(uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT CASE
    WHEN auth.role() = 'service_role' OR uid = auth.uid()
      THEN private.is_admin_or_hr(uid)
    ELSE false
  END;
$$;

CREATE FUNCTION public.is_internal_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.is_internal_user();
$$;

CREATE FUNCTION public.alerts_summary_rpc(
  p_expiry_horizon date,
  p_urgent_horizon date
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.alerts_summary_rpc(p_expiry_horizon, p_urgent_horizon);
$$;

CREATE FUNCTION public.assign_platform_account(
  p_account_id uuid,
  p_employee_id uuid,
  p_start_date date,
  p_notes text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
)
RETURNS public.account_assignments
LANGUAGE sql
VOLATILE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.assign_platform_account(
    p_account_id,
    p_employee_id,
    p_start_date,
    p_notes,
    auth.uid()
  );
$$;

CREATE FUNCTION public.performance_dashboard_rpc(
  p_month_year text,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
VOLATILE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.performance_dashboard_rpc(p_month_year, p_today);
$$;

CREATE FUNCTION public.replace_daily_orders_month_rpc(
  p_month_year text,
  p_rows jsonb DEFAULT '[]'::jsonb,
  p_source_type text DEFAULT 'manual',
  p_file_name text DEFAULT NULL,
  p_target_app_id uuid DEFAULT NULL
)
RETURNS TABLE(batch_id uuid, saved_rows integer, failed_rows integer)
LANGUAGE sql
VOLATILE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT *
  FROM private.replace_daily_orders_month_rpc(
    p_month_year,
    p_rows,
    p_source_type,
    p_file_name,
    p_target_app_id
  );
$$;

CREATE FUNCTION public.rider_profile_performance_rpc(
  p_employee_id uuid,
  p_month_year text,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
VOLATILE
SECURITY INVOKER
SET search_path = pg_catalog, public, private
AS $$
  SELECT private.rider_profile_performance_rpc(
    p_employee_id,
    p_month_year,
    p_today
  );
$$;

-- These compatibility overloads only delegate to the already-invoker two-arg
-- dashboard RPC, so elevated execution is unnecessary.
ALTER FUNCTION public.dashboard_overview_rpc(text, integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(text, text, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(integer, integer, date) SECURITY INVOKER;

REVOKE ALL ON FUNCTION public.get_my_role() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_permission(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_settings_management_access() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_active_user(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_admin_or_hr(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_internal_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.alerts_summary_rpc(date, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.assign_platform_account(uuid, uuid, date, text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.performance_dashboard_rpc(text, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rider_profile_performance_rpc(uuid, text, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.dashboard_overview_rpc(text, integer, integer, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.dashboard_overview_rpc(text, text, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.dashboard_overview_rpc(integer, integer, date) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_permission(text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_settings_management_access() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_active_user(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_admin_or_hr(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_internal_user() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.alerts_summary_rpc(date, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.assign_platform_account(uuid, uuid, date, text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.performance_dashboard_rpc(text, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.rider_profile_performance_rpc(uuid, text, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.dashboard_overview_rpc(text, integer, integer, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.dashboard_overview_rpc(text, text, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.dashboard_overview_rpc(integer, integer, date) TO authenticated, service_role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_proc AS proc
    JOIN pg_namespace AS namespace
      ON namespace.oid = proc.pronamespace
    WHERE namespace.nspname = 'public'
      AND proc.prosecdef
      AND has_function_privilege('authenticated', proc.oid, 'EXECUTE')
      AND proc.proname IN (
        'advance_in_my_company',
        'alerts_summary_rpc',
        'assign_platform_account',
        'dashboard_overview_rpc',
        'employee_in_my_company',
        'get_my_role',
        'has_permission',
        'has_role',
        'has_settings_management_access',
        'is_active_user',
        'is_admin_or_hr',
        'is_internal_user',
        'performance_dashboard_rpc',
        'replace_daily_orders_month_rpc',
        'rider_profile_performance_rpc'
      )
  ) THEN
    RAISE EXCEPTION 'Exposed authenticated SECURITY DEFINER functions remain';
  END IF;
END;
$$;

COMMIT;
