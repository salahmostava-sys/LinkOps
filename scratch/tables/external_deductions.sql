CREATE TABLE IF NOT EXISTS public.external_deductions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  source_app_id UUID REFERENCES public.apps(id),
  type public.deduction_type NOT NULL DEFAULT 'fine',
  amount NUMERIC(10,2) NOT NULL,
  incident_date DATE,
  apply_month TEXT NOT NULL,
  approval_status public.approval_status NOT NULL DEFAULT _const_installment_pending(),
  note TEXT,
  approved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.external_deductions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_deductions
  ADD COLUMN IF NOT EXISTS linked_advance_id UUID REFERENCES public.advances(id) ON DELETE SET NULL;
COMMENT ON COLUMN public.external_deductions.linked_advance_id IS 'عند تحويل المخالفة لسلفة: معرّف السلفة المنشأة';
CREATE INDEX IF NOT EXISTS idx_external_deductions_linked_advance_id
  ON public.external_deductions(linked_advance_id)
  WHERE linked_advance_id IS NOT NULL;

-- FILE: 20260325120001_security_scan_signup_employees_rls.sql
﻿-- ============================================================

-- FILE: 20260325140000_rename_project_muhimmat_altawseel.sql
ALTER TABLE public.external_deductions ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325173000_tenant_integrity_assertions_and_not_null.sql
DO $$
DECLARE
  v_count bigint;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.employees
  WHERE company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % employees rows with NULL company_id', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.platform_accounts
  WHERE company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % platform_accounts rows with NULL company_id', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.account_assignments
  WHERE company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % account_assignments rows with NULL company_id', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.platform_accounts pa
  JOIN public.employees e ON e.id = pa.employee_id
  WHERE pa.employee_id IS NOT NULL
    AND pa.company_id <> e.company_id;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % platform_accounts rows mismatch employee company', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.account_assignments aa
  JOIN public.employees e ON e.id = aa.employee_id
  JOIN public.platform_accounts pa ON pa.id = aa.account_id
  WHERE aa.company_id <> e.company_id
     OR aa.company_id <> pa.company_id;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % account_assignments rows mismatch employee/account company', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.attendance a
  LEFT JOIN public.employees e ON e.id = a.employee_id
  WHERE e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % attendance rows not linked to tenant-bound employees', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.daily_orders d
  LEFT JOIN public.employees e ON e.id = d.employee_id
  WHERE e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % daily_orders rows not linked to tenant-bound employees', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.advances a
  LEFT JOIN public.employees e ON e.id = a.employee_id
  WHERE e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % advances rows not linked to tenant-bound employees', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.salary_records s
  LEFT JOIN public.employees e ON e.id = s.employee_id
  WHERE e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % salary_records rows not linked to tenant-bound employees', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.external_deductions x
  LEFT JOIN public.employees e ON e.id = x.employee_id
  WHERE e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % external_deductions rows not linked to tenant-bound employees', v_count;
  END IF;
  SELECT COUNT(*) INTO v_count
  FROM public.advance_installments ai
  LEFT JOIN public.advances a ON a.id = ai.advance_id
  LEFT JOIN public.employees e ON e.id = a.employee_id
  WHERE a.id IS NULL OR e.id IS NULL OR e.company_id IS NULL;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Tenant integrity failed: % advance_installments rows not linked to tenant-bound employees', v_count;
  END IF;
END $$;
ALTER TABLE public.external_deductions
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.external_deductions
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.external_deductions
      ADD CONSTRAINT external_deductions_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'salary_records_company_id_fkey'
      AND conrelid = 'public.salary_records'::regclass
  ) THEN
ALTER TABLE public.external_deductions
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.external_deductions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_deductions  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.external_deductions  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.external_deductions
  DROP CONSTRAINT IF EXISTS external_deductions_approved_by_fkey;
ALTER TABLE public.external_deductions
  ADD CONSTRAINT external_deductions_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;