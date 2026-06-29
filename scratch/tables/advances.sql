CREATE TABLE IF NOT EXISTS public.advances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  disbursement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_installments INT NOT NULL DEFAULT 1,
  monthly_amount NUMERIC(10,2) NOT NULL,
  first_deduction_month TEXT NOT NULL,
  note TEXT,
  status public.advance_status NOT NULL DEFAULT _const_employee_active(),
  approved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances 
  ADD COLUMN IF NOT EXISTS is_written_off boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS written_off_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS written_off_reason text;

-- FILE: 20260318015512_c1513ec8-bda1-4b98-b671-dbf9ae05ce75.sql
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.advances
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.advances
      ADD CONSTRAINT advances_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'advance_installments_company_id_fkey'
      AND conrelid = 'public.advance_installments'::regclass
  ) THEN
ALTER TABLE public.advances
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances             ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advances             ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advances
  DROP CONSTRAINT IF EXISTS advances_approved_by_fkey;
ALTER TABLE public.advances
  ADD CONSTRAINT advances_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;