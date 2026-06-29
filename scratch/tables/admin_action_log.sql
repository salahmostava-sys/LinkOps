CREATE TABLE IF NOT EXISTS public.admin_action_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  table_name text NULL,
  record_id text NULL,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  company_id uuid NULL
);
CREATE INDEX IF NOT EXISTS idx_admin_action_log_created_at
  ON public.admin_action_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_action_log_table_record
  ON public.admin_action_log (table_name, record_id);
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;

-- FILE: 20260326001000_dashboard_overview_rpc.sql
﻿-- Dashboard overview aggregation (server-side).

-- FILE: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
﻿-- ============================================================================
INSERT INTO public.roles (title, permissions, is_active)
VALUES
  ('admin', '{}'::jsonb, true),
  ('hr', '{}'::jsonb, true),
  ('finance', '{}'::jsonb, true),
  ('accountant', '{}'::jsonb, true),
  ('operations', '{}'::jsonb, true),
  ('viewer', '{}'::jsonb, true)
ON CONFLICT (title) DO UPDATE
SET is_active = EXCLUDED.is_active;
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  '*', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true, 'approve', true),
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'approve', true),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true, 'approve', true),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = _const_role_admin()::text;
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = 'hr';
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'approve', true),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false, 'approve', true),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title IN ('finance', 'accountant');
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', false, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = 'operations';
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', false, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', false, 'write', false)
)
WHERE title = _const_role_viewer()::text;
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;