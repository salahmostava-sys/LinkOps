CREATE TABLE IF NOT EXISTS public.platform_accounts (
  id                     UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  app_id                 UUID        NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  account_username       TEXT        NOT NULL,
  account_id_on_platform TEXT,
  iqama_number           TEXT,
  iqama_expiry_date      DATE,
  status                 TEXT        NOT NULL DEFAULT _const_employee_active()
                           CHECK (status IN (_const_employee_active(), 'inactive')),
  notes                  TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_accounts
  ADD COLUMN IF NOT EXISTS employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL;
CREATE TABLE IF NOT EXISTS public.platform_accounts (
  id                      UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  app_id                  UUID        NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  employee_id             UUID        REFERENCES public.employees(id) ON DELETE SET NULL,
  account_username        TEXT        NOT NULL,
  account_id_on_platform  TEXT,
  iqama_number            TEXT,
  iqama_expiry_date       DATE,
  status                  TEXT        NOT NULL DEFAULT _const_employee_active() CHECK (status IN (_const_employee_active(), 'inactive')),
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_accounts
  ADD COLUMN IF NOT EXISTS company_id uuid;
    ALTER TABLE public.platform_accounts
      ADD CONSTRAINT platform_accounts_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'account_assignments_company_id_fkey'
      AND conrelid = 'public.account_assignments'::regclass
  ) THEN
ALTER TABLE public.platform_accounts
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_accounts
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.platform_accounts DROP CONSTRAINT IF EXISTS platform_accounts_company_id_fkey;
ALTER TABLE public.platform_accounts DROP COLUMN IF EXISTS company_id;