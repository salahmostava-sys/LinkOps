CREATE TABLE IF NOT EXISTS public.employee_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL CHECK (month_year ~ '^\d{4}-\d{2}$'),
  monthly_target_orders INTEGER NOT NULL DEFAULT 0 CHECK (monthly_target_orders >= 0),
  daily_target_orders INTEGER NOT NULL DEFAULT 0 CHECK (daily_target_orders >= 0),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (employee_id, month_year)
);
CREATE INDEX IF NOT EXISTS idx_employee_targets_employee_month
  ON public.employee_targets(employee_id, month_year);
CREATE INDEX IF NOT EXISTS idx_employee_targets_month
  ON public.employee_targets(month_year);
ALTER TABLE public.employee_targets ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.employee_targets IS
'Monthly and daily delivery targets per employee.';