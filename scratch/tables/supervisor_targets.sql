CREATE TABLE IF NOT EXISTS public.supervisor_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supervisor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  target_orders NUMERIC(10, 0) NOT NULL DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT supervisor_targets_month_fmt_chk CHECK (month_year ~ '^\d{4}-\d{2}$'),
  CONSTRAINT supervisor_targets_target_non_negative_chk CHECK (target_orders >= 0),
  CONSTRAINT supervisor_targets_unique UNIQUE (supervisor_id, month_year)
);
CREATE INDEX IF NOT EXISTS idx_supervisor_targets_month ON public.supervisor_targets (month_year);
ALTER TABLE public.supervisor_targets ENABLE ROW LEVEL SECURITY;
COMMIT;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260329210000_salary_per_order_band_and_calc_tiers.sql
BEGIN;