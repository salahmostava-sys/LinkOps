CREATE TABLE IF NOT EXISTS public.salary_schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  target_orders INT,
  target_bonus NUMERIC(10,2),
  status public.scheme_status NOT NULL DEFAULT _const_employee_active(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_schemes
  ADD COLUMN IF NOT EXISTS scheme_type TEXT NOT NULL DEFAULT 'order_based',
  ADD COLUMN IF NOT EXISTS monthly_amount NUMERIC DEFAULT NULL;
ALTER TABLE public.salary_schemes
  ADD CONSTRAINT salary_schemes_scheme_type_check
    CHECK (scheme_type IN ('order_based', 'fixed_monthly'));
ALTER TABLE public.salary_schemes ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.salary_schemes ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.salary_schemes ADD CONSTRAINT salary_schemes_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'salary_scheme_tiers_company_id_fkey') THEN