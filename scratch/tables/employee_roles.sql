CREATE TABLE IF NOT EXISTS public.employee_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (employee_id, role_id)
);
CREATE INDEX IF NOT EXISTS idx_employee_roles_employee ON public.employee_roles(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_roles_role ON public.employee_roles(role_id);
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;