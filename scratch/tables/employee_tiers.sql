CREATE TABLE IF NOT EXISTS public.employee_tiers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  package_type TEXT NOT NULL DEFAULT 'شريحة أساسية',
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  renewal_date DATE NOT NULL,
  delivery_status TEXT NOT NULL DEFAULT _const_installment_pending(),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.employee_tiers ENABLE ROW LEVEL SECURITY;

-- FILE: 20260318011345_3b8ae88e-c0ac-444f-af22-613b145dc0d4.sql
ALTER TABLE public.employee_tiers
  ADD COLUMN IF NOT EXISTS sim_number text,
  ADD COLUMN IF NOT EXISTS app_ids jsonb NOT NULL DEFAULT '[]'::jsonb;

-- FILE: 20260318091031_ea72075a-49eb-4399-bdcb-7f2bb16bc19a.sql
ALTER TABLE public.employee_tiers ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_tiers ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.employee_tiers ADD CONSTRAINT employee_tiers_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_company_id_fkey') THEN