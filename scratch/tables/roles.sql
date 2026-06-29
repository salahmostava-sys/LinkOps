CREATE TABLE IF NOT EXISTS public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL UNIQUE CHECK (title IN ('admin', 'hr', 'accountant', 'viewer', 'operations')),
  permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO public.roles (title, permissions)
VALUES
  ('admin', '{"*": {"view": true, "edit": true, "delete": true}}'::jsonb),
  ('hr', '{"employees": {"view": true, "edit": true}, "attendance": {"view": true, "edit": true}}'::jsonb),
  ('accountant', '{"salary": {"view": true, "edit": true}, "orders": {"view": true}}'::jsonb),
  ('viewer', '{"*": {"view": true, "edit": false, "delete": false}}'::jsonb),
  ('operations', '{"orders": {"view": true, "edit": true}, "platform_accounts": {"view": true, "edit": true}}'::jsonb)
ON CONFLICT (title) DO NOTHING;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles
  DROP CONSTRAINT IF EXISTS roles_title_check;
ALTER TABLE public.roles
  ADD CONSTRAINT roles_title_check
  CHECK (
    title = ANY (
      ARRAY[
        'admin'::text,
        'hr'::text,
        'finance'::text,
        'accountant'::text,
        'operations'::text,
        'viewer'::text
      ]
    )
  );
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
SET permissions = jsonb_build_object(
  '*',
  jsonb_build_object('view', true, 'write', true, 'delete', true, 'approve', true),
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', true)
)
WHERE title = 'admin';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title = 'hr';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title IN ('finance', 'accountant');
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'operations';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'viewer';

-- FILE: 20260324230000_seed_default_pricing_rules_for_active_apps.sql
INSERT INTO public.pricing_rules (
  app_id,
  min_orders,
  max_orders,
  rule_type,
  rate_per_order,
  fixed_salary,
  bonus_target_orders,
  bonus_amount,
  is_active,
  priority
)
SELECT
  a.id AS app_id,
  0 AS min_orders,
  NULL AS max_orders,
  'per_order'::text AS rule_type,
  0::numeric AS rate_per_order,
  NULL::numeric AS fixed_salary,
  NULL::integer AS bonus_target_orders,
  NULL::numeric AS bonus_amount,
  true AS is_active,
  -1000 AS priority
FROM public.apps a
WHERE a.is_active = true
  AND NOT EXISTS (
    SELECT 1
    FROM public.pricing_rules pr
    WHERE pr.app_id = a.id
  );

-- FILE: 20260324235500_user_roles_role_id_bridge.sql
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;