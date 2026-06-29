CREATE TABLE IF NOT EXISTS public.pl_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month_year TEXT NOT NULL UNIQUE,
  revenue_riders NUMERIC(10,2) NOT NULL DEFAULT 0,
  revenue_other NUMERIC(10,2) NOT NULL DEFAULT 0,
  cost_salaries NUMERIC(10,2) NOT NULL DEFAULT 0,
  cost_vehicles NUMERIC(10,2) NOT NULL DEFAULT 0,
  cost_deductions NUMERIC(10,2) NOT NULL DEFAULT 0,
  cost_other NUMERIC(10,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.pl_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pl_records ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.pl_records ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.pl_records ADD CONSTRAINT pl_records_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'alerts_company_id_fkey') THEN
ALTER TABLE public.pl_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pl_records           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.pl_records
  DROP CONSTRAINT IF EXISTS pl_records_created_by_fkey;
ALTER TABLE public.pl_records
  ADD CONSTRAINT pl_records_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;