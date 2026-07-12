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
    END IF;
  END LOOP;
END;
$$;

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
