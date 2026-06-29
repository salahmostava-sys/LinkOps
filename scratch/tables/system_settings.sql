CREATE TABLE IF NOT EXISTS public.system_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_name_ar text NOT NULL DEFAULT 'نظام التوصيل',
  project_name_en text NOT NULL DEFAULT 'Delivery System',
  project_subtitle_ar text NOT NULL DEFAULT 'إدارة المناديب',
  project_subtitle_en text NOT NULL DEFAULT 'Rider Management',
  logo_url text,
  default_language text NOT NULL DEFAULT 'ar',
  theme text NOT NULL DEFAULT 'light',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS system_settings_singleton ON public.system_settings ((true));
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
INSERT INTO public.system_settings (project_name_ar, project_name_en, project_subtitle_ar, project_subtitle_en)
VALUES ('نظام التوصيل', 'Delivery System', 'إدارة المناديب', 'Rider Management')
ON CONFLICT DO NOTHING;

-- FILE: 20260308084923_1221af4a-eb12-4835-96fb-9562bcc2249c.sql
ALTER TABLE public.system_settings
  ADD COLUMN IF NOT EXISTS iqama_alert_days INTEGER NOT NULL DEFAULT 90;
ALTER TABLE public.system_settings
  ADD COLUMN IF NOT EXISTS iqama_alert_days INTEGER NOT NULL DEFAULT 90;
UPDATE public.system_settings
SET iqama_alert_days = 90
WHERE iqama_alert_days IS NULL;

-- FILE: 20260324193000_erd_foundation_roles_salary_structure.sql
﻿-- Phase 1 ERD foundation (non-breaking):
ALTER TABLE public.system_settings
  ALTER COLUMN project_name_ar SET DEFAULT 'مهمة التوصيل',
  ALTER COLUMN project_name_en SET DEFAULT 'Muhimmat alTawseel';
UPDATE public.system_settings
SET
  project_name_ar = 'مهمة التوصيل',
  project_name_en = 'Muhimmat alTawseel',
  updated_at = now();

-- FILE: 20260325153000_employees_tenant_rls_hardening.sql
﻿-- ============================================================================
ALTER TABLE public.system_settings ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.system_settings ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.system_settings ADD CONSTRAINT system_settings_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_log_company_id_fkey') THEN