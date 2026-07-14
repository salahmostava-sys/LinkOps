-- Deploy the system integration and performance corrections to existing environments.
-- Historical migration files remain the schema source; this migration applies their
-- corrected definitions and introduces the new lightweight alert summary RPC.

BEGIN;

DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);

CREATE OR REPLACE FUNCTION public.preview_salary_for_month(p_month_year TEXT)
RETURNS TABLE (
  employee_id UUID,
  total_orders INTEGER,
  total_shift_days INTEGER,
  base_salary NUMERIC,
  external_deduction NUMERIC,
  advance_deduction NUMERIC,
  net_salary NUMERIC,
  platform_breakdown JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_start DATE; v_end DATE;
  v_emp RECORD; v_app RECORD;
  v_app_orders INTEGER; v_app_shift_days INTEGER; v_app_earnings NUMERIC;
  v_total_orders INTEGER; v_total_shift_days INTEGER; v_base_salary NUMERIC;
  v_external_deduction NUMERIC; v_advance_deduction NUMERIC;
  v_net NUMERIC; v_platform_breakdown JSONB;
  v_calculation_method TEXT;
  v_hybrid_rule RECORD;
  v_day RECORD; v_hours_worked NUMERIC;
  v_monthly_amount NUMERIC;
  v_fixed_scheme_ids UUID[];
  -- Constants
  c_cancelled TEXT := _const_order_cancelled();
  c_active TEXT := _const_employee_active();
  c_approved TEXT := _const_approval_approved();
  c_pending TEXT := _const_installment_pending();
  c_deferred TEXT := _const_installment_deferred();
  c_orders TEXT := _const_work_orders();
  c_shift TEXT := _const_work_shift();
  c_hybrid TEXT := _const_work_hybrid();
  c_days_per_month NUMERIC := _const_days_per_month();
BEGIN
  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::date;

  FOR v_emp IN SELECT e.id FROM employees e WHERE e.status = c_active LOOP
    v_total_orders := 0; v_total_shift_days := 0; v_base_salary := 0;
    v_platform_breakdown := '[]'::jsonb;
    v_fixed_scheme_ids := ARRAY[]::UUID[];

    FOR v_app IN
      SELECT a.id AS app_id, a.name AS app_name, a.work_type,
             s.id AS scheme_id, s.scheme_type, s.monthly_amount
      FROM apps a
      LEFT JOIN salary_schemes s ON s.id = a.scheme_id
      WHERE a.is_active IS TRUE
    LOOP
      v_app_orders := 0; v_app_shift_days := 0; v_app_earnings := 0;
      v_calculation_method := c_orders;

      IF v_app.work_type = c_orders OR v_app.work_type IS NULL THEN
        -- === ORDERS-BASED: salary from daily_orders ===
        SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
        FROM daily_orders d
        WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id
          AND d.date BETWEEN v_start AND v_end
          AND (d.status IS NULL OR d.status <> c_cancelled);

        v_total_orders := v_total_orders + v_app_orders;
        
        -- Use the unified fallback function
        SELECT earnings, calculation_method, fixed_scheme_ids 
        INTO v_app_earnings, v_calculation_method, v_fixed_scheme_ids
        FROM public.calculate_order_salary_for_app(
          v_app.app_id, 
          v_app_orders, 
          0, 
          v_fixed_scheme_ids, 
          true
        );

      ELSIF v_app.work_type = c_shift THEN
        -- === SHIFT-BASED: always full monthly_amount ===
        v_calculation_method := _const_calc_method_shift_fixed();

        IF EXISTS(
          SELECT 1 FROM employee_apps ea
          WHERE ea.employee_id = v_emp.id AND ea.app_id = v_app.app_id
        ) THEN
          SELECT COUNT(*)::INTEGER INTO v_app_shift_days
          FROM daily_shifts ds
          WHERE ds.employee_id = v_emp.id AND ds.app_id = v_app.app_id
            AND ds.date BETWEEN v_start AND v_end AND ds.hours_worked > 0;

          v_total_shift_days := v_total_shift_days + v_app_shift_days;

          v_monthly_amount := COALESCE(v_app.monthly_amount, 0);
          IF v_monthly_amount > 0 AND v_app_shift_days > 0 THEN
            v_app_earnings := ROUND((v_monthly_amount / c_days_per_month) * v_app_shift_days);
          ELSE
            v_app_earnings := 0;
          END IF;
        END IF;

      ELSIF v_app.work_type = c_hybrid THEN
        -- === HYBRID ===
        v_calculation_method := _const_calc_method_mixed();
        SELECT * INTO v_hybrid_rule FROM app_hybrid_rules WHERE app_id = v_app.app_id;

        IF v_hybrid_rule IS NULL THEN
          v_calculation_method := _const_calc_method_orders_fallback();
          SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
          FROM daily_orders d
          WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id
            AND d.date BETWEEN v_start AND v_end
            AND (d.status IS NULL OR d.status <> c_cancelled);
            
          v_total_orders := v_total_orders + v_app_orders;
          
          SELECT earnings INTO v_app_earnings
          FROM public.calculate_order_salary_for_app(
            v_app.app_id, 
            v_app_orders, 
            0, 
            v_fixed_scheme_ids, 
            true
          );
        ELSE
          FOR v_day IN SELECT generate_series(v_start, v_end, '1 day'::interval)::date AS day_date LOOP
            SELECT hours_worked INTO v_hours_worked
            FROM daily_shifts ds
            WHERE ds.employee_id = v_emp.id
              AND ds.app_id = v_app.app_id
              AND ds.date = v_day.day_date;

            IF v_hours_worked IS NOT NULL AND v_hours_worked > 0 THEN
              v_app_earnings := v_app_earnings + v_hybrid_rule.shift_rate;
              v_app_shift_days := v_app_shift_days + 1;
            ELSIF v_hybrid_rule.fallback_to_orders THEN
              SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
              FROM daily_orders d
              WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id AND d.date = v_day.day_date
                AND (d.status IS NULL OR d.status <> c_cancelled);
                
              v_total_orders := v_total_orders + v_app_orders;
              IF v_app_orders > 0 THEN
                v_app_earnings := v_app_earnings + (
                  SELECT earnings 
                  FROM public.calculate_order_salary_for_app(
                    v_app.app_id, 
                    v_app_orders, 
                    0, 
                    v_fixed_scheme_ids, 
                    false
                  )
                );
              END IF;
            END IF;
          END LOOP;
          v_total_shift_days := v_total_shift_days + v_app_shift_days;
        END IF;
      END IF;

      v_base_salary := v_base_salary + v_app_earnings;

      IF v_app_orders > 0 OR v_app_shift_days > 0 OR v_app_earnings > 0 THEN
        v_platform_breakdown := v_platform_breakdown || jsonb_build_object(
          'app_id', v_app.app_id, 'app_name', v_app.app_name,
          'work_type', COALESCE(v_app.work_type, c_orders),
          'calculation_method', v_calculation_method,
          'orders_count', v_app_orders, 'shift_days', v_app_shift_days,
          'earnings', ROUND(v_app_earnings)
        );
      END IF;
    END LOOP;

    SELECT COALESCE(SUM(ed.amount), 0) INTO v_external_deduction
    FROM external_deductions ed
    WHERE ed.employee_id = v_emp.id AND ed.apply_month = p_month_year
      AND ed.approval_status = c_approved;

    SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance_deduction
    FROM advances ad JOIN advance_installments ai ON ai.advance_id = ad.id
    WHERE ad.employee_id = v_emp.id AND ai.month_year = p_month_year
      AND ai.status IN (c_pending, c_deferred);

    v_net := GREATEST(v_base_salary - v_external_deduction - v_advance_deduction, 0);

    employee_id := v_emp.id; total_orders := v_total_orders;
    total_shift_days := v_total_shift_days; base_salary := v_base_salary;
    external_deduction := v_external_deduction; advance_deduction := v_advance_deduction;
    net_salary := v_net; platform_breakdown := v_platform_breakdown;
    RETURN NEXT;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.preview_salary_for_month(text) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.preview_salary_for_month(text) TO service_role;

DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION public.calculate_salary_for_employee_month(
  p_employee_id UUID,
  p_month_year TEXT,
  p_payment_method TEXT DEFAULT _const_payment_cash(),
  p_manual_deduction NUMERIC DEFAULT 0,
  p_manual_deduction_note TEXT DEFAULT NULL
)
RETURNS TABLE (
  employee_id UUID,
  month_year TEXT,
  total_orders INTEGER,
  total_shift_days INTEGER,
  base_salary NUMERIC,
  attendance_deduction NUMERIC,
  external_deduction NUMERIC,
  advance_deduction NUMERIC,
  manual_deduction NUMERIC,
  net_salary NUMERIC,
  calc_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_start DATE; v_end DATE;
  v_app RECORD;
  v_app_orders INTEGER; v_app_shift_days INTEGER; v_app_earnings NUMERIC;
  v_total_orders INTEGER := 0; v_total_shift_days INTEGER := 0;
  v_base_salary NUMERIC := 0; v_attendance_deduction NUMERIC := 0;
  v_external_deduction NUMERIC := 0; v_advance_deduction NUMERIC := 0;
  v_net NUMERIC := 0; v_platform_breakdown JSONB := '[]'::jsonb;
  v_calculation_method TEXT;
  v_hybrid_rule RECORD; v_day RECORD; v_hours_worked NUMERIC;
  v_monthly_amount NUMERIC;
  v_fixed_scheme_ids UUID[] := ARRAY[]::UUID[];
  -- Constants
  c_cancelled TEXT := _const_order_cancelled();
  c_approved TEXT := _const_approval_approved();
  c_pending TEXT := _const_installment_pending();
  c_deferred TEXT := _const_installment_deferred();
  c_orders TEXT := _const_work_orders();
  c_shift TEXT := _const_work_shift();
  c_hybrid TEXT := _const_work_hybrid();
  c_days_per_month NUMERIC := _const_days_per_month();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.employees e WHERE e.id = p_employee_id) THEN
    RAISE EXCEPTION 'Employee not found';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::date;

  FOR v_app IN
    SELECT a.id AS app_id, a.name AS app_name, a.work_type,
           s.id AS scheme_id, s.scheme_type, s.monthly_amount
    FROM public.apps a
    LEFT JOIN public.salary_schemes s ON s.id = a.scheme_id
    WHERE a.is_active IS TRUE
  LOOP
    v_app_orders := 0; v_app_shift_days := 0; v_app_earnings := 0;
    v_calculation_method := c_orders;

    IF v_app.work_type = c_orders OR v_app.work_type IS NULL THEN
      SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
      FROM public.daily_orders d
      WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id
        AND d.date BETWEEN v_start AND v_end
        AND (d.status IS NULL OR d.status <> c_cancelled);

      v_total_orders := v_total_orders + v_app_orders;

      SELECT earnings, calculation_method, fixed_scheme_ids
      INTO v_app_earnings, v_calculation_method, v_fixed_scheme_ids
      FROM public.calculate_order_salary_for_app(
        v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, true
      );

    ELSIF v_app.work_type = c_shift THEN
      v_calculation_method := _const_calc_method_shift_fixed();
      IF EXISTS(
        SELECT 1 FROM public.employee_apps ea
        WHERE ea.employee_id = p_employee_id AND ea.app_id = v_app.app_id
      ) THEN
        SELECT COUNT(*)::INTEGER INTO v_app_shift_days
        FROM public.daily_shifts ds
        WHERE ds.employee_id = p_employee_id AND ds.app_id = v_app.app_id
          AND ds.date BETWEEN v_start AND v_end AND ds.hours_worked > 0;

        v_total_shift_days := v_total_shift_days + v_app_shift_days;

        v_monthly_amount := COALESCE(v_app.monthly_amount, 0);
        IF v_monthly_amount > 0 AND v_app_shift_days > 0 THEN
          v_app_earnings := ROUND((v_monthly_amount / c_days_per_month) * v_app_shift_days);
        ELSE
          v_app_earnings := 0;
        END IF;
      END IF;

    ELSIF v_app.work_type = c_hybrid THEN
      v_calculation_method := _const_calc_method_mixed();
      SELECT * INTO v_hybrid_rule FROM public.app_hybrid_rules WHERE app_id = v_app.app_id;

      IF v_hybrid_rule IS NULL THEN
        v_calculation_method := _const_calc_method_orders_fallback();
        SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
        FROM public.daily_orders d
        WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id
          AND d.date BETWEEN v_start AND v_end
          AND (d.status IS NULL OR d.status <> c_cancelled);
        v_total_orders := v_total_orders + v_app_orders;

        SELECT earnings INTO v_app_earnings
        FROM public.calculate_order_salary_for_app(
          v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, true
        );
      ELSE
        FOR v_day IN SELECT generate_series(v_start, v_end, '1 day'::interval)::date AS day_date LOOP
          SELECT hours_worked INTO v_hours_worked
          FROM public.daily_shifts ds
          WHERE ds.employee_id = p_employee_id
            AND ds.app_id = v_app.app_id
            AND ds.date = v_day.day_date;

          IF v_hours_worked IS NOT NULL AND v_hours_worked > 0 THEN
            v_app_earnings := v_app_earnings + v_hybrid_rule.shift_rate;
            v_app_shift_days := v_app_shift_days + 1;
          ELSIF v_hybrid_rule.fallback_to_orders THEN
            SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
            FROM public.daily_orders d
            WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id AND d.date = v_day.day_date
              AND (d.status IS NULL OR d.status <> c_cancelled);
            v_total_orders := v_total_orders + v_app_orders;
            IF v_app_orders > 0 THEN
              v_app_earnings := v_app_earnings + (
                SELECT earnings FROM public.calculate_order_salary_for_app(
                  v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, false
                )
              );
            END IF;
          END IF;
        END LOOP;
        v_total_shift_days := v_total_shift_days + v_app_shift_days;
      END IF;
    END IF;

    v_base_salary := v_base_salary + v_app_earnings;

    IF v_app_orders > 0 OR v_app_shift_days > 0 OR v_app_earnings > 0 THEN
      v_platform_breakdown := v_platform_breakdown || jsonb_build_object(
        'app_id', v_app.app_id, 'app_name', v_app.app_name,
        'work_type', COALESCE(v_app.work_type, c_orders),
        'calculation_method', v_calculation_method,
        'orders_count', v_app_orders, 'shift_days', v_app_shift_days,
        'earnings', ROUND(v_app_earnings)
      );
    END IF;
  END LOOP;

  SELECT COALESCE(SUM(ed.amount), 0) INTO v_external_deduction
  FROM public.external_deductions ed
  WHERE ed.employee_id = p_employee_id AND ed.apply_month = p_month_year
    AND ed.approval_status = c_approved;

  SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance_deduction
  FROM public.advances ad JOIN public.advance_installments ai ON ai.advance_id = ad.id
  WHERE ad.employee_id = p_employee_id AND ai.month_year = p_month_year
    AND ai.status IN (c_pending, c_deferred);

  v_net := GREATEST(
    v_base_salary - v_attendance_deduction - v_external_deduction - v_advance_deduction
      - COALESCE(p_manual_deduction, 0),
    0
  );

  -- FIX: only real public.salary_records columns are written here.
  -- (total_orders / total_shift_days / platform_breakdown / "status" do NOT
  -- exist on this table and previously made every call fail outright.)
  INSERT INTO public.salary_records (
    employee_id,
    month_year,
    base_salary,
    attendance_deduction,
    external_deduction,
    advance_deduction,
    manual_deduction,
    manual_deduction_note,
    net_salary,
    payment_method,
    calc_status,
    calc_source,
    is_approved,
    sheet_snapshot
  )
  VALUES (
    p_employee_id,
    p_month_year,
    v_base_salary,
    v_attendance_deduction,
    v_external_deduction,
    v_advance_deduction,
    COALESCE(p_manual_deduction, 0),
    p_manual_deduction_note,
    v_net,
    COALESCE(NULLIF(TRIM(p_payment_method), ''), _const_payment_cash()),
    _const_calc_calculated(),
    'engine_v6_platform_breakdown',
    false,
    NULL
  )
  -- FIX: was missing this upsert clause, even though the table has a
  -- UNIQUE(employee_id, month_year) constraint â€” recalculating an
  -- already-saved month previously failed with a duplicate key error.
  ON CONFLICT ON CONSTRAINT salary_records_employee_id_month_year_key
  DO UPDATE SET
    base_salary = EXCLUDED.base_salary,
    attendance_deduction = EXCLUDED.attendance_deduction,
    external_deduction = EXCLUDED.external_deduction,
    advance_deduction = EXCLUDED.advance_deduction,
    manual_deduction = EXCLUDED.manual_deduction,
    manual_deduction_note = EXCLUDED.manual_deduction_note,
    net_salary = EXCLUDED.net_salary,
    payment_method = EXCLUDED.payment_method,
    calc_status = EXCLUDED.calc_status,
    calc_source = EXCLUDED.calc_source,
    updated_at = now()
  RETURNING
    public.salary_records.employee_id,
    public.salary_records.month_year,
    v_total_orders,
    v_total_shift_days,
    public.salary_records.base_salary,
    public.salary_records.attendance_deduction,
    public.salary_records.external_deduction,
    public.salary_records.advance_deduction,
    public.salary_records.manual_deduction,
    public.salary_records.net_salary,
    public.salary_records.calc_status
  INTO
    employee_id,
    month_year,
    total_orders,
    total_shift_days,
    base_salary,
    attendance_deduction,
    external_deduction,
    advance_deduction,
    manual_deduction,
    net_salary,
    calc_status;

  RETURN NEXT;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) TO service_role;

COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS
  'v6: fixes INSERT column list (total_orders/total_shift_days/platform_breakdown/status did not exist on salary_records â€” every call failed), restores ON CONFLICT upsert, and restores the TABLE return shape expected by calculate_salary_for_month().';

CREATE OR REPLACE FUNCTION public.replace_daily_orders_month_rpc(
  p_month_year TEXT,
  p_rows JSONB DEFAULT '[]'::jsonb,
  p_source_type TEXT DEFAULT 'manual',
  p_file_name TEXT DEFAULT NULL,
  p_target_app_id UUID DEFAULT NULL
)
RETURNS TABLE (
  batch_id UUID,
  saved_rows INTEGER,
  failed_rows INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public' /* NOSONAR */
AS $$
DECLARE
  v_start DATE;
  v_end DATE;
  v_batch_id UUID;
  v_total_rows INTEGER := COALESCE(jsonb_array_length(COALESCE(p_rows, '[]'::jsonb)), 0);
BEGIN
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), _const_role_admin())
      OR public.has_role(auth.uid(), _const_role_operations())
      OR public.has_role(auth.uid(), _const_role_hr())
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  IF p_source_type NOT IN ('manual', 'excel', 'api') THEN
    RAISE EXCEPTION 'Invalid source_type';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::DATE;

  INSERT INTO public.order_import_batches (
    month_year,
    source_type,
    file_name,
    target_app_id,
    status,
    total_rows,
    started_by,
    meta
  )
  VALUES (
    p_month_year,
    p_source_type,
    NULLIF(BTRIM(p_file_name), ''),
    p_target_app_id,
    _const_installment_pending(),
    v_total_rows,
    auth.uid(),
    jsonb_build_object(
      'replace_mode', 'month',
      'input_rows', v_total_rows
    )
  )
  RETURNING id INTO v_batch_id;

  IF v_total_rows > 0 THEN
    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(COALESCE(p_rows, '[]'::jsonb)) AS x(
        employee_id TEXT,
        app_id TEXT,
        date TEXT,
        orders_count INTEGER
      )
      WHERE x.date::DATE < v_start
         OR x.date::DATE > v_end
         OR x.orders_count <= 0
    ) THEN
      RAISE EXCEPTION 'Input rows must belong to the target month and have positive orders_count';
    END IF;
  END IF;

  DELETE
  FROM public.daily_orders
  WHERE date BETWEEN v_start AND v_end;

  IF v_total_rows > 0 THEN
    INSERT INTO public.daily_orders (
      employee_id,
      app_id,
      date,
      orders_count,
      status,
      source,
      created_by,
      import_batch_id
    )
    SELECT
      x.employee_id::UUID,
      x.app_id::UUID,
      x.date::DATE,
      x.orders_count,
      'confirmed',
      CASE
        WHEN p_source_type = 'excel' THEN 'excel_import'
        ELSE p_source_type
      END,
      auth.uid(),
      v_batch_id
    FROM jsonb_to_recordset(COALESCE(p_rows, '[]'::jsonb)) AS x(
      employee_id TEXT,
      app_id TEXT,
      date TEXT,
      orders_count INTEGER
    )
    ON CONFLICT (employee_id, date, app_id)
    DO UPDATE SET
      orders_count = EXCLUDED.orders_count,
      status = 'confirmed',
      source = EXCLUDED.source,
      import_batch_id = EXCLUDED.import_batch_id,
      updated_at = now();
  END IF;

  UPDATE public.order_import_batches
  SET
    status = 'completed',
    imported_rows = v_total_rows,
    skipped_rows = 0,
    error_count = 0,
    error_summary = '[]'::jsonb,
    completed_at = now(),
    updated_at = now()
  WHERE id = v_batch_id;

  batch_id := v_batch_id;
  saved_rows := v_total_rows;
  failed_rows := 0;
  RETURN NEXT;

EXCEPTION WHEN OTHERS THEN
  IF v_batch_id IS NOT NULL THEN
    UPDATE public.order_import_batches
    SET
      status = 'failed',
      imported_rows = 0,
      skipped_rows = 0,
      error_count = 1,
      error_summary = jsonb_build_array(SQLERRM),
      completed_at = now(),
      updated_at = now()
    WHERE id = v_batch_id;
  END IF;
  RAISE;
END;
$$;

COMMENT ON FUNCTION public.replace_daily_orders_month_rpc(TEXT, JSONB, TEXT, TEXT, UUID) IS
'Transactional month replacement for daily orders with import-batch tracking.';

REVOKE EXECUTE ON FUNCTION public.replace_daily_orders_month_rpc(TEXT, JSONB, TEXT, TEXT, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.replace_daily_orders_month_rpc(TEXT, JSONB, TEXT, TEXT, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid)
  TO authenticated, service_role;

DROP FUNCTION IF EXISTS public.sync_salaries_as_expenses(text);
DROP INDEX IF EXISTS public.idx_daily_orders_perf_employee_date;

-- Backward compatibility for older dashboard RPC call signatures.
-- Some deployed clients still call month/year argument variants.

CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(
  p_month integer,
  p_year integer,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
DECLARE
  v_month_year text;
BEGIN
  IF p_month IS NULL OR p_year IS NULL THEN
    RAISE EXCEPTION 'p_month and p_year are required';
  END IF;

  v_month_year := to_char(make_date(p_year, p_month, 1), 'YYYY-MM');
  RETURN public.dashboard_overview_rpc(v_month_year, COALESCE(p_today, CURRENT_DATE));
END;
$$;

CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(
  p_cip text,
  p_month integer,
  p_year integer,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
BEGIN
  PERFORM p_cip;
  RETURN public.dashboard_overview_rpc(p_month, p_year, COALESCE(p_today, CURRENT_DATE));
END;
$$;

CREATE OR REPLACE FUNCTION public.dashboard_overview(
  p_month integer,
  p_year integer,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
  SELECT public.dashboard_overview_rpc(p_month, p_year, COALESCE(p_today, CURRENT_DATE));
$$;

CREATE OR REPLACE FUNCTION public.dashboard_overview(
  p_cip text,
  p_month integer,
  p_year integer,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
  SELECT public.dashboard_overview_rpc(p_cip, p_month, p_year, COALESCE(p_today, CURRENT_DATE));
$$;

-- Compatibility overloads for backend calls using:
-- dashboard_overview(p_cip, p_monthly_year, p_today)
-- and dashboard_overview_rpc(p_cip, p_monthly_year, p_today).

CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(
  p_cip text,
  p_monthly_year text,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
BEGIN
  PERFORM p_cip;
  RETURN public.dashboard_overview_rpc(p_monthly_year, COALESCE(p_today, CURRENT_DATE));
END;
$$;

CREATE OR REPLACE FUNCTION public.dashboard_overview(
  p_cip text,
  p_monthly_year text,
  p_today date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
  SELECT public.dashboard_overview_rpc(p_monthly_year, COALESCE(p_today, CURRENT_DATE));
$$;

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

CREATE OR REPLACE FUNCTION public.alerts_summary_rpc(
  p_expiry_horizon date,
  p_urgent_horizon date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_employee_total integer := 0;
  v_employee_urgent integer := 0;
  v_vehicle_total integer := 0;
  v_vehicle_urgent integer := 0;
  v_platform_total integer := 0;
  v_platform_urgent integer := 0;
  v_persisted_total integer := 0;
  v_persisted_urgent integer := 0;
  v_absconded_total integer := 0;
BEGIN
  IF p_expiry_horizon IS NULL OR p_urgent_horizon IS NULL THEN
    RAISE EXCEPTION 'Alert horizons are required' USING ERRCODE = '22004';
  END IF;

  IF p_urgent_horizon > p_expiry_horizon THEN
    RAISE EXCEPTION 'Urgent horizon cannot exceed expiry horizon' USING ERRCODE = '22023';
  END IF;

  IF COALESCE(auth.role(), '') <> 'service_role'
     AND NOT COALESCE(public.has_permission('alerts', 'view'), false) THEN
    RAISE EXCEPTION 'Insufficient permission to view alerts' USING ERRCODE = '42501';
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE due.due_date <= p_expiry_horizon)::integer,
    COUNT(*) FILTER (
      WHERE due.due_date <= p_urgent_horizon
        AND (NOT due.is_probation OR due.due_date >= CURRENT_DATE)
    )::integer
  INTO v_employee_total, v_employee_urgent
  FROM public.employees AS employee
  CROSS JOIN LATERAL (
    VALUES
      (employee.residency_expiry, false),
      (employee.probation_end_date, true),
      (employee.health_insurance_expiry, false),
      (employee.license_expiry, false)
  ) AS due(due_date, is_probation)
  WHERE employee.status::text = 'active'
    AND COALESCE(lower(employee.sponsorship_status::text), '') <> ALL (
      ARRAY['absconded', 'expired', 'terminated', 'inactive', 'canceled', 'final_exit']
    )
    AND due.due_date IS NOT NULL;

  SELECT
    COUNT(*) FILTER (WHERE due.due_date <= p_expiry_horizon)::integer,
    COUNT(*) FILTER (WHERE due.due_date <= p_urgent_horizon)::integer
  INTO v_vehicle_total, v_vehicle_urgent
  FROM public.vehicles AS vehicle
  CROSS JOIN LATERAL (
    VALUES (vehicle.insurance_expiry), (vehicle.authorization_expiry)
  ) AS due(due_date)
  WHERE vehicle.status::text IN ('active', 'maintenance', 'rental')
    AND due.due_date IS NOT NULL;

  SELECT
    COUNT(*) FILTER (WHERE account.iqama_expiry_date <= p_expiry_horizon)::integer,
    COUNT(*) FILTER (WHERE account.iqama_expiry_date <= p_urgent_horizon)::integer
  INTO v_platform_total, v_platform_urgent
  FROM public.platform_accounts AS account
  WHERE account.status = 'active'
    AND account.iqama_expiry_date IS NOT NULL;

  SELECT
    COUNT(*)::integer,
    COUNT(*) FILTER (
      WHERE COALESCE(alert.due_date, CURRENT_DATE) <= p_urgent_horizon
    )::integer
  INTO v_persisted_total, v_persisted_urgent
  FROM public.alerts AS alert
  WHERE alert.is_resolved IS FALSE;

  SELECT COUNT(*)::integer
  INTO v_absconded_total
  FROM public.employees AS employee
  WHERE employee.status::text = 'active'
    AND lower(employee.sponsorship_status::text) = 'absconded';

  RETURN jsonb_build_object(
    'unresolved_count',
      v_employee_total + v_vehicle_total + v_platform_total + v_persisted_total + v_absconded_total,
    'urgent_count',
      v_employee_urgent + v_vehicle_urgent + v_platform_urgent + v_persisted_urgent + v_absconded_total
  );
END;
$$;

REVOKE ALL ON FUNCTION public.alerts_summary_rpc(date, date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.alerts_summary_rpc(date, date) TO authenticated, service_role;

COMMENT ON FUNCTION public.alerts_summary_rpc(date, date) IS
  'Returns alert badge counts without loading full alert detail rows into the browser.';

COMMIT;
