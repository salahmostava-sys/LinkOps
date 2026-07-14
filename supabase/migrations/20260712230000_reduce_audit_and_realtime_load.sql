-- Reduce database write amplification and realtime fanout.
-- The activity log can still be queried, but broad automatic CUD audit triggers
-- are removed so high-volume tables do not write an extra audit row per change.

DO $$
DECLARE
  v_table text;
  v_tables text[] := ARRAY[
    'profiles',
    'user_roles',
    'user_permissions',
    'trade_registers',
    'apps',
    'app_monthly_activations',
    'app_targets',
    'pricing_rules',
    'platform_accounts',
    'account_assignments',
    'salary_schemes',
    'salary_scheme_tiers',
    'salary_tiers',
    'salary_records',
    'pl_records',
    'salary_deductions',
    'salary_drafts',
    'salary_month_snapshots',
    'salary_slip_templates',
    'scheme_month_snapshots',
    'employees',
    'employee_scheme',
    'employee_apps',
    'employee_tiers',
    'employee_roles',
    'employee_targets',
    'employee_wallet_transactions',
    'attendance',
    'attendance_status_configs',
    'daily_orders',
    'daily_shifts',
    'order_import_batches',
    'advances',
    'advance_installments',
    'external_deductions',
    'vehicles',
    'vehicle_assignments',
    'vehicle_documents',
    'vehicle_mileage',
    'vehicle_mileage_daily',
    'fuel_records',
    'maintenance_logs',
    'maintenance_parts',
    'maintenance_records',
    'spare_parts',
    'treasury_accounts',
    'treasury_categories',
    'treasury_transactions',
    'finance_transactions',
    'commercial_records',
    'departments',
    'positions',
    'leave_requests',
    'hr_performance_reviews',
    'alerts',
    'locked_months',
    'system_settings'
  ];
BEGIN
  FOREACH v_table IN ARRAY v_tables LOOP
    IF to_regclass(format('public.%I', v_table)) IS NOT NULL THEN
      EXECUTE format('DROP TRIGGER IF EXISTS audit_%I ON public.%I', v_table, v_table);
      EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_admin_log ON public.%I', v_table, v_table);
    END IF;
  END LOOP;
END;
$$;

DROP FUNCTION IF EXISTS public.log_admin_action_cud();

CREATE OR REPLACE FUNCTION public.prune_audit_logs(
  p_keep_days integer DEFAULT 90,
  p_batch_size integer DEFAULT 5000
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_audit_deleted integer := 0;
  v_admin_deleted integer := 0;
BEGIN
  IF p_keep_days NOT BETWEEN 1 AND 3650 THEN
    RAISE EXCEPTION 'p_keep_days must be between 1 and 3650';
  END IF;
  IF p_batch_size NOT BETWEEN 1 AND 10000 THEN
    RAISE EXCEPTION 'p_batch_size must be between 1 and 10000';
  END IF;

  DELETE FROM public.audit_log
  WHERE ctid IN (
    SELECT ctid
    FROM public.audit_log
    WHERE created_at < now() - make_interval(days => p_keep_days)
    ORDER BY created_at
    LIMIT p_batch_size
  );
  GET DIAGNOSTICS v_audit_deleted = ROW_COUNT;

  DELETE FROM public.admin_action_log
  WHERE ctid IN (
    SELECT ctid
    FROM public.admin_action_log
    WHERE created_at < now() - make_interval(days => p_keep_days)
    ORDER BY created_at
    LIMIT p_batch_size
  );
  GET DIAGNOSTICS v_admin_deleted = ROW_COUNT;

  RETURN jsonb_build_object(
    'audit_log_deleted', v_audit_deleted,
    'admin_action_log_deleted', v_admin_deleted
  );
END;
$$;

REVOKE ALL ON FUNCTION public.prune_audit_logs(integer, integer) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prune_audit_logs(integer, integer) TO service_role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'audit_log'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.audit_log';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'platform_accounts'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.platform_accounts';
  END IF;
END;
$$;
