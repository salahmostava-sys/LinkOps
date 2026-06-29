CREATE TABLE IF NOT EXISTS public.app_targets (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  month_year text NOT NULL,
  target_orders integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (app_id, month_year)
);
ALTER TABLE public.app_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_targets ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.app_targets ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.app_targets ADD CONSTRAINT app_targets_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'salary_schemes_company_id_fkey') THEN