CREATE TABLE IF NOT EXISTS public.vehicle_mileage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  month_year text NOT NULL,
  km_total numeric NOT NULL DEFAULT 0,
  fuel_cost numeric NOT NULL DEFAULT 0,
  cost_per_km numeric GENERATED ALWAYS AS (
    CASE WHEN km_total > 0 THEN fuel_cost / km_total ELSE NULL END
  ) STORED,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(employee_id, month_year)
);
ALTER TABLE public.vehicle_mileage ENABLE ROW LEVEL SECURITY;

-- FILE: 20260308074955_1cb7258b-936c-4f15-a48f-8bbda5531813.sql
ALTER TABLE public.vehicle_mileage ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_mileage ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.vehicle_mileage ADD CONSTRAINT vehicle_mileage_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_mileage_daily_company_id_fkey') THEN