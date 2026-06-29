CREATE TABLE IF NOT EXISTS public.salary_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  min_orders INTEGER NOT NULL DEFAULT 0,
  max_orders INTEGER,
  tier_type TEXT NOT NULL DEFAULT 'per_order' -- NOSONAR
    CHECK (tier_type IN ('per_order', 'fixed', _const_work_hybrid())),
  rate_per_order NUMERIC(10,2),
  fixed_amount NUMERIC(10,2),
  extra_rate NUMERIC(10,2),
  priority INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT salary_tiers_range_chk CHECK (max_orders IS NULL OR max_orders >= min_orders),
  CONSTRAINT salary_tiers_payload_chk CHECK (
    (tier_type = 'per_order' AND rate_per_order IS NOT NULL) OR
    (tier_type = 'fixed' AND fixed_amount IS NOT NULL) OR
    (tier_type = _const_work_hybrid() AND fixed_amount IS NOT NULL AND extra_rate IS NOT NULL)
  )
);
CREATE INDEX IF NOT EXISTS idx_salary_tiers_app_priority
  ON public.salary_tiers(app_id, is_active, priority DESC);
ALTER TABLE public.salary_tiers ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324213000_seed_roles_permissions_matrix.sql
UPDATE public.roles
SET permissions = jsonb_build_object(
  '*',
  jsonb_build_object('view', true, 'write', true, 'delete', true, 'approve', true), -- NOSONAR
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

-- FILE: 20260324220000_roles_upsert_and_permissions_bootstrap.sql