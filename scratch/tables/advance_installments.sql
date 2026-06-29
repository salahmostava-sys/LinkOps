CREATE TABLE IF NOT EXISTS public.advance_installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advance_id UUID NOT NULL REFERENCES public.advances(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  status public.installment_status NOT NULL DEFAULT _const_installment_pending(),
  deducted_at TIMESTAMPTZ
);
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS notes text;

-- FILE: 20260318013628_09bf19b4-b17d-4b43-bb94-d55ee18d5628.sql
﻿
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advance_installments
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.advance_installments
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.advance_installments
      ADD CONSTRAINT advance_installments_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_deductions_company_id_fkey'
      AND conrelid = 'public.external_deductions'::regclass
  ) THEN
ALTER TABLE public.advance_installments
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;