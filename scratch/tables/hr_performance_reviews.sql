CREATE TABLE IF NOT EXISTS public.hr_performance_reviews (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id         uuid        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  month_year          text        NOT NULL CHECK (month_year ~ '^\d{4}-\d{2}$'),
  reviewer_id         uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  attendance_score    integer     NOT NULL DEFAULT 5 CHECK (attendance_score BETWEEN 1 AND 10),
  performance_score   integer     NOT NULL DEFAULT 5 CHECK (performance_score BETWEEN 1 AND 10),
  behavior_score      integer     NOT NULL DEFAULT 5 CHECK (behavior_score BETWEEN 1 AND 10),
  commitment_score    integer     NOT NULL DEFAULT 5 CHECK (commitment_score BETWEEN 1 AND 10),
  notes               text,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now(),
  CONSTRAINT hr_reviews_unique_employee_month UNIQUE (employee_id, month_year)
);
ALTER TABLE public.hr_performance_reviews ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_hr_reviews_employee  ON public.hr_performance_reviews(employee_id);
CREATE INDEX IF NOT EXISTS idx_hr_reviews_month     ON public.hr_performance_reviews(month_year);

-- FILE: 20260503000003_allow_negative_hours_worked.sql