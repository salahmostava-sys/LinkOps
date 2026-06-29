CREATE TABLE IF NOT EXISTS public.scheme_month_snapshots (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  scheme_id uuid NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
  month_year text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(scheme_id, month_year)
);
ALTER TABLE public.scheme_month_snapshots ENABLE ROW LEVEL SECURITY;

-- FILE: 20260308071338_da5633c6-2d3d-45dc-b7c1-1d1bc9be8bd6.sql
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'breakdown';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'rental';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'ended';
ALTER TABLE public.scheme_month_snapshots ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.scheme_month_snapshots ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.scheme_month_snapshots ADD CONSTRAINT scheme_month_snapshots_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_scheme_company_id_fkey') THEN