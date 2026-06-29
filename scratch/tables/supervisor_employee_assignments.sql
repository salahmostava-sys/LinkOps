CREATE TABLE IF NOT EXISTS public.supervisor_employee_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supervisor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT supervisor_employee_assignments_dates_chk
    CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT supervisor_employee_assignments_unique_open UNIQUE (supervisor_id, employee_id, start_date)
);
CREATE INDEX IF NOT EXISTS idx_supervisor_employee_assignments_supervisor
  ON public.supervisor_employee_assignments (supervisor_id, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_supervisor_employee_assignments_employee
  ON public.supervisor_employee_assignments (employee_id, start_date DESC);
ALTER TABLE public.supervisor_employee_assignments ENABLE ROW LEVEL SECURITY;