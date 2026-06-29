CREATE TABLE IF NOT EXISTS public.employee_scheme (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id),
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  assigned_by UUID REFERENCES auth.users(id)
);
ALTER TABLE public.employee_scheme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_scheme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_scheme ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_scheme ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.employee_scheme ADD CONSTRAINT employee_scheme_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_apps_company_id_fkey') THEN
ALTER TABLE public.employee_scheme
  DROP CONSTRAINT IF EXISTS employee_scheme_assigned_by_fkey;
ALTER TABLE public.employee_scheme
  ADD CONSTRAINT employee_scheme_assigned_by_fkey
  FOREIGN KEY (assigned_by) REFERENCES auth.users(id) ON DELETE SET NULL;