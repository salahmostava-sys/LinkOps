CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plate_number TEXT UNIQUE NOT NULL,
  type public.vehicle_type NOT NULL DEFAULT 'motorcycle',
  brand TEXT,
  model TEXT,
  year INT,
  insurance_expiry DATE,
  registration_expiry DATE,
  status public.vehicle_status NOT NULL DEFAULT _const_employee_active(),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS authorization_expiry date;
ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS plate_number_en TEXT,
  ADD COLUMN IF NOT EXISTS chassis_number TEXT,
  ADD COLUMN IF NOT EXISTS serial_number TEXT;

-- FILE: 20260318022147_16beb355-291d-4c12-8d89-b3e1f31c9338.sql
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS has_fuel_chip boolean NOT NULL DEFAULT false;

-- FILE: 20260318074211_ce2d15d2-a550-4026-889a-c46208c3b4d1.sql
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicles ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.vehicles ADD CONSTRAINT vehicles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_assignments_company_id_fkey') THEN