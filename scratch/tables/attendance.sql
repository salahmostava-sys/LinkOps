CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status public.attendance_status NOT NULL DEFAULT 'present',
  check_in TIME,
  check_out TIME,
  note TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.attendance
      ADD CONSTRAINT attendance_check_out_after_check_in_chk
      CHECK (check_out IS NULL OR check_in IS NULL OR check_out >= check_in);
  END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS uq_attendance_employee_date
  ON public.attendance(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_status_date
  ON public.attendance(employee_id, status, date);
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS total_hours NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS late BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS early_leave BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_late
  ON public.attendance (employee_id, date, late);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_early_leave
  ON public.attendance (employee_id, date, early_leave);

-- FILE: 20260325120000_external_deductions_linked_advance.sql
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.attendance
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.attendance
      ADD CONSTRAINT attendance_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'daily_orders_company_id_fkey'
      AND conrelid = 'public.daily_orders'::regclass
  ) THEN
ALTER TABLE public.attendance
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS total_hours NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS late BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS early_leave BOOLEAN NOT NULL DEFAULT false;

-- FILE: 20260326021000_phase_1_1_remove_company_id_single_org.sql
BEGIN;
DROP FUNCTION IF EXISTS public.jwt_company_id() CASCADE;
ALTER TABLE public.attendance
  DROP CONSTRAINT IF EXISTS attendance_created_by_fkey;
ALTER TABLE public.attendance
  ADD CONSTRAINT attendance_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;