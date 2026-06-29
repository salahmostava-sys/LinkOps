-- TABLE: account_assignments
CREATE TABLE IF NOT EXISTS public.account_assignments (
    id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    account_id  UUID        NOT NULL REFERENCES public.platform_accounts(id) ON DELETE CASCADE,
    employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    start_date  DATE        NOT NULL,
    end_date    DATE,
    month_year  TEXT        NOT NULL,
    -- YYYY-MM
  notes       TEXT,
    created_by  UUID        REFERENCES auth.users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;


-- TABLE: admin_action_log
CREATE TABLE IF NOT EXISTS public.admin_action_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    user_id uuid NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    action text NOT NULL,
    table_name text NULL,
    record_id text NULL,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb,
    company_id uuid NULL
);
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;


-- TABLE: advances
CREATE TABLE IF NOT EXISTS public.advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL,
    disbursement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_installments INT NOT NULL DEFAULT 1,
    monthly_amount NUMERIC(10,2) NOT NULL,
    first_deduction_month TEXT NOT NULL,
    note TEXT,
    status public.advance_status NOT NULL DEFAULT _const_employee_active(),
    approved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_written_off boolean NOT NULL DEFAULT false,
    written_off_at timestamp with time zone,
    written_off_reason text,
    company_id uuid,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;


-- TABLE: advance_installments
CREATE TABLE IF NOT EXISTS public.advance_installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    advance_id UUID NOT NULL REFERENCES public.advances(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    status public.installment_status NOT NULL DEFAULT _const_installment_pending(),
    deducted_at TIMESTAMPTZ,
    notes text,
    company_id uuid,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;


-- TABLE: alerts
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL,
    entity_id UUID,
    entity_type TEXT,
    due_date DATE,
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    message TEXT,
    details JSONB,
    company_id uuid
);
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;


-- TABLE: apps
CREATE TABLE IF NOT EXISTS public.apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_en TEXT,
    logo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_archived BOOLEAN NOT NULL DEFAULT false,
    brand_color TEXT NOT NULL DEFAULT '#6366f1',
    text_color TEXT NOT NULL DEFAULT '#ffffff',
    scheme_id UUID REFERENCES public.salary_schemes(id) ON DELETE SET NULL,
    custom_columns JSONB DEFAULT '[]'::jsonb,
    company_id uuid
);
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;


-- TABLE: app_hybrid_rules
CREATE TABLE IF NOT EXISTS public.app_hybrid_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE UNIQUE,
    min_hours_for_shift DECIMAL(4,2) NOT NULL CHECK (min_hours_for_shift > 0),
    shift_rate DECIMAL(10,2) NOT NULL CHECK (shift_rate >= 0),
    fallback_to_orders BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.app_hybrid_rules ENABLE ROW LEVEL SECURITY;


-- TABLE: app_monthly_activations
CREATE TABLE IF NOT EXISTS public.app_monthly_activations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL,
    -- Format: YYYY-MM
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(app_id, month_year)
);
ALTER TABLE public.app_monthly_activations ENABLE ROW LEVEL SECURITY;


-- TABLE: app_targets
CREATE TABLE IF NOT EXISTS public.app_targets (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    month_year text NOT NULL,
    target_orders integer NOT NULL DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE (app_id, month_year),
    company_id uuid
);
ALTER TABLE public.app_targets ENABLE ROW LEVEL SECURITY;


-- TABLE: attendance
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
    UNIQUE(employee_id, date),
    total_hours NUMERIC(6,
    late BOOLEAN NOT NULL DEFAULT false,
    early_leave BOOLEAN NOT NULL DEFAULT false,
    company_id uuid,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;


-- TABLE: attendance_status_configs
CREATE TABLE IF NOT EXISTS public.attendance_status_configs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    color text NOT NULL DEFAULT '#6366f1',
    created_at timestamptz DEFAULT now()
);
ALTER TABLE public.attendance_status_configs ENABLE ROW LEVEL SECURITY;


-- TABLE: audit_log
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id UUID,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    company_id uuid
);
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;


-- TABLE: commercial_records
CREATE TABLE IF NOT EXISTS public.commercial_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT commercial_records_name_not_blank CHECK (btrim(name) <> '')
);
ALTER TABLE public.commercial_records ENABLE ROW LEVEL SECURITY;


-- TABLE: daily_orders
CREATE TABLE IF NOT EXISTS public.daily_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    app_id UUID NOT NULL REFERENCES public.apps(id),
    orders_count INT NOT NULL DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(employee_id, date, app_id),
    source TEXT NOT NULL DEFAULT 'manual',
    company_id uuid,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    import_batch_id UUID REFERENCES public.order_import_batches(id) ON DELETE SET NULL
);
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;


-- TABLE: daily_shifts
CREATE TABLE IF NOT EXISTS public.daily_shifts (
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
ALTER TABLE public.daily_shifts ENABLE ROW LEVEL SECURITY;


-- TABLE: departments
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT,
    manager_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    company_id uuid
);
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;


-- TABLE: edge_rate_limits
CREATE TABLE IF NOT EXISTS public.edge_rate_limits (
    key text PRIMARY KEY,
    window_start timestamptz NOT NULL,
    request_count integer NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.edge_rate_limits ENABLE ROW LEVEL SECURITY;


-- TABLE: employees
CREATE TABLE IF NOT EXISTS public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_en TEXT,
    phone TEXT,
    national_id TEXT UNIQUE,
    iban TEXT,
    is_sponsored BOOLEAN NOT NULL DEFAULT false,
    dob DATE,
    residency_expiry DATE,
    license_has BOOLEAN NOT NULL DEFAULT false,
    license_expiry DATE,
    email TEXT,
    salary_type public.salary_type NOT NULL DEFAULT _const_work_orders(),
    base_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
    allowances JSONB DEFAULT '{}',
    status public.employee_status NOT NULL DEFAULT _const_employee_active(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    job_title text,
    bank_account_number text,
    city public.city_enum,
    join_date date,
    license_status public.license_status_enum DEFAULT 'no_license',
    sponsorship_status public.sponsorship_status_enum DEFAULT 'not_sponsored',
    id_photo_url text,
    license_photo_url text,
    personal_photo_url text,
    preferred_language text NOT NULL DEFAULT 'ar' CHECK (preferred_language IN ('ar',
    nationality text,
    birth_date date,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    position_id UUID REFERENCES public.positions(id) ON DELETE SET NULL,
    probation_end_date date NULL,
    health_insurance_expiry date,
    role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL,
    company_id uuid,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    commercial_record TEXT,
    cities text[],
    iqama_photo_url text
);
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;


-- TABLE: employee_apps
CREATE TABLE IF NOT EXISTS public.employee_apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    app_id UUID NOT NULL REFERENCES public.apps(id),
    username TEXT,
    status TEXT NOT NULL DEFAULT _const_employee_active(),
    joined_date DATE,
    UNIQUE(employee_id, app_id),
    company_id uuid
);
ALTER TABLE public.employee_apps ENABLE ROW LEVEL SECURITY;


-- TABLE: employee_roles
CREATE TABLE IF NOT EXISTS public.employee_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    UNIQUE (employee_id, role_id)
);
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;


-- TABLE: employee_scheme
CREATE TABLE IF NOT EXISTS public.employee_scheme (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id),
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_by UUID REFERENCES auth.users(id),
    company_id uuid
);
ALTER TABLE public.employee_scheme ENABLE ROW LEVEL SECURITY;


-- TABLE: employee_targets
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
ALTER TABLE public.employee_targets ENABLE ROW LEVEL SECURITY;


-- TABLE: employee_tiers
CREATE TABLE IF NOT EXISTS public.employee_tiers (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    package_type TEXT NOT NULL DEFAULT 'شريحة أساسية',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    renewal_date DATE NOT NULL,
    delivery_status TEXT NOT NULL DEFAULT _const_installment_pending(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    sim_number text,
    app_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
    company_id uuid
);
ALTER TABLE public.employee_tiers ENABLE ROW LEVEL SECURITY;


-- TABLE: external_deductions
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    linked_advance_id UUID REFERENCES public.advances(id) ON DELETE SET NULL,
    company_id uuid,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.external_deductions ENABLE ROW LEVEL SECURITY;


-- TABLE: finance_transactions
CREATE TABLE IF NOT EXISTS public.finance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('revenue', 'expense')),
    category TEXT NOT NULL,
    description TEXT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    month_year TEXT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_auto BOOLEAN NOT NULL DEFAULT false,
    reference_type TEXT,
    reference_id UUID,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.finance_transactions ENABLE ROW LEVEL SECURITY;


-- TABLE: hr_performance_reviews
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


-- TABLE: IF
ALTER TABLE IF EXISTS public.employees DROP CONSTRAINT IF EXISTS employees_company_id_fkey;
ALTER TABLE IF EXISTS public.user_roles DROP CONSTRAINT IF EXISTS user_roles_company_id_fkey;
ALTER TABLE IF EXISTS public.user_permissions DROP CONSTRAINT IF EXISTS user_permissions_company_id_fkey;
ALTER TABLE IF EXISTS public.departments DROP CONSTRAINT IF EXISTS departments_company_id_fkey;
ALTER TABLE IF EXISTS public.positions DROP CONSTRAINT IF EXISTS positions_company_id_fkey;
ALTER TABLE IF EXISTS public.apps DROP CONSTRAINT IF EXISTS apps_company_id_fkey;
ALTER TABLE IF EXISTS public.app_targets DROP CONSTRAINT IF EXISTS app_targets_company_id_fkey;
ALTER TABLE IF EXISTS public.salary_schemes DROP CONSTRAINT IF EXISTS salary_schemes_company_id_fkey;
ALTER TABLE IF EXISTS public.salary_scheme_tiers DROP CONSTRAINT IF EXISTS salary_scheme_tiers_company_id_fkey;
ALTER TABLE IF EXISTS public.scheme_month_snapshots DROP CONSTRAINT IF EXISTS scheme_month_snapshots_company_id_fkey;
ALTER TABLE IF EXISTS public.employee_scheme DROP CONSTRAINT IF EXISTS employee_scheme_company_id_fkey;
ALTER TABLE IF EXISTS public.employee_apps DROP CONSTRAINT IF EXISTS employee_apps_company_id_fkey;
ALTER TABLE IF EXISTS public.employee_tiers DROP CONSTRAINT IF EXISTS employee_tiers_company_id_fkey;
ALTER TABLE IF EXISTS public.vehicles DROP CONSTRAINT IF EXISTS vehicles_company_id_fkey;
ALTER TABLE IF EXISTS public.vehicle_assignments DROP CONSTRAINT IF EXISTS vehicle_assignments_company_id_fkey;
ALTER TABLE IF EXISTS public.maintenance_logs DROP CONSTRAINT IF EXISTS maintenance_logs_company_id_fkey;
ALTER TABLE IF EXISTS public.vehicle_mileage DROP CONSTRAINT IF EXISTS vehicle_mileage_company_id_fkey;
ALTER TABLE IF EXISTS public.vehicle_mileage_daily DROP CONSTRAINT IF EXISTS vehicle_mileage_daily_company_id_fkey;
ALTER TABLE IF EXISTS public.daily_orders DROP CONSTRAINT IF EXISTS daily_orders_company_id_fkey;
ALTER TABLE IF EXISTS public.attendance DROP CONSTRAINT IF EXISTS attendance_company_id_fkey;
ALTER TABLE IF EXISTS public.external_deductions DROP CONSTRAINT IF EXISTS external_deductions_company_id_fkey;
ALTER TABLE IF EXISTS public.advances DROP CONSTRAINT IF EXISTS advances_company_id_fkey;
ALTER TABLE IF EXISTS public.advance_installments DROP CONSTRAINT IF EXISTS advance_installments_company_id_fkey;
ALTER TABLE IF EXISTS public.salary_records DROP CONSTRAINT IF EXISTS salary_records_company_id_fkey;
ALTER TABLE IF EXISTS public.pl_records DROP CONSTRAINT IF EXISTS pl_records_company_id_fkey;
ALTER TABLE IF EXISTS public.alerts DROP CONSTRAINT IF EXISTS alerts_company_id_fkey;
ALTER TABLE IF EXISTS public.locked_months DROP CONSTRAINT IF EXISTS locked_months_company_id_fkey;
ALTER TABLE IF EXISTS public.system_settings DROP CONSTRAINT IF EXISTS system_settings_company_id_fkey;
ALTER TABLE IF EXISTS public.audit_log DROP CONSTRAINT IF EXISTS audit_log_company_id_fkey;
ALTER TABLE IF EXISTS public.admin_action_log DROP CONSTRAINT IF EXISTS admin_action_log_company_id_fkey;
ALTER TABLE IF EXISTS public.platform_accounts DROP CONSTRAINT IF EXISTS platform_accounts_company_id_fkey;
ALTER TABLE IF EXISTS public.platform_account_assignments DROP CONSTRAINT IF EXISTS platform_account_assignments_company_id_fkey;
ALTER TABLE IF EXISTS public.employees DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.daily_orders DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.attendance DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.advances DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.advance_installments DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.external_deductions DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.salary_records DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.pl_records DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.user_roles DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.user_permissions DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.departments DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.positions DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.apps DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.app_targets DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.salary_schemes DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.salary_scheme_tiers DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.scheme_month_snapshots DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.employee_scheme DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.employee_apps DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.employee_tiers DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.vehicles DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.vehicle_assignments DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.maintenance_logs DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.vehicle_mileage DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.vehicle_mileage_daily DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.alerts DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.locked_months DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.system_settings DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.audit_log DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.admin_action_log DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.platform_accounts DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.platform_account_assignments DROP COLUMN IF EXISTS company_id CASCADE;
DROP TABLE IF EXISTS public.companies CASCADE;
COMMIT;

-- FILE: 20260327092500_restore_single_org_salary_functions.sql
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(uuid, text, text, numeric, text) CASCADE;
DROP FUNCTION IF EXISTS public.calculate_salary_for_month(text, text) CASCADE;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text) CASCADE;

-- FILE: 20260327101500_fix_dashboard_overview_city_enum_unknown.sql
﻿-- Fix dashboard_overview_rpc city enum casting issue.

-- FILE: 20260327120000_finalize_remove_company_id_single_org.sql
﻿-- Final cleanup: remove any remaining company_id dependencies.
BEGIN;
ALTER TABLE IF EXISTS public.profiles DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.employees DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.attendance DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.daily_orders DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.advances DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.advance_installments DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.external_deductions DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.salary_records DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.platform_accounts DROP COLUMN IF EXISTS company_id CASCADE;
ALTER TABLE IF EXISTS public.platform_account_assignments DROP COLUMN IF EXISTS company_id CASCADE;
DROP FUNCTION IF EXISTS public.sync_attendance_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_daily_orders_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_advances_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_external_deductions_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_salary_records_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_advance_installments_company_id() CASCADE;
COMMIT;

-- FILE: 20260327120001_avatars_allow_svg_mime.sql
UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']::text[]
WHERE id = 'avatars';

-- FILE: 20260327123500_fix_employees_visibility_after_company_id_removal.sql
BEGIN;
ALTER TABLE IF EXISTS public.account_assignments DROP COLUMN IF EXISTS company_id CASCADE;
COMMIT;

-- FILE: 20260328220000_fleet_spare_parts.sql
﻿-- Fleet: spare parts inventory (single-org RLS aligned with vehicles / fuel)
BEGIN;
ALTER TABLE IF EXISTS public.maintenance_logs RENAME TO maintenance_logs_legacy_pre_fleet;

-- TABLE: leave_requests
CREATE TABLE IF NOT EXISTS public.leave_requests (
    id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id      uuid        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    type             text        NOT NULL CHECK (type IN ('annual','sick','emergency','unpaid','other')),
    start_date       date        NOT NULL,
    end_date         date        NOT NULL,
    days_count       integer     NOT NULL CHECK (days_count > 0),
    status           text        NOT NULL DEFAULT _const_installment_pending() CHECK (status IN (_const_installment_pending(),
    _const_approval_approved(),'rejected')),
    reason           text,
    reviewer_id      uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
    review_note      text,
    reviewed_at      timestamptz,
    created_by       uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at       timestamptz DEFAULT now(),
    updated_at       timestamptz DEFAULT now(),
    CONSTRAINT leave_dates_check CHECK (end_date >= start_date)
);
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;


-- TABLE: locked_months
CREATE TABLE IF NOT EXISTS public.locked_months (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    month_year TEXT NOT NULL UNIQUE,
    locked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    locked_by UUID REFERENCES auth.users(id),
    company_id uuid
);
ALTER TABLE public.locked_months ENABLE ROW LEVEL SECURITY;


-- TABLE: maintenance_logs
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    type public.maintenance_type NOT NULL DEFAULT 'routine',
    description TEXT,
    cost NUMERIC(10,2) DEFAULT 0,
    paid_by TEXT DEFAULT 'company',
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'completed',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    company_id uuid
);
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;


-- TABLE: maintenance_parts
CREATE TABLE IF NOT EXISTS public.maintenance_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_log_id UUID NOT NULL REFERENCES public.maintenance_logs(id) ON DELETE CASCADE,
    part_id UUID NOT NULL REFERENCES public.spare_parts(id) ON DELETE RESTRICT,
    quantity_used NUMERIC(10, 2) NOT NULL,
    cost_at_time NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.maintenance_parts ENABLE ROW LEVEL SECURITY;


-- TABLE: order_import_batches
CREATE TABLE IF NOT EXISTS public.order_import_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    month_year TEXT NOT NULL CHECK (month_year ~ '^\d{4}-\d{2}$'),
    source_type TEXT NOT NULL DEFAULT 'manual'
    CHECK (source_type IN ('manual', 'excel', 'api')),
    file_name TEXT,
    target_app_id UUID REFERENCES public.apps(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT _const_installment_pending()
    CHECK (status IN (_const_installment_pending(), 'completed', 'failed')),
    total_rows INTEGER NOT NULL DEFAULT 0 CHECK (total_rows >= 0),
    imported_rows INTEGER NOT NULL DEFAULT 0 CHECK (imported_rows >= 0),
    skipped_rows INTEGER NOT NULL DEFAULT 0 CHECK (skipped_rows >= 0),
    error_count INTEGER NOT NULL DEFAULT 0 CHECK (error_count >= 0),
    error_summary JSONB NOT NULL DEFAULT '[]'::jsonb,
    meta JSONB NOT NULL DEFAULT '{}'::jsonb,
    started_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.order_import_batches ENABLE ROW LEVEL SECURITY;


-- TABLE: platform_accounts
CREATE TABLE IF NOT EXISTS public.platform_accounts (
    id                     UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    app_id                 UUID        NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    account_username       TEXT        NOT NULL,
    account_id_on_platform TEXT,
    iqama_number           TEXT,
    iqama_expiry_date      DATE,
    status                 TEXT        NOT NULL DEFAULT _const_employee_active()
                           CHECK (status IN (_const_employee_active(), 'inactive')),
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL
);
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;


-- TABLE: pl_records
CREATE TABLE IF NOT EXISTS public.pl_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    month_year TEXT NOT NULL UNIQUE,
    revenue_riders NUMERIC(10,2) NOT NULL DEFAULT 0,
    revenue_other NUMERIC(10,2) NOT NULL DEFAULT 0,
    cost_salaries NUMERIC(10,2) NOT NULL DEFAULT 0,
    cost_vehicles NUMERIC(10,2) NOT NULL DEFAULT 0,
    cost_deductions NUMERIC(10,2) NOT NULL DEFAULT 0,
    cost_other NUMERIC(10,2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    company_id uuid,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.pl_records ENABLE ROW LEVEL SECURITY;


-- TABLE: positions
CREATE TABLE IF NOT EXISTS public.positions (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    company_id uuid
);
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;


-- TABLE: pricing_rules
CREATE TABLE IF NOT EXISTS public.pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    min_orders INTEGER NOT NULL DEFAULT 0,
    max_orders INTEGER,
    rule_type TEXT NOT NULL DEFAULT 'per_order' -- NOSONAR
    CHECK (rule_type IN ('per_order',
    'fixed',
    _const_work_hybrid())),
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
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;


-- TABLE: profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp']) -- NOSONAR
ON CONFLICT (id) DO NOTHING;

-- FILE: 20260308075948_985c6682-cdd2-4600-b9e6-5cd61215cebd.sql
﻿
ALTER TABLE public.profiles
ALTER COLUMN is_active SET DEFAULT false;

-- FILE: 20260324140000_pricing_rules.sql
﻿-- Pricing rules for payroll calculation (db-driven)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.profiles
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'attendance_company_id_fkey'
      AND conrelid = 'public.attendance'::regclass
  ) THEN

-- TABLE: public
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.table_name);
    SELECT COUNT(*)
    INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = t.table_name;
    IF v_policy_count = 0 THEN
      EXECUTE format(
        '
      EXECUTE format(
        '
      EXECUTE format(
        '
      EXECUTE format(
        '
    END IF;
  END LOOP;
END
$$;

-- FILE: 20260325233000_fix_employees_rls_company_id_null.sql
﻿-- Fix employees RLS when jwt_company_id() is NULL.

-- TABLE: roles
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL UNIQUE CHECK (title IN ('admin', 'hr', 'accountant', 'viewer', 'operations')),
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_drafts
CREATE TABLE IF NOT EXISTS public.salary_drafts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    draft_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, month_year, employee_id)
);
ALTER TABLE public.salary_drafts ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_month_snapshots
CREATE TABLE IF NOT EXISTS public.salary_month_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    month_year TEXT NOT NULL UNIQUE CHECK (month_year ~ '^\d{4}-\d{2}$'),
    snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
    summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    captured_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_month_snapshots ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_records
CREATE TABLE IF NOT EXISTS public.salary_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL,
    base_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
    allowances NUMERIC(10,2) NOT NULL DEFAULT 0,
    attendance_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    advance_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    external_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    manual_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    manual_deduction_note TEXT,
    net_salary NUMERIC(10,2) NOT NULL DEFAULT 0,
    is_approved BOOLEAN NOT NULL DEFAULT false,
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(employee_id, month_year),
    payment_method text DEFAULT _const_payment_cash() NOT NULL,
    calc_source TEXT NOT NULL DEFAULT 'engine_v1',
    company_id uuid,
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    version INTEGER DEFAULT 1 NOT NULL,
    sheet_snapshot JSONB
);
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_schemes
CREATE TABLE IF NOT EXISTS public.salary_schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_en TEXT,
    target_orders INT,
    target_bonus NUMERIC(10,2),
    status public.scheme_status NOT NULL DEFAULT _const_employee_active(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheme_type TEXT NOT NULL DEFAULT 'order_based',
    monthly_amount NUMERIC DEFAULT NULL,
    company_id uuid
);
ALTER TABLE public.salary_schemes ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_scheme_tiers
CREATE TABLE IF NOT EXISTS public.salary_scheme_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
    tier_order INT NOT NULL DEFAULT 1,
    from_orders INT NOT NULL DEFAULT 0,
    to_orders INT,
    price_per_order NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    tier_type TEXT NOT NULL DEFAULT 'total_multiplier',
    incremental_threshold INTEGER DEFAULT NULL,
    incremental_price NUMERIC DEFAULT NULL,
    company_id uuid
);
ALTER TABLE public.salary_scheme_tiers ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_slip_templates
CREATE TABLE IF NOT EXISTS public.salary_slip_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    header_html TEXT,
    footer_html TEXT,
    selected_columns JSONB DEFAULT '[]'::jsonb,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.salary_slip_templates ENABLE ROW LEVEL SECURITY;


-- TABLE: salary_tiers
CREATE TABLE IF NOT EXISTS public.salary_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
    min_orders INTEGER NOT NULL DEFAULT 0,
    max_orders INTEGER,
    tier_type TEXT NOT NULL DEFAULT 'per_order' -- NOSONAR
    CHECK (tier_type IN ('per_order',
    'fixed',
    _const_work_hybrid())),
    rate_per_order NUMERIC(10,2),
    fixed_amount NUMERIC(10,2),
    extra_rate NUMERIC(10,2),
    priority INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT salary_tiers_range_chk CHECK (max_orders IS NULL OR max_orders >= min_orders),
    CONSTRAINT salary_tiers_payload_chk CHECK (
    (tier_type = 'per_order' AND rate_per_order IS NOT NULL) OR
    (tier_type = 'fixed' AND fixed_amount IS NOT NULL) OR
    (tier_type = _const_work_hybrid() AND fixed_amount IS NOT NULL AND extra_rate IS NOT NULL)
  )
);
ALTER TABLE public.salary_tiers ENABLE ROW LEVEL SECURITY;


-- TABLE: scheme_month_snapshots
CREATE TABLE IF NOT EXISTS public.scheme_month_snapshots (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    scheme_id uuid NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
    month_year text NOT NULL,
    snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE(scheme_id, month_year),
    company_id uuid
);
ALTER TABLE public.scheme_month_snapshots ENABLE ROW LEVEL SECURITY;


-- TABLE: spare_parts
CREATE TABLE IF NOT EXISTS public.spare_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ar TEXT NOT NULL,
    part_number TEXT,
    stock_quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    min_stock_alert NUMERIC(10, 2) DEFAULT 5,
    unit TEXT DEFAULT 'قطعة',
    unit_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,
    supplier TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;


-- TABLE: supervisor_employee_assignments
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
ALTER TABLE public.supervisor_employee_assignments ENABLE ROW LEVEL SECURITY;


-- TABLE: supervisor_targets
CREATE TABLE IF NOT EXISTS public.supervisor_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supervisor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL,
    target_orders NUMERIC(10, 0) NOT NULL DEFAULT 0,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT supervisor_targets_month_fmt_chk CHECK (month_year ~ '^\d{4}-\d{2}$'),
    CONSTRAINT supervisor_targets_target_non_negative_chk CHECK (target_orders >= 0),
    CONSTRAINT supervisor_targets_unique UNIQUE (supervisor_id, month_year)
);
ALTER TABLE public.supervisor_targets ENABLE ROW LEVEL SECURITY;


-- TABLE: system_settings
CREATE TABLE IF NOT EXISTS public.system_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name_ar text NOT NULL DEFAULT 'نظام التوصيل',
    project_name_en text NOT NULL DEFAULT 'Delivery System',
    project_subtitle_ar text NOT NULL DEFAULT 'إدارة المناديب',
    project_subtitle_en text NOT NULL DEFAULT 'Rider Management',
    logo_url text,
    default_language text NOT NULL DEFAULT 'ar',
    theme text NOT NULL DEFAULT 'light',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    iqama_alert_days INTEGER NOT NULL DEFAULT 90,
    company_id uuid
);
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;


-- TABLE: trade_registers
CREATE TABLE IF NOT EXISTS public.trade_registers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_en TEXT,
    cr_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.trade_registers ENABLE ROW LEVEL SECURITY;


-- TABLE: user_permissions
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    permission_key TEXT NOT NULL,
    can_view BOOLEAN NOT NULL DEFAULT false,
    can_edit BOOLEAN NOT NULL DEFAULT false,
    can_delete BOOLEAN NOT NULL DEFAULT false,
    UNIQUE(user_id, permission_key),
    company_id uuid
);
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;


-- TABLE: user_roles
ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS role_id UUID;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_roles_role_id_fkey'
      AND conrelid = 'public.user_roles'::regclass
  ) THEN
    ALTER TABLE public.user_roles
      ADD CONSTRAINT user_roles_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;
  END IF;
END $$;
UPDATE public.user_roles ur
SET role_id = r.id
FROM public.roles r
WHERE ur.role_id IS NULL
  AND lower(r.title) = lower(ur.role::text);
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_roles_user_role_id
  ON public.user_roles(user_id, role_id)
  WHERE role_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id
  ON public.user_roles(role_id);

-- FILE: 20260325001000_attendance_checkin_checkout_metrics.sql
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.user_roles ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_permissions_company_id_fkey') THEN
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- TABLE: vehicles
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate_number TEXT UNIQUE NOT NULL,
    type public.vehicle_type NOT NULL DEFAULT 'motorcycle',
    brand TEXT,
    model TEXT,
    year INT,
    insurance_expiry DATE,
    registration_expiry DATE,
    status public.vehicle_status NOT NULL DEFAULT _const_employee_active(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    authorization_expiry date,
    plate_number_en TEXT,
    chassis_number TEXT,
    serial_number TEXT,
    has_fuel_chip boolean NOT NULL DEFAULT false,
    company_id uuid
);
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;


-- TABLE: vehicle_assignments
CREATE TABLE IF NOT EXISTS public.vehicle_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    reason TEXT,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    returned_at timestamp with time zone,
    start_at timestamp with time zone,
    company_id uuid
);
ALTER TABLE public.vehicle_assignments ENABLE ROW LEVEL SECURITY;


-- TABLE: vehicle_mileage
CREATE TABLE IF NOT EXISTS public.vehicle_mileage (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    month_year text NOT NULL,
    km_total numeric NOT NULL DEFAULT 0,
    fuel_cost numeric NOT NULL DEFAULT 0,
    cost_per_km numeric GENERATED ALWAYS AS (
    CASE WHEN km_total > 0 THEN fuel_cost / km_total ELSE NULL END
  ) STORED,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(employee_id, month_year),
    company_id uuid
);
ALTER TABLE public.vehicle_mileage ENABLE ROW LEVEL SECURITY;


-- TABLE: vehicle_mileage_daily
CREATE TABLE IF NOT EXISTS public.vehicle_mileage_daily (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
    date date NOT NULL,
    km_total numeric NOT NULL DEFAULT 0,
    fuel_cost numeric NOT NULL DEFAULT 0,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(employee_id, date),
    company_id uuid
);
ALTER TABLE public.vehicle_mileage_daily ENABLE ROW LEVEL SECURITY;

