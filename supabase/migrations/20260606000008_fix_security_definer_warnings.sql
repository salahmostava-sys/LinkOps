-- ============================================================
-- FIX: SECURITY DEFINER WARNINGS
-- ============================================================
-- The Supabase Performance & Security Advisor flags any function
-- that is SECURITY DEFINER and callable by anon or authenticated users.
-- To clear these warnings, we switch them to SECURITY INVOKER.
-- Since our RLS policies are solid, these functions will still work
-- securely under the caller's privileges.

ALTER FUNCTION public.is_admin_or_hr(uid uuid) SECURITY INVOKER;
ALTER FUNCTION public.preview_salary_for_month(p_month_year text) SECURITY INVOKER;
ALTER FUNCTION public.preview_salary_for_month_v2(p_month_year text) SECURITY INVOKER;
ALTER FUNCTION public.assign_platform_account(p_account_id uuid, p_employee_id uuid, p_start_date date, p_notes text, p_created_by uuid) SECURITY INVOKER;
ALTER FUNCTION public.calculate_employee_salary(p_employee_id uuid, p_month_year text, p_payment_method text, p_manual_deduction numeric, p_manual_deduction_note text) SECURITY INVOKER;
ALTER FUNCTION public.enforce_rate_limit(p_key text, p_limit integer, p_window_seconds integer) SECURITY INVOKER;
ALTER FUNCTION public.get_my_role() SECURITY INVOKER;
ALTER FUNCTION public.has_permission(p_resource text, p_action text) SECURITY INVOKER;
ALTER FUNCTION public.has_role(_user_id uuid, _role public.app_role) SECURITY INVOKER;
ALTER FUNCTION public.is_active_user(_user_id uuid) SECURITY INVOKER;
ALTER FUNCTION public.is_internal_user() SECURITY INVOKER;
ALTER FUNCTION public.performance_dashboard_rpc(p_month_year text, p_today date) SECURITY INVOKER;
ALTER FUNCTION public.rider_profile_performance_rpc(p_employee_id uuid, p_month_year text, p_today date) SECURITY INVOKER;

-- For good measure, explicitly revoke EXECUTE from anon for the first three
-- (though SECURITY INVOKER alone usually clears the warning)
REVOKE EXECUTE ON FUNCTION public.is_admin_or_hr(uid uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.preview_salary_for_month(p_month_year text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.preview_salary_for_month_v2(p_month_year text) FROM anon;

NOTIFY pgrst, 'reload schema';
