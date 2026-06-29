CREATE TABLE IF NOT EXISTS public.account_assignments (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id  UUID        NOT NULL REFERENCES public.platform_accounts(id) ON DELETE CASCADE,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date  DATE        NOT NULL,
  end_date    DATE,
  month_year  TEXT        NOT NULL,   -- YYYY-MM
  notes       TEXT,
  created_by  UUID        REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;

-- FILE: 20260323150000_locked_months.sql
CREATE TABLE IF NOT EXISTS public.account_assignments (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id  UUID        NOT NULL REFERENCES public.platform_accounts(id) ON DELETE CASCADE,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date  DATE        NOT NULL DEFAULT CURRENT_DATE,
  end_date    DATE,
  month_year  TEXT        NOT NULL,
  notes       TEXT,
  created_by  UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_account_assignments_account_id ON public.account_assignments(account_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_employee_id ON public.account_assignments(employee_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_open ON public.account_assignments(end_date) WHERE end_date IS NULL;
ALTER TABLE public.account_assignments
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.platform_accounts pa
SET company_id = e.company_id
FROM public.employees e
WHERE pa.employee_id = e.id
  AND pa.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.account_assignments aa
SET company_id = e.company_id
FROM public.employees e
WHERE aa.employee_id = e.id
  AND aa.company_id IS NULL
  AND e.company_id IS NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'platform_accounts_company_id_fkey'
      AND conrelid = 'public.platform_accounts'::regclass
  ) THEN
    ALTER TABLE public.account_assignments
      ADD CONSTRAINT account_assignments_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_platform_accounts_company_id
  ON public.platform_accounts (company_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_company_id
  ON public.account_assignments (company_id);
ALTER TABLE public.account_assignments
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325170000_tenant_rls_ops_finance_tables.sql
﻿-- ============================================================================
ALTER TABLE public.account_assignments
  ALTER COLUMN company_id SET NOT NULL;

-- FILE: 20260325174500_add_company_id_to_operational_tables.sql
﻿-- ============================================================================
ALTER TABLE public.account_assignments DROP CONSTRAINT IF EXISTS account_assignments_company_id_fkey;
ALTER TABLE public.account_assignments DROP COLUMN IF EXISTS company_id;

-- FILE: 20260404010000_cleanup_employee_code_and_employee_cities.sql
BEGIN;
UPDATE public.employees
SET preferred_language = 'ar'
WHERE preferred_language = 'ur';
ALTER TABLE public.account_assignments
  DROP CONSTRAINT IF EXISTS account_assignments_created_by_fkey;
ALTER TABLE public.account_assignments
  ADD CONSTRAINT account_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.account_assignments
  DROP CONSTRAINT IF EXISTS account_assignments_created_by_fkey;
ALTER TABLE public.account_assignments
  ADD CONSTRAINT account_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;