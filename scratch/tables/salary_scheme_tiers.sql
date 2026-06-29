CREATE TABLE IF NOT EXISTS public.salary_scheme_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
  tier_order INT NOT NULL DEFAULT 1,
  from_orders INT NOT NULL DEFAULT 0,
  to_orders INT,
  price_per_order NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_scheme_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_scheme_tiers
  ADD COLUMN IF NOT EXISTS tier_type TEXT NOT NULL DEFAULT 'total_multiplier',
  ADD COLUMN IF NOT EXISTS incremental_threshold INTEGER DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS incremental_price NUMERIC DEFAULT NULL;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
    CHECK (tier_type IN ('total_multiplier', _const_tier_fixed(), _const_tier_incremental()));

-- FILE: 20260318090223_4fe00ba3-9c12-481b-8ba1-2683f82edffa.sql
ALTER TABLE public.salary_scheme_tiers ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.salary_scheme_tiers ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.salary_scheme_tiers ADD CONSTRAINT salary_scheme_tiers_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'scheme_month_snapshots_company_id_fkey') THEN
ALTER TABLE public.salary_scheme_tiers
  DROP CONSTRAINT IF EXISTS salary_scheme_tiers_tier_type_check;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
  CHECK (tier_type IN (
    'total_multiplier',
    _const_tier_fixed(),
    _const_tier_incremental(),
    'per_order_band'
  ));
COMMENT ON FUNCTION public.calc_tier_salary(INTEGER) IS
  'Default tier curve (single-band): 1–300×3، 301–400×4، 401–449×5، 450–470 ثابت 2500، فوق 470: 2500+(n-470)×5. Schemes UI may use per_order_band tiers for the same logic per app.';
COMMIT;

-- FILE: 20260330120000_salary_slip_templates.sql
ALTER TABLE public.salary_scheme_tiers
  DROP CONSTRAINT IF EXISTS salary_scheme_tiers_tier_type_check;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
  CHECK (tier_type IN (
    'total_multiplier',
    _const_tier_fixed(),
    _const_tier_incremental(),
    'per_order_band'
  ));

-- FILE: 20260402010000_assign_platform_account_rpc.sql
﻿BEGIN;
COMMIT;

-- FILE: 20260403000000_add_commercial_record_to_employees.sql