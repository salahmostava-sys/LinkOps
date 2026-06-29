CREATE TABLE IF NOT EXISTS app_hybrid_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE UNIQUE,
  min_hours_for_shift DECIMAL(4,2) NOT NULL CHECK (min_hours_for_shift > 0),
  shift_rate DECIMAL(10,2) NOT NULL CHECK (shift_rate >= 0),
  fallback_to_orders BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
COMMENT ON TABLE app_hybrid_rules IS 'قواعد المنصات المختلطة (دوام أو طلبات)';
COMMENT ON COLUMN app_hybrid_rules.min_hours_for_shift IS 'الحد الأدنى من الساعات لاحتساب الدوام';
COMMENT ON COLUMN app_hybrid_rules.shift_rate IS 'سعر الدوام اليومي بالريال';
COMMENT ON COLUMN app_hybrid_rules.fallback_to_orders IS 'التحويل لحساب الطلبات عند عدم تحقيق الساعات المطلوبة';
CREATE OR REPLACE FUNCTION check_no_overlap_orders_shifts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'daily_shifts' THEN
    IF EXISTS (
      SELECT 1 FROM daily_orders 
      WHERE employee_id = NEW.employee_id 
        AND app_id = NEW.app_id 
        AND date = NEW.date
    ) THEN
      RAISE EXCEPTION 'لا يمكن تسجيل دوام في يوم يحتوي على طلبات لنفس الموظف والمنصة';
    END IF;
  END IF;
  IF TG_TABLE_NAME = 'daily_orders' THEN
    IF EXISTS (
      SELECT 1 FROM daily_shifts 
      WHERE employee_id = NEW.employee_id 
        AND app_id = NEW.app_id 
        AND date = NEW.date
    ) THEN
      RAISE EXCEPTION 'لا يمكن تسجيل طلبات في يوم يحتوي على دوام لنفس الموظف والمنصة';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION update_daily_shifts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
ALTER TABLE app_hybrid_rules ENABLE ROW LEVEL SECURITY;

-- FILE: 20260406000000_fix_salary_preview_for_shifts.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.preview_salary_for_month IS 'v2: Preview salary supporting orders, shift, and hybrid work types';
COMMIT;

-- FILE: 20260407000000_concurrent_editing_protection.sql