CREATE TABLE IF NOT EXISTS public.salary_month_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month_year TEXT NOT NULL UNIQUE CHECK (month_year ~ '^\d{4}-\d{2}$'),
  snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb,
  captured_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_salary_month_snapshots_month
  ON public.salary_month_snapshots(month_year);
ALTER TABLE public.salary_month_snapshots ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.salary_month_snapshots IS
'Frozen accounting snapshot of salary records for each month.';
COMMENT ON VIEW public.v_rider_daily_platform_orders IS
'Performance write-model projection: daily orders per employee and platform.';
COMMENT ON VIEW public.v_rider_daily_performance IS
'Performance read-model: one daily summary row per rider with platform breakdown.';
COMMENT ON VIEW public.v_rider_monthly_performance IS
'Performance read-model: monthly rider metrics, consistency, and target achievement.';
COMMENT ON FUNCTION public.replace_daily_orders_month_rpc(TEXT, JSONB, TEXT, TEXT, UUID) IS
'Transactional month replacement for daily orders with import-batch tracking.';
COMMENT ON FUNCTION public.capture_salary_month_snapshot(TEXT) IS
'Freeze a month-level salary snapshot for accounting and reload parity.';
COMMIT;

-- FILE: 20260410010000_performance_dashboard_rpcs.sql
﻿BEGIN;
CREATE INDEX IF NOT EXISTS idx_daily_orders_perf_date_employee
  ON public.daily_orders(date, employee_id, app_id)
  WHERE orders_count > 0;
CREATE INDEX IF NOT EXISTS idx_daily_orders_perf_employee_date
  ON public.daily_orders(employee_id, date)
  WHERE orders_count > 0;
CREATE INDEX IF NOT EXISTS idx_salary_records_month_employee
  ON public.salary_records(month_year, employee_id);
COMMENT ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) IS
'Single backend source for dashboard KPIs, comparisons, rankings, alerts, and performance trends.';
COMMENT ON FUNCTION public.rider_profile_performance_rpc(UUID, TEXT, DATE) IS
'Single backend source for rider profile performance, comparisons, targets, alerts, and salary snapshot.';
COMMIT;

-- FILE: 20260410011000_fix_performance_dashboard_avg_orders.sql
BEGIN;
DO $$
DECLARE
  v_definition TEXT;
  v_updated_definition TEXT;
  v_old_crlf TEXT;
  v_old_lf TEXT;
  v_new_block TEXT;
BEGIN
  SELECT pg_get_functiondef('public.performance_dashboard_rpc(text, date)'::regprocedure)
    INTO v_definition;
  IF v_definition IS NULL THEN
    RAISE EXCEPTION 'Function public.performance_dashboard_rpc(text, date) was not found';
  END IF;
  v_old_crlf :=
    '          SELECT ROUND(current_orders::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE total_orders > 0), 0), 2)'
    || E'\r\n'
    || '          FROM month_comparison, current_month';
  v_old_lf :=
    '          SELECT ROUND(current_orders::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE total_orders > 0), 0), 2)'
    || E'\n'
    || '          FROM month_comparison, current_month';
  v_new_block :=
    '          SELECT ROUND('
    || E'\n'
    || '            COALESCE((SELECT current_orders FROM month_comparison), 0)::NUMERIC'
    || E'\n'
    || '            / NULLIF((SELECT COUNT(*)::INTEGER FROM current_month WHERE total_orders > 0), 0),'
    || E'\n'
    || '            2'
    || E'\n'
    || '          )';
  v_updated_definition := replace(v_definition, v_old_crlf, v_new_block);
  IF v_updated_definition = v_definition THEN
    v_updated_definition := replace(v_definition, v_old_lf, v_new_block);
  END IF;
  IF v_updated_definition = v_definition THEN
    RAISE NOTICE 'Hotfix pattern was not found in public.performance_dashboard_rpc(text, date). It may have already been applied.';
    RETURN;
  END IF;
  EXECUTE v_updated_definition;
END;
$$;
COMMENT ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) IS
'Single backend source for dashboard KPIs, comparisons, rankings, alerts, and performance trends.';
COMMIT;

-- FILE: 20260410020000_fix_auth_users_fk_cascade_for_delete.sql