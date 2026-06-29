ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
CREATE TABLE IF NOT EXISTS public.apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  logo_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.apps 
  ADD COLUMN IF NOT EXISTS brand_color TEXT NOT NULL DEFAULT '#6366f1',
  ADD COLUMN IF NOT EXISTS text_color TEXT NOT NULL DEFAULT '#ffffff';

-- FILE: 20260308111611_3a71d7dd-4a79-494c-aa33-73b5f4dbd9fd.sql
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS scheme_id UUID REFERENCES public.salary_schemes(id) ON DELETE SET NULL;

-- FILE: 20260308125350_32da242e-1c8b-4247-8e75-8057d5e57a62.sql
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS custom_columns JSONB DEFAULT '[]'::jsonb;

-- FILE: 20260318010209_91b4f4a3-6035-43db-aa04-230b6ecf97b6.sql
﻿
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.apps ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.apps ADD CONSTRAINT apps_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'app_targets_company_id_fkey') THEN
ALTER TABLE apps ADD COLUMN IF NOT EXISTS work_type TEXT DEFAULT _const_work_orders() 
  CHECK (work_type IN (_const_work_orders(), _const_work_shift(), _const_work_hybrid()));
COMMENT ON COLUMN apps.work_type IS 'نوع العمل: orders (طلبات), shift (دوام), hybrid (مختلط)';
ALTER TABLE public.apps
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_apps_is_archived ON public.apps(is_archived);
COMMENT ON COLUMN public.apps.is_archived IS
  'Soft archive flag. Archived apps are hidden from all UI lists and salary calculations. '
  'Use is_active to temporarily disable an app for a month.';

-- FILE: 20260504000000_fix_remaining_auth_users_fk.sql