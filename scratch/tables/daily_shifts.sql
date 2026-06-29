CREATE TABLE IF NOT EXISTS daily_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  hours_worked DECIMAL(4,2) NOT NULL CHECK (hours_worked >= 0 AND hours_worked <= 24),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT daily_shifts_unique_employee_app_date UNIQUE(employee_id, app_id, date)
);
COMMENT ON TABLE daily_shifts IS 'تسجيل ساعات الدوام اليومية للموظفين';
COMMENT ON COLUMN daily_shifts.hours_worked IS 'عدد ساعات العمل في اليوم';
CREATE INDEX IF NOT EXISTS idx_daily_shifts_employee_date ON daily_shifts(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_shifts_app_date ON daily_shifts(app_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_shifts_date ON daily_shifts(date);
ALTER TABLE daily_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_shifts
  DROP CONSTRAINT IF EXISTS daily_shifts_hours_worked_check;
ALTER TABLE public.daily_shifts
  DROP CONSTRAINT IF EXISTS check_hours_worked;
ALTER TABLE public.daily_shifts
  DROP CONSTRAINT IF EXISTS daily_shifts_hours_worked_valid;
ALTER TABLE public.daily_shifts
  ADD CONSTRAINT daily_shifts_hours_worked_valid
  CHECK (
    hours_worked = 1    -- حاضر
    OR hours_worked = -1  -- إجازة براتب
    OR hours_worked = -2  -- إجازة مرضى
    OR hours_worked > 0   -- للتوافق مع البيانات القديمة (ساعات متعددة)
  );
COMMENT ON COLUMN public.daily_shifts.hours_worked IS
  'قيمة الحضور: 1=حاضر | -1=إجازة براتب | -2=إجازة مرضى | >1=ساعات عمل (للأنظمة القديمة)';

-- FILE: 20260503000004_add_is_archived_to_apps.sql