CREATE TABLE IF NOT EXISTS public.vehicle_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  reason TEXT,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.vehicle_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS returned_at timestamp with time zone;
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS start_at timestamp with time zone;

-- FILE: 20260308074600_505a58f7-de3a-4e55-9d20-96bced1928fb.sql
﻿-- Create vehicle_mileage table
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_assignments ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.vehicle_assignments ADD CONSTRAINT vehicle_assignments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'maintenance_logs_company_id_fkey') THEN
ALTER TABLE public.vehicle_assignments
  DROP CONSTRAINT IF EXISTS vehicle_assignments_created_by_fkey;
ALTER TABLE public.vehicle_assignments
  ADD CONSTRAINT vehicle_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;