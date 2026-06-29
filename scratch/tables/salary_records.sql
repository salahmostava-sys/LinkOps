CREATE TABLE IF NOT EXISTS public.salary_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  base_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
  allowances NUMERIC(10,2) NOT NULL DEFAULT 0,
  attendance_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
  advance_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
  external_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
  manual_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
  manual_deduction_note TEXT,
  net_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
  is_approved BOOLEAN NOT NULL DEFAULT false,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, month_year)
);
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ADD COLUMN IF NOT EXISTS payment_method text DEFAULT _const_payment_cash() NOT NULL;

-- FILE: 20260308121145_756f2a5b-e50d-4dee-b1fc-7f631d941b1b.sql
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324180000_add_iqama_alert_days_to_system_settings.sql
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS calc_status TEXT NOT NULL DEFAULT _const_calc_calculated()
  CHECK (calc_status IN (_const_calc_calculated(), _const_approval_approved(), 'paid', _const_order_cancelled()));
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS calc_source TEXT NOT NULL DEFAULT 'engine_v1';
CREATE INDEX IF NOT EXISTS idx_salary_records_employee_month
  ON public.salary_records(employee_id, month_year);
CREATE INDEX IF NOT EXISTS idx_salary_records_calc_status
  ON public.salary_records(calc_status);
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.attendance a
SET company_id = e.company_id
FROM public.employees e
WHERE a.employee_id = e.id
  AND a.company_id IS NULL;
UPDATE public.daily_orders d
SET company_id = e.company_id
FROM public.employees e
WHERE d.employee_id = e.id
  AND d.company_id IS NULL;
UPDATE public.advances a
SET company_id = e.company_id
FROM public.employees e
WHERE a.employee_id = e.id
  AND a.company_id IS NULL;
UPDATE public.external_deductions x
SET company_id = e.company_id
FROM public.employees e
WHERE x.employee_id = e.id
  AND x.company_id IS NULL;
UPDATE public.salary_records s
SET company_id = e.company_id
FROM public.employees e
WHERE s.employee_id = e.id
  AND s.company_id IS NULL;
UPDATE public.advance_installments ai
SET company_id = a.company_id
FROM public.advances a
WHERE ai.advance_id = a.id
  AND ai.company_id IS NULL;
ALTER TABLE public.salary_records
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_company_id_fkey'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.salary_records
      ADD CONSTRAINT salary_records_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_daily_orders_company_id ON public.daily_orders(company_id);
CREATE INDEX IF NOT EXISTS idx_advances_company_id ON public.advances(company_id);
CREATE INDEX IF NOT EXISTS idx_advance_installments_company_id ON public.advance_installments(company_id);
CREATE INDEX IF NOT EXISTS idx_external_deductions_company_id ON public.external_deductions(company_id);
CREATE INDEX IF NOT EXISTS idx_salary_records_company_id ON public.salary_records(company_id);
ALTER TABLE public.salary_records
  ALTER COLUMN company_id SET NOT NULL;

-- FILE: 20260325181500_company_id_rollout_remaining_tables.sql
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records       ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.salary_records       ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.salary_records 
ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1 NOT NULL;
ALTER TABLE public.salary_records
ADD COLUMN IF NOT EXISTS sheet_snapshot JSONB;
COMMENT ON COLUMN public.salary_records.sheet_snapshot IS
'Canonical UI snapshot for approved/paid salary rows so the salary sheet can be restored exactly after reload.';

-- FILE: 20260410000000_performance_engine_foundation.sql
﻿BEGIN;
ALTER TABLE public.salary_records
  DROP CONSTRAINT IF EXISTS salary_records_approved_by_fkey;
ALTER TABLE public.salary_records
  ADD CONSTRAINT salary_records_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;