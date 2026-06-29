CREATE TABLE IF NOT EXISTS public.app_monthly_activations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL, -- Format: YYYY-MM
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(app_id, month_year)
);
ALTER TABLE public.app_monthly_activations ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_monthly_activations_month ON public.app_monthly_activations(month_year);
CREATE INDEX IF NOT EXISTS idx_monthly_activations_app ON public.app_monthly_activations(app_id);

-- FILE: 20260106000000_update_salary_engine_for_shifts.sql
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT);
COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS 'Calculate employee salary for a month supporting orders, shifts, and hybrid work types';

-- FILE: 20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql
﻿
CREATE TYPE public.app_role AS ENUM ('admin', 'hr', 'finance', 'operations', 'viewer'); -- NOSONAR
CREATE TYPE public.salary_type AS ENUM (_const_work_shift(), _const_work_orders());
CREATE TYPE public.employee_status AS ENUM (_const_employee_active(), 'inactive', 'ended');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'leave', 'sick', 'late');
CREATE TYPE public.vehicle_type AS ENUM ('motorcycle', 'car');
CREATE TYPE public.vehicle_status AS ENUM (_const_employee_active(), 'maintenance', 'inactive');
CREATE TYPE public.advance_status AS ENUM (_const_employee_active(), 'completed', 'paused');
CREATE TYPE public.installment_status AS ENUM (_const_installment_pending(), 'deducted', _const_installment_deferred());
CREATE TYPE public.deduction_type AS ENUM ('fine', 'return', 'delay', 'accident', 'other');
CREATE TYPE public.approval_status AS ENUM (_const_installment_pending(), _const_approval_approved(), 'rejected');
CREATE TYPE public.maintenance_type AS ENUM ('routine', 'breakdown', 'accident');
CREATE TYPE public.scheme_status AS ENUM (_const_employee_active(), 'archived');