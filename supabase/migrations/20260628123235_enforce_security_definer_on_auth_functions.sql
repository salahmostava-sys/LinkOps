-- ============================================================
-- FIX: Enforce SECURITY DEFINER on core auth functions
-- ============================================================
-- These functions are used inside RLS policies. If they are
-- executed as SECURITY INVOKER, they trigger RLS policies on
-- the tables they query (e.g., profiles, user_roles), which
-- in turn call these functions again, causing infinite recursion
-- and "stack depth limit exceeded" errors.

ALTER FUNCTION public.is_active_user(_user_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.has_role(_user_id uuid, _role public.app_role) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.get_my_role() SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.is_internal_user() SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.is_admin_or_hr(uid uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.employee_in_my_company(_employee_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.advance_in_my_company(_advance_id uuid) SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
