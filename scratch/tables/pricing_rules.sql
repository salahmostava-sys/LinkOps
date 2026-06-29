CREATE TABLE IF NOT EXISTS public.pricing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  min_orders INTEGER NOT NULL DEFAULT 0,
  max_orders INTEGER,
  rule_type TEXT NOT NULL DEFAULT 'per_order' -- NOSONAR
    CHECK (rule_type IN ('per_order', 'fixed', _const_work_hybrid())),
  rate_per_order NUMERIC(10,2),
  fixed_salary NUMERIC(10,2),
  bonus_target_orders INTEGER,
  bonus_amount NUMERIC(10,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT pricing_rules_order_range_chk CHECK (
    max_orders IS NULL OR max_orders >= min_orders
  ),
  CONSTRAINT pricing_rules_payload_chk CHECK (
    (rule_type = 'per_order' AND rate_per_order IS NOT NULL) OR
    (rule_type = 'fixed' AND fixed_salary IS NOT NULL) OR
    (rule_type = _const_work_hybrid() AND rate_per_order IS NOT NULL AND fixed_salary IS NOT NULL)
  )
);
CREATE INDEX IF NOT EXISTS idx_pricing_rules_app_id ON public.pricing_rules(app_id);
CREATE INDEX IF NOT EXISTS idx_pricing_rules_active_priority ON public.pricing_rules(is_active, priority DESC);
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324150000_rls_payroll_attendance_employees_hardening.sql
﻿-- RLS hardening for core payroll-related tables