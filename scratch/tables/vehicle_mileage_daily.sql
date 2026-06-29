CREATE TABLE IF NOT EXISTS public.vehicle_mileage_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date date NOT NULL,
  km_total numeric NOT NULL DEFAULT 0,
  fuel_cost numeric NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);
ALTER TABLE public.vehicle_mileage_daily ENABLE ROW LEVEL SECURITY;

-- FILE: 20260320000002_rls_comprehensive_fix.sql
﻿

-- FILE: 20260320000003_profiles_realtime.sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;
END
$$;

-- FILE: 20260320000004_activate_salah_user.sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
UPDATE auth.users
SET
  encrypted_password = extensions.crypt('sala7372495', extensions.gen_salt('bf')),
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  updated_at          = now()
WHERE email = 'salahmostava@gmail.com'; -- NOSONAR
INSERT INTO public.profiles (id, email, name, is_active)
SELECT id, email, 'Salah', true
FROM auth.users
WHERE email = 'salahmostava@gmail.com'
ON CONFLICT (id) DO UPDATE
  SET is_active = true,
      email     = EXCLUDED.email,
      updated_at = now();
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin'
FROM auth.users
WHERE email = 'salahmostava@gmail.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- FILE: 20260320100000_restrict_pii_rls.sql
﻿

-- FILE: 20260321000001_platform_accounts.sql
﻿-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.vehicle_mileage_daily (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date        DATE        NOT NULL,
  km_total    NUMERIC     NOT NULL DEFAULT 0,
  fuel_cost   NUMERIC     NOT NULL DEFAULT 0,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT vehicle_mileage_daily_employee_date_unique UNIQUE (employee_id, date)
);
ALTER TABLE public.vehicle_mileage_daily ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_vehicle_mileage_daily_employee_date
  ON public.vehicle_mileage_daily(employee_id, date);
ALTER TABLE public.vehicle_mileage_daily ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_mileage_daily ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.vehicle_mileage_daily ADD CONSTRAINT vehicle_mileage_daily_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pl_records_company_id_fkey') THEN