CREATE TABLE IF NOT EXISTS public.salary_slip_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    header_html TEXT DEFAULT '',
    footer_html TEXT DEFAULT '',
    selected_columns JSONB DEFAULT '[]'::jsonb,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.salary_slip_templates ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';
INSERT INTO public.salary_slip_templates (name, header_html, footer_html, selected_columns, is_default)
VALUES (
    'Default Enterprise Template',
    '<div class="header"><div><div class="header-brand">Muhimmat Delivery</div><div class="header-subtitle">Monthly Salary Slip</div></div></div>',
    '<div class="footer"><div class="signature-box"><div class="signature-line"></div><div>Employee Signature</div></div><div class="signature-box"><div class="signature-line"></div><div>Management Approval</div></div></div>',
    '["employeeName", "nationalId", "totalOrders", "baseSalary", "incentives", "netSalary"]'::jsonb,
    true
) ON CONFLICT DO NOTHING;

-- FILE: 20260401000000_fix_tier_type_constraint.sql
ALTER TABLE public.salary_slip_templates
  ADD COLUMN IF NOT EXISTS header_html TEXT,
  ADD COLUMN IF NOT EXISTS footer_html TEXT,
  ADD COLUMN IF NOT EXISTS selected_columns JSONB DEFAULT '[]'::jsonb;

-- FILE: 20260415000000_audit_log_performance.sql
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON public.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON public.audit_log(table_name);

-- FILE: 20260415000001_constants.sql
﻿-- =============================================================================
DO $$ BEGIN
  CREATE TEMP TABLE IF NOT EXISTS _order_statuses AS
  SELECT _const_order_cancelled()::TEXT AS cancelled;
  CREATE TEMP TABLE IF NOT EXISTS _installment_statuses AS
  SELECT 
    _const_installment_pending()::TEXT AS pending,
    _const_installment_deferred()::TEXT AS deferred;
  CREATE TEMP TABLE IF NOT EXISTS _approval_statuses AS
  SELECT _const_approval_approved()::TEXT AS approved;
  CREATE TEMP TABLE IF NOT EXISTS _work_types AS
  SELECT
    _const_work_orders()::TEXT AS orders,
    _const_work_shift()::TEXT AS shift,
    _const_work_hybrid()::TEXT AS hybrid;
  CREATE TEMP TABLE IF NOT EXISTS _calc_methods AS
  SELECT
    _const_work_orders()::TEXT AS orders,
    _const_work_shift()::TEXT AS shift,
    _const_calc_method_shift_fixed()::TEXT AS shift_fixed,
    _const_calc_method_shift_full_month()::TEXT AS shift_full_month,
    _const_calc_method_mixed()::TEXT AS mixed,
    _const_calc_method_orders_fallback()::TEXT AS orders_fallback;
  CREATE TEMP TABLE IF NOT EXISTS _tier_types AS
  SELECT
    _const_tier_fixed()::TEXT AS fixed_amount,
    _const_tier_incremental()::TEXT AS base_plus_incremental,
    'per_order'::TEXT AS per_order;
  CREATE TEMP TABLE IF NOT EXISTS _payment_methods AS
  SELECT
    _const_payment_cash()::TEXT AS cash,
    _const_payment_bank()::TEXT AS bank;
  CREATE TEMP TABLE IF NOT EXISTS _calc_statuses AS
  SELECT _const_calc_calculated()::TEXT AS calculated;
  CREATE TEMP TABLE IF NOT EXISTS _calc_sources AS
  SELECT
    _const_calc_source_v6()::TEXT AS v6_shift_fallback,
    _const_calc_source_v7()::TEXT AS v7_shift_fixed;
  CREATE TEMP TABLE IF NOT EXISTS _employee_statuses AS
  SELECT _const_employee_active()::TEXT AS active;
  CREATE TEMP TABLE IF NOT EXISTS _numeric_constants AS
  SELECT
    _const_days_per_month()::NUMERIC AS days_per_month,
    0::NUMERIC AS zero;
END $$;
CREATE OR REPLACE FUNCTION _const_order_cancelled() RETURNS TEXT AS $$
  SELECT 'cancelled'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_installment_pending() RETURNS TEXT AS $$
  SELECT 'pending'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_installment_deferred() RETURNS TEXT AS $$
  SELECT 'deferred'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_approval_approved() RETURNS TEXT AS $$
  SELECT 'approved'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_orders() RETURNS TEXT AS $$
  SELECT 'orders'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_shift() RETURNS TEXT AS $$
  SELECT 'shift'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_hybrid() RETURNS TEXT AS $$
  SELECT 'hybrid'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_days_per_month() RETURNS NUMERIC AS $$
  SELECT 30.0::NUMERIC;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_employee_active() RETURNS TEXT AS $$
  SELECT 'active'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_payment_cash() RETURNS TEXT AS $$
  SELECT 'cash'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_payment_bank() RETURNS TEXT AS $$
  SELECT 'bank'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_calculated() RETURNS TEXT AS $$
  SELECT 'calculated'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_source_v6() RETURNS TEXT AS $$
  SELECT 'engine_v6_shift_fallback'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_source_v7() RETURNS TEXT AS $$
  SELECT 'engine_v7_shift_fixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_orders() RETURNS TEXT AS $$
  SELECT _const_work_orders()::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift() RETURNS TEXT AS $$
  SELECT _const_work_shift()::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift_fixed() RETURNS TEXT AS $$
  SELECT 'shift_fixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift_full_month() RETURNS TEXT AS $$
  SELECT 'shift_full_month'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_mixed() RETURNS TEXT AS $$
  SELECT 'mixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_orders_fallback() RETURNS TEXT AS $$
  SELECT 'orders_fallback'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_tier_fixed() RETURNS TEXT AS $$
  SELECT 'fixed_amount'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_tier_incremental() RETURNS TEXT AS $$
  SELECT 'base_plus_incremental'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
COMMENT ON FUNCTION _const_order_cancelled() IS 'Constant: cancelled order status';
COMMENT ON FUNCTION _const_installment_pending() IS 'Constant: pending installment status';
COMMENT ON FUNCTION _const_installment_deferred() IS 'Constant: deferred installment status';
COMMENT ON FUNCTION _const_approval_approved() IS 'Constant: approved status';
COMMENT ON FUNCTION _const_work_orders() IS 'Constant: orders work type';
COMMENT ON FUNCTION _const_work_shift() IS 'Constant: shift work type';
COMMENT ON FUNCTION _const_work_hybrid() IS 'Constant: hybrid work type';
COMMENT ON FUNCTION _const_days_per_month() IS 'Constant: 30 days per month for salary calculations';
COMMENT ON FUNCTION _const_employee_active() IS 'Constant: active employee status';
COMMENT ON FUNCTION _const_payment_cash() IS 'Constant: cash payment method';
COMMENT ON FUNCTION _const_payment_bank() IS 'Constant: bank payment method';
COMMENT ON FUNCTION _const_calc_calculated() IS 'Constant: calculated status';
COMMENT ON FUNCTION _const_tier_fixed() IS 'Constant: fixed_amount tier type';
COMMENT ON FUNCTION _const_tier_incremental() IS 'Constant: base_plus_incremental tier type';
COMMENT ON FUNCTION _const_calc_source_v6() IS 'Constant: engine_v6_shift_fallback calc source';
COMMENT ON FUNCTION _const_calc_source_v7() IS 'Constant: engine_v7_shift_fixed calc source';
COMMENT ON FUNCTION _const_calc_method_orders() IS 'Constant: orders calculation method';
COMMENT ON FUNCTION _const_calc_method_shift() IS 'Constant: shift calculation method';
COMMENT ON FUNCTION _const_calc_method_shift_fixed() IS 'Constant: shift_fixed calculation method';
COMMENT ON FUNCTION _const_calc_method_shift_full_month() IS 'Constant: shift_full_month calculation method';
COMMENT ON FUNCTION _const_calc_method_mixed() IS 'Constant: mixed calculation method';
COMMENT ON FUNCTION _const_calc_method_orders_fallback() IS 'Constant: orders_fallback calculation method';

-- FILE: 20260415100000_fix_calc_tier_with_scheme_id.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(integer);

-- FILE: 20260415200000_debug_and_fix_shift_salary.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);

-- FILE: 20260415210000_shift_salary_fallback_full_month.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260415220000_shift_salary_always_full_month.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260416000000_apply_constants_pattern.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(integer, uuid);
COMMENT ON FUNCTION public.calc_tier_salary(INTEGER, UUID) IS 
  'Refactored to use constants - fixes SonarCloud literal duplication';
COMMENT ON FUNCTION public.preview_salary_for_month_v2(TEXT) IS 
  'Example function showing constant usage - replace preview_salary_for_month in production';

-- FILE: 20260416000001_refactor_shift_salary_with_constants.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS 
  'Refactored with constants - fixes SonarCloud CRITICAL: 10+ literal duplications removed';
COMMENT ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) IS 
  'Refactored with constants - fixes SonarCloud CRITICAL: 10+ literal duplications removed';

-- FILE: 20260416000002_fix_security_definer_permissions.sql
COMMENT ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) IS 
  'SECURITY DEFINER - service_role only. Calculates and saves salary for an employee.';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS 
  'SECURITY DEFINER - service_role only. Previews salary calculations for all employees.';
COMMENT ON FUNCTION public.has_permission(TEXT, TEXT) IS 
  'SECURITY DEFINER - authenticated only. Checks if current user has a specific permission.';
COMMENT ON FUNCTION public.has_role(UUID, public.app_role) IS 
  'SECURITY DEFINER - authenticated only. Checks if a user has a specific role.';
COMMENT ON FUNCTION public.is_admin_or_hr(UUID) IS 
  'SECURITY DEFINER - authenticated only. Checks if user is admin or HR.';
NOTIFY pgrst, 'reload schema';

-- FILE: 20260416000003_unique_default_slip_template.sql
DO $$
BEGIN
  IF (SELECT count(*) FROM salary_slip_templates WHERE is_default = true) > 1 THEN
    UPDATE salary_slip_templates
    SET is_default = false
    WHERE is_default = true
      AND id != (
        SELECT id FROM salary_slip_templates
        WHERE is_default = true
        ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST
        LIMIT 1
      );
  END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS idx_salary_slip_templates_single_default
  ON salary_slip_templates (is_default)
  WHERE is_default = true;

-- FILE: 20260501000000_fix_security_warnings.sql
ALTER FUNCTION public.calc_tier_salary SET search_path = public;

-- FILE: 20260502000000_flip_admin_rider_logic.sql
DROP FUNCTION IF EXISTS public.is_salary_admin_job_title(TEXT);

-- FILE: 20260503000000_leave_requests.sql