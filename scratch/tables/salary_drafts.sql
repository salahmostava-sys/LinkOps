CREATE TABLE IF NOT EXISTS public.salary_drafts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  draft_data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(user_id, month_year, employee_id)
);
CREATE INDEX IF NOT EXISTS idx_salary_drafts_user_month 
ON public.salary_drafts(user_id, month_year);
ALTER TABLE public.salary_drafts ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'salary_drafts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.salary_drafts;
  END IF;
END $$;
COMMENT ON COLUMN public.salary_records.version IS 'Optimistic locking version - increments on each update to detect concurrent modifications';
COMMENT ON TABLE public.salary_drafts IS 'Server-side storage for salary editing drafts - replaces localStorage to enable cross-device and multi-user scenarios';
COMMENT ON COLUMN public.salary_drafts.draft_data IS 'JSONB containing: incentives, violations, customDeductions, sickAllowance, transfer, etc.';

-- FILE: 20260407000001_salary_preview_platform_breakdown.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.preview_salary_for_month IS 'v3: Preview salary with shift/hybrid-aware per-platform breakdown';
COMMIT;

-- FILE: 20260407110000_employee_commercial_records_and_iqama_docs.sql
﻿BEGIN;