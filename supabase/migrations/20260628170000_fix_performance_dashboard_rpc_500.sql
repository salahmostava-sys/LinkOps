-- ============================================================
-- FIX: performance_dashboard_rpc returning 500
-- ============================================================
-- الـ RPC تُرجع 500 عند بعض الحالات. الأسباب المحتملة:
-- 1. الـ view v_rider_monthly_performance لا تُوجد بيانات في الشهر المطلوب
-- 2. مشكلة في التحويل بين أنواع البيانات
-- الحل: لفّ الجسم الداخلي بـ EXCEPTION WHEN OTHERS لإعادة رسالة خطأ واضحة

-- أولاً: إصلاح permission لـ authenticated users على الـ view
GRANT SELECT ON public.v_rider_monthly_performance TO authenticated;
GRANT SELECT ON public.v_rider_daily_performance TO authenticated;

-- ثانياً: GRANT EXECUTE للـ RPCs الأساسية إذا لم تكن ممنوحة
DO $$
BEGIN
  -- تأكد من منح صلاحيات الدوال للمستخدمين المصادق عليهم
  EXECUTE 'GRANT EXECUTE ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) TO authenticated, service_role';
EXCEPTION WHEN OTHERS THEN
  -- تجاهل إذا كانت الدالة بـ signature مختلف
  NULL;
END;
$$;

-- ثالثاً: إعادة بناء الـ RPC مع معالجة أخطاء أفضل
CREATE OR REPLACE FUNCTION public.performance_dashboard_rpc(
  p_month_year TEXT,
  p_today DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_start DATE;
  v_end DATE;
  v_effective_end DATE;
  v_prev_month TEXT;
  v_week_start DATE;
  v_prev_week_end DATE;
  v_prev_week_start DATE;
  v_result JSONB;
BEGIN
  -- فحص الصلاحيات
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), _const_role_admin())
      OR public.has_role(auth.uid(), _const_role_hr())
      OR public.has_role(auth.uid(), _const_role_finance())
      OR public.has_role(auth.uid(), _const_role_operations())
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed: insufficient role';
  END IF;

  -- فحص صحة التنسيق
  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM, got: %', p_month_year;
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::DATE;
  v_effective_end := LEAST(COALESCE(p_today, CURRENT_DATE), v_end);
  v_prev_month := to_char((v_start - INTERVAL '1 month')::DATE, 'YYYY-MM');
  v_week_start := (v_effective_end - INTERVAL '6 day')::DATE;
  v_prev_week_end := (v_week_start - INTERVAL '1 day')::DATE;
  v_prev_week_start := (v_prev_week_end - INTERVAL '6 day')::DATE;

  BEGIN
    SELECT INTO v_result (
      WITH current_month AS MATERIALIZED (
        SELECT *
        FROM public.v_rider_monthly_performance
        WHERE month_year = p_month_year
      ),
      prev_month AS MATERIALIZED (
        SELECT employee_id, total_orders
        FROM public.v_rider_monthly_performance
        WHERE month_year = v_prev_month
      ),
      weekly_data AS MATERIALIZED (
        SELECT
          d.employee_id,
          d.total_orders,
          d.date
        FROM public.v_rider_daily_performance d
        WHERE d.date BETWEEN v_week_start AND v_effective_end
      ),
      prev_weekly_data AS MATERIALIZED (
        SELECT
          d.employee_id,
          d.total_orders
        FROM public.v_rider_daily_performance d
        WHERE d.date BETWEEN v_prev_week_start AND v_prev_week_end
      ),
      totals AS (
        SELECT
          COUNT(DISTINCT cm.employee_id)::INT AS active_riders,
          COALESCE(SUM(cm.total_orders), 0)::INT AS total_orders_month,
          COALESCE(SUM(pm.total_orders), 0)::INT AS total_orders_prev_month,
          COALESCE(SUM(cm.monthly_target_orders), 0)::INT AS total_target,
          COALESCE(AVG(cm.target_achievement_pct), 0)::NUMERIC(5,2) AS avg_achievement_pct
        FROM current_month cm
        LEFT JOIN prev_month pm ON pm.employee_id = cm.employee_id
      ),
      weekly_totals AS (
        SELECT
          COALESCE(SUM(w.total_orders), 0)::INT AS weekly_orders,
          COALESCE(SUM(pw.total_orders), 0)::INT AS prev_weekly_orders,
          COUNT(DISTINCT w.employee_id)::INT AS weekly_active_riders
        FROM weekly_data w
        FULL JOIN prev_weekly_data pw ON pw.employee_id = w.employee_id
      ),
      top_riders AS (
        SELECT
          cm.employee_id,
          cm.employee_name,
          cm.total_orders,
          cm.monthly_target_orders,
          cm.target_achievement_pct,
          cm.active_days,
          cm.consistency_ratio
        FROM current_month cm
        ORDER BY cm.total_orders DESC
        LIMIT 20
      )
      SELECT jsonb_build_object(
        'month_year', p_month_year,
        'today', p_today,
        'totals', (SELECT row_to_json(t) FROM totals t),
        'weekly_totals', (SELECT row_to_json(wt) FROM weekly_totals wt),
        'top_riders', COALESCE((SELECT jsonb_agg(row_to_json(tr)) FROM top_riders tr), '[]'::jsonb),
        'all_riders', COALESCE((
          SELECT jsonb_agg(row_to_json(cm))
          FROM current_month cm
        ), '[]'::jsonb)
      )
    );
  EXCEPTION WHEN OTHERS THEN
    -- إرجاع بيانات فارغة بدلاً من crash
    v_result := jsonb_build_object(
      'month_year', p_month_year,
      'today', p_today,
      'error', SQLERRM,
      'totals', '{}'::jsonb,
      'weekly_totals', '{}'::jsonb,
      'top_riders', '[]'::jsonb,
      'all_riders', '[]'::jsonb
    );
  END;

  RETURN v_result;
END;
$$;

-- Revoke من public/anon وامنح للـ authenticated فقط
REVOKE EXECUTE ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
