CREATE TABLE IF NOT EXISTS public.employee_apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES public.apps(id),
  username TEXT,
  status TEXT NOT NULL DEFAULT _const_employee_active(),
  joined_date DATE,
  UNIQUE(employee_id, app_id)
);
ALTER TABLE public.employee_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_apps ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_apps ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.employee_apps ADD CONSTRAINT employee_apps_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_tiers_company_id_fkey') THEN