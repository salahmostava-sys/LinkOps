-- FILE: 20240330000000_monthly_app_archives.sql
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
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
CREATE TABLE IF NOT EXISTS public.user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission_key TEXT NOT NULL,
  can_view BOOLEAN NOT NULL DEFAULT false,
  can_edit BOOLEAN NOT NULL DEFAULT false,
  can_delete BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(user_id, permission_key)
);
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.trade_registers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  cr_number TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.trade_registers ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  logo_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.salary_schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  target_orders INT,
  target_bonus NUMERIC(10,2),
  status public.scheme_status NOT NULL DEFAULT _const_employee_active(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_schemes ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.salary_scheme_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
  tier_order INT NOT NULL DEFAULT 1,
  from_orders INT NOT NULL DEFAULT 0,
  to_orders INT,
  price_per_order NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.salary_scheme_tiers ENABLE ROW LEVEL SECURITY;
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
  trade_register_id UUID REFERENCES public.trade_registers(id),
  status public.employee_status NOT NULL DEFAULT _const_employee_active(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.employee_scheme (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  scheme_id UUID NOT NULL REFERENCES public.salary_schemes(id),
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  assigned_by UUID REFERENCES auth.users(id)
);
ALTER TABLE public.employee_scheme ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.employee_apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES public.apps(id),
  username TEXT,
  status TEXT NOT NULL DEFAULT _const_employee_active(),
  joined_date DATE,
  UNIQUE(employee_id, app_id)
);
ALTER TABLE public.employee_apps ENABLE ROW LEVEL SECURITY;
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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.vehicle_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  reason TEXT,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.vehicle_assignments ENABLE ROW LEVEL SECURITY;
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;
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
CREATE TABLE IF NOT EXISTS public.daily_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  app_id UUID NOT NULL REFERENCES public.apps(id),
  orders_count INT NOT NULL DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date, app_id)
);
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.advance_installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advance_id UUID NOT NULL REFERENCES public.advances(id) ON DELETE CASCADE,
  month_year TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  status public.installment_status NOT NULL DEFAULT _const_installment_pending(),
  deducted_at TIMESTAMPTZ
);
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
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
  UNIQUE(employee_id, month_year)
);
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.pl_records ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  entity_id UUID,
  entity_type TEXT,
  due_date DATE,
  is_resolved BOOLEAN NOT NULL DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
;
INSERT INTO public.apps (name, name_en, is_active) VALUES
  ('هنقر', 'Hunger Station', true),
  ('كيتا', 'Keeta', true),
  ('طبو', 'Tobo', true),
  ('جاهز', 'Jahiz', true),
  ('نينجا', 'Ninja', true);

-- FILE: 20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql
﻿
CREATE TYPE public.city_enum AS ENUM ('makkah', 'jeddah');
CREATE TYPE public.license_status_enum AS ENUM ('has_license', 'no_license', 'applied');
CREATE TYPE public.sponsorship_status_enum AS ENUM ('sponsored', 'not_sponsored', 'absconded', 'terminated');
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS job_title text,
  ADD COLUMN IF NOT EXISTS bank_account_number text,
  ADD COLUMN IF NOT EXISTS city public.city_enum,
  ADD COLUMN IF NOT EXISTS join_date date,
  ADD COLUMN IF NOT EXISTS license_status public.license_status_enum DEFAULT 'no_license',
  ADD COLUMN IF NOT EXISTS sponsorship_status public.sponsorship_status_enum DEFAULT 'not_sponsored',
  ADD COLUMN IF NOT EXISTS id_photo_url text,
  ADD COLUMN IF NOT EXISTS license_photo_url text,
  ADD COLUMN IF NOT EXISTS personal_photo_url text;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'employee-documents', -- NOSONAR
  'employee-documents',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- FILE: 20260308070643_7e8e693c-d0d3-4d54-bb98-f628d77acadb.sql
﻿
CREATE TABLE IF NOT EXISTS public.scheme_month_snapshots (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  scheme_id uuid NOT NULL REFERENCES public.salary_schemes(id) ON DELETE CASCADE,
  month_year text NOT NULL,
  snapshot jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(scheme_id, month_year)
);
ALTER TABLE public.scheme_month_snapshots ENABLE ROW LEVEL SECURITY;

-- FILE: 20260308071338_da5633c6-2d3d-45dc-b7c1-1d1bc9be8bd6.sql
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'breakdown';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'rental';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'ended';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS authorization_expiry date;
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS returned_at timestamp with time zone;
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS start_at timestamp with time zone;

-- FILE: 20260308074600_505a58f7-de3a-4e55-9d20-96bced1928fb.sql
﻿-- Create vehicle_mileage table
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
  UNIQUE(employee_id, month_year)
);
ALTER TABLE public.vehicle_mileage ENABLE ROW LEVEL SECURITY;

-- FILE: 20260308074955_1cb7258b-936c-4f15-a48f-8bbda5531813.sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp']) -- NOSONAR
ON CONFLICT (id) DO NOTHING;

-- FILE: 20260308075948_985c6682-cdd2-4600-b9e6-5cd61215cebd.sql
﻿
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
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS system_settings_singleton ON public.system_settings ((true));
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
INSERT INTO public.system_settings (project_name_ar, project_name_en, project_subtitle_ar, project_subtitle_en)
VALUES ('نظام التوصيل', 'Delivery System', 'إدارة المناديب', 'Rider Management')
ON CONFLICT DO NOTHING;

-- FILE: 20260308084923_1221af4a-eb12-4835-96fb-9562bcc2249c.sql
ALTER TABLE public.apps 
  ADD COLUMN IF NOT EXISTS brand_color TEXT NOT NULL DEFAULT '#6366f1',
  ADD COLUMN IF NOT EXISTS text_color TEXT NOT NULL DEFAULT '#ffffff';

-- FILE: 20260308111611_3a71d7dd-4a79-494c-aa33-73b5f4dbd9fd.sql
ALTER TABLE public.salary_records ADD COLUMN IF NOT EXISTS payment_method text DEFAULT _const_payment_cash() NOT NULL;

-- FILE: 20260308121145_756f2a5b-e50d-4dee-b1fc-7f631d941b1b.sql
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS scheme_id UUID REFERENCES public.salary_schemes(id) ON DELETE SET NULL;

-- FILE: 20260308125350_32da242e-1c8b-4247-8e75-8057d5e57a62.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS preferred_language text NOT NULL DEFAULT 'ar' CHECK (preferred_language IN ('ar', 'en', 'ur'));

-- FILE: 20260308160244_08e17ad0-0a55-4ec5-b5f2-a2dc4ea0e6b0.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS nationality text;

-- FILE: 20260308160641_33fe96e5-0f81-4488-8186-8436064285db.sql
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS employee_code text,
  ADD COLUMN IF NOT EXISTS birth_date date;
CREATE UNIQUE INDEX IF NOT EXISTS employees_employee_code_unique
  ON public.employees (employee_code)
  WHERE employee_code IS NOT NULL;

-- FILE: 20260309003853_b312456a-78bf-413c-be9d-7ebb91748221.sql
﻿

-- FILE: 20260309003904_4ac0abf0-9134-4156-9456-1e4dd05dc643.sql
UPDATE storage.buckets SET public = FALSE WHERE id = 'employee-documents'; -- NOSONAR

-- FILE: 20260309004512_08955870-3030-4d1b-841a-781651a23ca5.sql
CREATE TABLE IF NOT EXISTS public.departments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  name_en TEXT,
  description TEXT,
  manager_id UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.positions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  name_en TEXT,
  department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES public.positions(id) ON DELETE SET NULL;

-- FILE: 20260318000852_1d17194a-ce8c-4d75-840d-0226be68a413.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS probation_end_date date NULL;

-- FILE: 20260318003456_618c1cf7-60bf-4c42-8470-74109a9f6d45.sql
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS custom_columns JSONB DEFAULT '[]'::jsonb;

-- FILE: 20260318010209_91b4f4a3-6035-43db-aa04-230b6ecf97b6.sql
﻿
CREATE TABLE IF NOT EXISTS public.employee_tiers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  package_type TEXT NOT NULL DEFAULT 'شريحة أساسية',
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  renewal_date DATE NOT NULL,
  delivery_status TEXT NOT NULL DEFAULT _const_installment_pending(),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.employee_tiers ENABLE ROW LEVEL SECURITY;

-- FILE: 20260318011345_3b8ae88e-c0ac-444f-af22-613b145dc0d4.sql
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS notes text;

-- FILE: 20260318013628_09bf19b4-b17d-4b43-bb94-d55ee18d5628.sql
﻿
CREATE TABLE IF NOT EXISTS public.app_targets (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  app_id uuid NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  month_year text NOT NULL,
  target_orders integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE (app_id, month_year)
);
ALTER TABLE public.app_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances 
  ADD COLUMN IF NOT EXISTS is_written_off boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS written_off_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS written_off_reason text;

-- FILE: 20260318015512_c1513ec8-bda1-4b98-b671-dbf9ae05ce75.sql
ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS plate_number_en TEXT,
  ADD COLUMN IF NOT EXISTS chassis_number TEXT,
  ADD COLUMN IF NOT EXISTS serial_number TEXT;

-- FILE: 20260318022147_16beb355-291d-4c12-8d89-b3e1f31c9338.sql
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS has_fuel_chip boolean NOT NULL DEFAULT false;

-- FILE: 20260318074211_ce2d15d2-a550-4026-889a-c46208c3b4d1.sql
ALTER TABLE public.salary_schemes
  ADD COLUMN IF NOT EXISTS scheme_type TEXT NOT NULL DEFAULT 'order_based',
  ADD COLUMN IF NOT EXISTS monthly_amount NUMERIC DEFAULT NULL;
ALTER TABLE public.salary_schemes
  ADD CONSTRAINT salary_schemes_scheme_type_check
    CHECK (scheme_type IN ('order_based', 'fixed_monthly'));
ALTER TABLE public.salary_scheme_tiers
  ADD COLUMN IF NOT EXISTS tier_type TEXT NOT NULL DEFAULT 'total_multiplier',
  ADD COLUMN IF NOT EXISTS incremental_threshold INTEGER DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS incremental_price NUMERIC DEFAULT NULL;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
    CHECK (tier_type IN ('total_multiplier', _const_tier_fixed(), _const_tier_incremental()));

-- FILE: 20260318090223_4fe00ba3-9c12-481b-8ba1-2683f82edffa.sql
ALTER TABLE public.employee_tiers
  ADD COLUMN IF NOT EXISTS sim_number text,
  ADD COLUMN IF NOT EXISTS app_ids jsonb NOT NULL DEFAULT '[]'::jsonb;

-- FILE: 20260318091031_ea72075a-49eb-4399-bdcb-7f2bb16bc19a.sql
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS health_insurance_expiry date;

-- FILE: 20260320000001_vehicle_mileage_daily.sql
﻿
CREATE TABLE IF NOT EXISTS public.vehicle_mileage_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date date NOT NULL,
  km_total numeric NOT NULL DEFAULT 0,
  fuel_cost numeric NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);
ALTER TABLE public.vehicle_mileage_daily ENABLE ROW LEVEL SECURITY;

-- FILE: 20260320000002_rls_comprehensive_fix.sql
﻿

-- FILE: 20260320000003_profiles_realtime.sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;
END
$$;

-- FILE: 20260320000004_activate_salah_user.sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
UPDATE auth.users
SET
  encrypted_password = extensions.crypt('sala7372495', extensions.gen_salt('bf')),
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  updated_at          = now()
WHERE email = 'salahmostava@gmail.com'; -- NOSONAR
INSERT INTO public.profiles (id, email, name, is_active)
SELECT id, email, 'Salah', true
FROM auth.users
WHERE email = 'salahmostava@gmail.com'
ON CONFLICT (id) DO UPDATE
  SET is_active = true,
      email     = EXCLUDED.email,
      updated_at = now();
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin'
FROM auth.users
WHERE email = 'salahmostava@gmail.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- FILE: 20260320100000_restrict_pii_rls.sql
﻿

-- FILE: 20260321000001_platform_accounts.sql
﻿-- ══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.system_settings
  ADD COLUMN IF NOT EXISTS iqama_alert_days INTEGER NOT NULL DEFAULT 90;
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
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.account_assignments (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id  UUID        NOT NULL REFERENCES public.platform_accounts(id) ON DELETE CASCADE,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date  DATE        NOT NULL,
  end_date    DATE,
  month_year  TEXT        NOT NULL,   -- YYYY-MM
  notes       TEXT,
  created_by  UUID        REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;

-- FILE: 20260323150000_locked_months.sql
﻿CREATE TABLE IF NOT EXISTS public.locked_months (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  month_year TEXT NOT NULL UNIQUE,
  locked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_by UUID REFERENCES auth.users(id)
);
ALTER TABLE public.locked_months ENABLE ROW LEVEL SECURITY;

-- FILE: 20260323170000_platform_accounts_employee_id_and_alerts_trigger.sql
ALTER TABLE public.platform_accounts
  ADD COLUMN IF NOT EXISTS employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL;
ALTER TABLE public.alerts
  ADD COLUMN IF NOT EXISTS message TEXT,
  ADD COLUMN IF NOT EXISTS details JSONB;
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  trade_cr TEXT;
  msg TEXT;
  accounts_json JSONB;
  vehicles_json JSONB;
  trade_json JSONB;
BEGIN
  status := NEW.sponsorship_status::TEXT;
  IF (NEW.sponsorship_status IS DISTINCT FROM OLD.sponsorship_status)
     AND (status IN ('absconded', 'terminated')) THEN
    IF status = 'terminated' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.platform_accounts WHERE employee_id = NEW.id
      ) THEN
        RETURN NEW;
      END IF;
    END IF;
    SELECT
      STRING_AGG(format('%s: %s', a.name, pa.account_username), ', ' ORDER BY a.name),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'app', a.name,
          'username', pa.account_username,
          'account_id_on_platform', pa.account_id_on_platform,
          'iqama_number', pa.iqama_number
        )
      ), '[]'::jsonb)
    INTO account_list, accounts_json
    FROM public.platform_accounts pa
    JOIN public.apps a ON a.id = pa.app_id
    WHERE pa.employee_id = NEW.id;
    SELECT
      COUNT(*)::int,
      STRING_AGG(v.plate_number, ', ' ORDER BY v.plate_number),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT('vehicle_id', v.id, 'plate_number', v.plate_number)
      ), '[]'::jsonb)
    INTO vehicle_count, vehicle_plate_list, vehicles_json
    FROM public.vehicle_assignments va
    JOIN public.vehicles v ON v.id = va.vehicle_id
    WHERE va.employee_id = NEW.id
      AND va.end_date IS NULL
      AND va.returned_at IS NULL;
    SELECT
      tr.name,
      tr.cr_number,
      COALESCE(JSONB_BUILD_OBJECT(
        'trade_register_id', tr.id,
        'name', tr.name,
        'cr_number', tr.cr_number,
        'notes', tr.notes
      ), '{}'::jsonb)
    INTO trade_name, trade_cr, trade_json
    FROM public.trade_registers tr
    WHERE tr.id = NEW.trade_register_id;
    msg :=
      format(
        'الموظف: %s (الهوية: %s) | منصات: %s | مركبات: %s | سجل تجاري: %s',
        COALESCE(NEW.name, '—'),
        COALESCE(NEW.national_id, '—'),
        COALESCE(account_list, '—'),
        COALESCE(vehicle_plate_list, CASE WHEN vehicle_count IS NULL THEN '—' ELSE vehicle_count::TEXT || ' مركبة' END),
        COALESCE(trade_name, '—')
      );
    INSERT INTO public.alerts (
      type,
      entity_id,
      entity_type,
      due_date,
      message,
      details
    )
    VALUES (
      CASE WHEN status = 'absconded' THEN 'employee_absconded' ELSE 'employee_terminated' END,
      NEW.id,
      'employee',
      CURRENT_DATE,
      msg,
      JSONB_BUILD_OBJECT(
        'employee_id', NEW.id,
        'employee_name', NEW.name,
        'national_id', NEW.national_id,
        'sponsorship_status', status,
        'platform_accounts', accounts_json,
        'vehicle_count', COALESCE(vehicle_count, 0),
        'vehicle_plates', COALESCE(vehicle_plate_list, ''),
        'vehicles', vehicles_json,
        'trade_register', trade_json,
        'trade_cr_number', trade_cr
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FILE: 20260324002310_e120f636-1ae5-460a-8e63-d591737abd62.sql
CREATE TABLE IF NOT EXISTS public.platform_accounts (
  id                      UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  app_id                  UUID        NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  employee_id             UUID        REFERENCES public.employees(id) ON DELETE SET NULL,
  account_username        TEXT        NOT NULL,
  account_id_on_platform  TEXT,
  iqama_number            TEXT,
  iqama_expiry_date       DATE,
  status                  TEXT        NOT NULL DEFAULT _const_employee_active() CHECK (status IN (_const_employee_active(), 'inactive')),
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.account_assignments (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id  UUID        NOT NULL REFERENCES public.platform_accounts(id) ON DELETE CASCADE,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  start_date  DATE        NOT NULL DEFAULT CURRENT_DATE,
  end_date    DATE,
  month_year  TEXT        NOT NULL,
  notes       TEXT,
  created_by  UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_account_assignments_account_id ON public.account_assignments(account_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_employee_id ON public.account_assignments(employee_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_open ON public.account_assignments(end_date) WHERE end_date IS NULL;
CREATE TABLE IF NOT EXISTS public.vehicle_mileage_daily (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date        DATE        NOT NULL,
  km_total    NUMERIC     NOT NULL DEFAULT 0,
  fuel_cost   NUMERIC     NOT NULL DEFAULT 0,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT vehicle_mileage_daily_employee_date_unique UNIQUE (employee_id, date)
);
ALTER TABLE public.vehicle_mileage_daily ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_vehicle_mileage_daily_employee_date
  ON public.vehicle_mileage_daily(employee_id, date);
CREATE TABLE IF NOT EXISTS public.locked_months (
  id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  month_year  TEXT        NOT NULL UNIQUE,
  locked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_by   UUID        REFERENCES public.profiles(id) ON DELETE SET NULL
);
ALTER TABLE public.locked_months ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324120000_dashboard_alerts_realtime_publication.sql
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'employees',
    'attendance',
    'daily_orders',
    'audit_log',
    'vehicles',
    'alerts',
    'apps',
    'app_targets',
    'platform_accounts'
  ];
BEGIN
  FOREACH t IN ARRAY tables
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END
$$;

-- FILE: 20260324120001_vehicle_mileage_daily_rls_finance.sql
﻿-- Allow finance (and HR) to read/write daily fuel/km entries alongside ops/admin

-- FILE: 20260324123500_signup_pii_rls_fix.sql
ALTER TABLE public.profiles
ALTER COLUMN is_active SET DEFAULT false;

-- FILE: 20260324140000_pricing_rules.sql
﻿-- Pricing rules for payroll calculation (db-driven)
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
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324180000_add_iqama_alert_days_to_system_settings.sql
ALTER TABLE public.system_settings
  ADD COLUMN IF NOT EXISTS iqama_alert_days INTEGER NOT NULL DEFAULT 90;
UPDATE public.system_settings
SET iqama_alert_days = 90
WHERE iqama_alert_days IS NULL;

-- FILE: 20260324193000_erd_foundation_roles_salary_structure.sql
﻿-- Phase 1 ERD foundation (non-breaking):
CREATE TABLE IF NOT EXISTS public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL UNIQUE CHECK (title IN ('admin', 'hr', 'accountant', 'viewer', 'operations')),
  permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO public.roles (title, permissions)
VALUES
  ('admin', '{"*": {"view": true, "edit": true, "delete": true}}'::jsonb),
  ('hr', '{"employees": {"view": true, "edit": true}, "attendance": {"view": true, "edit": true}}'::jsonb),
  ('accountant', '{"salary": {"view": true, "edit": true}, "orders": {"view": true}}'::jsonb),
  ('viewer', '{"*": {"view": true, "edit": false, "delete": false}}'::jsonb),
  ('operations', '{"orders": {"view": true, "edit": true}, "platform_accounts": {"view": true, "edit": true}}'::jsonb)
ON CONFLICT (title) DO NOTHING;
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
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_employees_role_id ON public.employees(role_id);
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'confirmed'
  CHECK (status IN ('draft', 'confirmed', _const_order_cancelled()));
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual';
CREATE INDEX IF NOT EXISTS idx_daily_orders_employee_date ON public.daily_orders(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_orders_app_date ON public.daily_orders(app_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_orders_status ON public.daily_orders(status);
COMMENT ON TABLE public.daily_orders IS 'Orders fact table (platform/app level). platform_id is represented by app_id.';
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'attendance_check_out_after_check_in_chk'
      AND conrelid = 'public.attendance'::regclass
  ) THEN
    ALTER TABLE public.attendance
      ADD CONSTRAINT attendance_check_out_after_check_in_chk
      CHECK (check_out IS NULL OR check_in IS NULL OR check_out >= check_in);
  END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS uq_attendance_employee_date
  ON public.attendance(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_status_date
  ON public.attendance(employee_id, status, date);
CREATE TABLE IF NOT EXISTS public.salary_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID NOT NULL REFERENCES public.apps(id) ON DELETE CASCADE,
  min_orders INTEGER NOT NULL DEFAULT 0,
  max_orders INTEGER,
  tier_type TEXT NOT NULL DEFAULT 'per_order' -- NOSONAR
    CHECK (tier_type IN ('per_order', 'fixed', _const_work_hybrid())),
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
CREATE INDEX IF NOT EXISTS idx_salary_tiers_app_priority
  ON public.salary_tiers(app_id, is_active, priority DESC);
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS calc_status TEXT NOT NULL DEFAULT _const_calc_calculated()
  CHECK (calc_status IN (_const_calc_calculated(), _const_approval_approved(), 'paid', _const_order_cancelled()));
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS calc_source TEXT NOT NULL DEFAULT 'engine_v1';
CREATE INDEX IF NOT EXISTS idx_salary_records_employee_month
  ON public.salary_records(employee_id, month_year);
CREATE INDEX IF NOT EXISTS idx_salary_records_calc_status
  ON public.salary_records(calc_status);
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_tiers ENABLE ROW LEVEL SECURITY;

-- FILE: 20260324213000_seed_roles_permissions_matrix.sql
UPDATE public.roles
SET permissions = jsonb_build_object(
  '*',
  jsonb_build_object('view', true, 'write', true, 'delete', true, 'approve', true), -- NOSONAR
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', true)
)
WHERE title = 'admin';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title = 'hr';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title IN ('finance', 'accountant');
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'operations';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'viewer';

-- FILE: 20260324220000_roles_upsert_and_permissions_bootstrap.sql
ALTER TABLE public.roles
  DROP CONSTRAINT IF EXISTS roles_title_check;
ALTER TABLE public.roles
  ADD CONSTRAINT roles_title_check
  CHECK (
    title = ANY (
      ARRAY[
        'admin'::text,
        'hr'::text,
        'finance'::text,
        'accountant'::text,
        'operations'::text,
        'viewer'::text
      ]
    )
  );
INSERT INTO public.roles (title, permissions, is_active)
VALUES
  ('admin', '{}'::jsonb, true),
  ('hr', '{}'::jsonb, true),
  ('finance', '{}'::jsonb, true),
  ('accountant', '{}'::jsonb, true),
  ('operations', '{}'::jsonb, true),
  ('viewer', '{}'::jsonb, true)
ON CONFLICT (title) DO UPDATE
SET is_active = EXCLUDED.is_active;
UPDATE public.roles
SET permissions = jsonb_build_object(
  '*',
  jsonb_build_object('view', true, 'write', true, 'delete', true, 'approve', true),
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', true),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', true)
)
WHERE title = 'admin';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title = 'hr';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', true, 'approve', true),
  'roles',
  jsonb_build_object('view', true, 'write', false)
)
WHERE title IN ('finance', 'accountant');
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', true, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', true),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'operations';
UPDATE public.roles
SET permissions = jsonb_build_object(
  'employees',
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  _const_work_orders(),
  jsonb_build_object('view', true, 'write', false, 'delete', false),
  'attendance',
  jsonb_build_object('view', true, 'write', false),
  'salary',
  jsonb_build_object('view', true, 'write', false, 'approve', false),
  'roles',
  jsonb_build_object('view', false, 'write', false)
)
WHERE title = 'viewer';

-- FILE: 20260324230000_seed_default_pricing_rules_for_active_apps.sql
INSERT INTO public.pricing_rules (
  app_id,
  min_orders,
  max_orders,
  rule_type,
  rate_per_order,
  fixed_salary,
  bonus_target_orders,
  bonus_amount,
  is_active,
  priority
)
SELECT
  a.id AS app_id,
  0 AS min_orders,
  NULL AS max_orders,
  'per_order'::text AS rule_type,
  0::numeric AS rate_per_order,
  NULL::numeric AS fixed_salary,
  NULL::integer AS bonus_target_orders,
  NULL::numeric AS bonus_amount,
  true AS is_active,
  -1000 AS priority
FROM public.apps a
WHERE a.is_active = true
  AND NOT EXISTS (
    SELECT 1
    FROM public.pricing_rules pr
    WHERE pr.app_id = a.id
  );

-- FILE: 20260324235500_user_roles_role_id_bridge.sql
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
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS total_hours NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS late BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS early_leave BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_late
  ON public.attendance (employee_id, date, late);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_early_leave
  ON public.attendance (employee_id, date, early_leave);

-- FILE: 20260325120000_external_deductions_linked_advance.sql
ALTER TABLE public.external_deductions
  ADD COLUMN IF NOT EXISTS linked_advance_id UUID REFERENCES public.advances(id) ON DELETE SET NULL;
COMMENT ON COLUMN public.external_deductions.linked_advance_id IS 'عند تحويل المخالفة لسلفة: معرّف السلفة المنشأة';
CREATE INDEX IF NOT EXISTS idx_external_deductions_linked_advance_id
  ON public.external_deductions(linked_advance_id)
  WHERE linked_advance_id IS NOT NULL;

-- FILE: 20260325120001_security_scan_signup_employees_rls.sql
﻿-- ============================================================

-- FILE: 20260325140000_rename_project_muhimmat_altawseel.sql
ALTER TABLE public.system_settings
  ALTER COLUMN project_name_ar SET DEFAULT 'مهمة التوصيل',
  ALTER COLUMN project_name_en SET DEFAULT 'Muhimmat alTawseel';
UPDATE public.system_settings
SET
  project_name_ar = 'مهمة التوصيل',
  project_name_en = 'Muhimmat alTawseel',
  updated_at = now();

-- FILE: 20260325153000_employees_tenant_rls_hardening.sql
﻿-- ============================================================================
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325154500_unify_company_id_on_employees.sql
﻿-- ============================================================================
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.employees
SET company_id = trade_register_id
WHERE company_id IS NULL
  AND trade_register_id IS NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'employees_company_id_fkey'
      AND conrelid = 'public.employees'::regclass
  ) THEN
    ALTER TABLE public.employees
      ADD CONSTRAINT employees_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_employees_company_id
  ON public.employees (company_id);
ALTER TABLE public.employees
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();

-- FILE: 20260325160000_drop_legacy_trade_register_id_on_employees.sql
UPDATE public.employees
SET company_id = trade_register_id
WHERE company_id IS NULL
  AND trade_register_id IS NOT NULL;
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  trade_cr TEXT;
  msg TEXT;
  accounts_json JSONB;
  vehicles_json JSONB;
  trade_json JSONB;
BEGIN
  status := NEW.sponsorship_status::TEXT;
  IF (NEW.sponsorship_status IS DISTINCT FROM OLD.sponsorship_status)
     AND (status IN ('absconded', 'terminated')) THEN
    IF status = 'terminated' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.platform_accounts WHERE employee_id = NEW.id
      ) THEN
        RETURN NEW;
      END IF;
    END IF;
    SELECT
      STRING_AGG(format('%s: %s', a.name, pa.account_username), ', ' ORDER BY a.name),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'app', a.name,
          'username', pa.account_username,
          'account_id_on_platform', pa.account_id_on_platform,
          'iqama_number', pa.iqama_number
        )
      ), '[]'::jsonb)
    INTO account_list, accounts_json
    FROM public.platform_accounts pa
    JOIN public.apps a ON a.id = pa.app_id
    WHERE pa.employee_id = NEW.id;
    SELECT
      COUNT(*)::int,
      STRING_AGG(v.plate_number, ', ' ORDER BY v.plate_number),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT('vehicle_id', v.id, 'plate_number', v.plate_number)
      ), '[]'::jsonb)
    INTO vehicle_count, vehicle_plate_list, vehicles_json
    FROM public.vehicle_assignments va
    JOIN public.vehicles v ON v.id = va.vehicle_id
    WHERE va.employee_id = NEW.id
      AND va.end_date IS NULL
      AND va.returned_at IS NULL;
    SELECT
      tr.name,
      tr.cr_number,
      COALESCE(JSONB_BUILD_OBJECT(
        'company_id', tr.id,
        'name', tr.name,
        'cr_number', tr.cr_number,
        'notes', tr.notes
      ), '{}'::jsonb)
    INTO trade_name, trade_cr, trade_json
    FROM public.trade_registers tr
    WHERE tr.id = NEW.company_id;
    msg :=
      format(
        'الموظف: %s (الهوية: %s) | منصات: %s | مركبات: %s | سجل تجاري: %s',
        COALESCE(NEW.name, '—'),
        COALESCE(NEW.national_id, '—'),
        COALESCE(account_list, '—'),
        COALESCE(vehicle_plate_list, CASE WHEN vehicle_count IS NULL THEN '—' ELSE vehicle_count::TEXT || ' مركبة' END),
        COALESCE(trade_name, '—')
      );
    INSERT INTO public.alerts (
      type,
      entity_id,
      entity_type,
      due_date,
      message,
      details
    )
    VALUES (
      CASE WHEN status = 'absconded' THEN 'employee_absconded' ELSE 'employee_terminated' END,
      NEW.id,
      'employee',
      CURRENT_DATE,
      msg,
      JSONB_BUILD_OBJECT(
        'employee_id', NEW.id,
        'employee_name', NEW.name,
        'national_id', NEW.national_id,
        'sponsorship_status', status,
        'platform_accounts', accounts_json,
        'vehicle_count', COALESCE(vehicle_count, 0),
        'vehicle_plates', COALESCE(vehicle_plate_list, ''),
        'vehicles', vehicles_json,
        'trade_register', trade_json,
        'trade_cr_number', trade_cr
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP FUNCTION IF EXISTS public.sync_employees_company_columns();
ALTER TABLE public.employees
  DROP CONSTRAINT IF EXISTS employees_trade_register_id_fkey;
ALTER TABLE public.employees
  DROP COLUMN IF EXISTS trade_register_id;

-- FILE: 20260325163000_tenant_rls_platform_accounts_and_employee_links.sql
﻿-- ============================================================================
ALTER TABLE public.platform_accounts
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.account_assignments
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.platform_accounts pa
SET company_id = e.company_id
FROM public.employees e
WHERE pa.employee_id = e.id
  AND pa.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.account_assignments aa
SET company_id = e.company_id
FROM public.employees e
WHERE aa.employee_id = e.id
  AND aa.company_id IS NULL
  AND e.company_id IS NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'platform_accounts_company_id_fkey'
      AND conrelid = 'public.platform_accounts'::regclass
  ) THEN
    ALTER TABLE public.platform_accounts
      ADD CONSTRAINT platform_accounts_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'account_assignments_company_id_fkey'
      AND conrelid = 'public.account_assignments'::regclass
  ) THEN
    ALTER TABLE public.account_assignments
      ADD CONSTRAINT account_assignments_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_platform_accounts_company_id
  ON public.platform_accounts (company_id);
CREATE INDEX IF NOT EXISTS idx_account_assignments_company_id
  ON public.account_assignments (company_id);
ALTER TABLE public.platform_accounts
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.account_assignments
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.employee_apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_scheme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_assignments ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325170000_tenant_rls_ops_finance_tables.sql
﻿-- ============================================================================
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE public.employees
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.platform_accounts
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.account_assignments
  ALTER COLUMN company_id SET NOT NULL;

-- FILE: 20260325174500_add_company_id_to_operational_tables.sql
﻿-- ============================================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.advances
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.advance_installments
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.external_deductions
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.attendance a
SET company_id = e.company_id
FROM public.employees e
WHERE a.employee_id = e.id
  AND a.company_id IS NULL;
UPDATE public.daily_orders d
SET company_id = e.company_id
FROM public.employees e
WHERE d.employee_id = e.id
  AND d.company_id IS NULL;
UPDATE public.advances a
SET company_id = e.company_id
FROM public.employees e
WHERE a.employee_id = e.id
  AND a.company_id IS NULL;
UPDATE public.external_deductions x
SET company_id = e.company_id
FROM public.employees e
WHERE x.employee_id = e.id
  AND x.company_id IS NULL;
UPDATE public.salary_records s
SET company_id = e.company_id
FROM public.employees e
WHERE s.employee_id = e.id
  AND s.company_id IS NULL;
UPDATE public.advance_installments ai
SET company_id = a.company_id
FROM public.advances a
WHERE ai.advance_id = a.id
  AND ai.company_id IS NULL;
ALTER TABLE public.profiles
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.attendance
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.daily_orders
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.advances
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.advance_installments
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.external_deductions
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.salary_records
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_company_id_fkey'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'attendance_company_id_fkey'
      AND conrelid = 'public.attendance'::regclass
  ) THEN
    ALTER TABLE public.attendance
      ADD CONSTRAINT attendance_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'daily_orders_company_id_fkey'
      AND conrelid = 'public.daily_orders'::regclass
  ) THEN
    ALTER TABLE public.daily_orders
      ADD CONSTRAINT daily_orders_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'advances_company_id_fkey'
      AND conrelid = 'public.advances'::regclass
  ) THEN
    ALTER TABLE public.advances
      ADD CONSTRAINT advances_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'advance_installments_company_id_fkey'
      AND conrelid = 'public.advance_installments'::regclass
  ) THEN
    ALTER TABLE public.advance_installments
      ADD CONSTRAINT advance_installments_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_deductions_company_id_fkey'
      AND conrelid = 'public.external_deductions'::regclass
  ) THEN
    ALTER TABLE public.external_deductions
      ADD CONSTRAINT external_deductions_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'salary_records_company_id_fkey'
      AND conrelid = 'public.salary_records'::regclass
  ) THEN
    ALTER TABLE public.salary_records
      ADD CONSTRAINT salary_records_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id);
CREATE INDEX IF NOT EXISTS idx_daily_orders_company_id ON public.daily_orders(company_id);
CREATE INDEX IF NOT EXISTS idx_advances_company_id ON public.advances(company_id);
CREATE INDEX IF NOT EXISTS idx_advance_installments_company_id ON public.advance_installments(company_id);
CREATE INDEX IF NOT EXISTS idx_external_deductions_company_id ON public.external_deductions(company_id);
CREATE INDEX IF NOT EXISTS idx_salary_records_company_id ON public.salary_records(company_id);
ALTER TABLE public.attendance
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.daily_orders
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.advances
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.advance_installments
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.external_deductions
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.salary_records
  ALTER COLUMN company_id SET NOT NULL;

-- FILE: 20260325181500_company_id_rollout_remaining_tables.sql
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.user_permissions ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.departments ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.positions ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.app_targets ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.salary_schemes ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.salary_scheme_tiers ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.scheme_month_snapshots ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_scheme ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_apps ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.employee_tiers ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_assignments ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.maintenance_logs ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_mileage ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.vehicle_mileage_daily ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.pl_records ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.alerts ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.locked_months ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.system_settings ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS company_id uuid;
UPDATE public.user_roles ur
SET company_id = p.company_id
FROM public.profiles p
WHERE ur.user_id = p.id
  AND ur.company_id IS NULL
  AND p.company_id IS NOT NULL;
UPDATE public.user_permissions up
SET company_id = p.company_id
FROM public.profiles p
WHERE up.user_id = p.id
  AND up.company_id IS NULL
  AND p.company_id IS NOT NULL;
UPDATE public.employee_scheme es
SET company_id = e.company_id
FROM public.employees e
WHERE es.employee_id = e.id
  AND es.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.employee_apps ea
SET company_id = e.company_id
FROM public.employees e
WHERE ea.employee_id = e.id
  AND ea.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.employee_tiers et
SET company_id = e.company_id
FROM public.employees e
WHERE et.employee_id = e.id
  AND et.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.vehicle_assignments va
SET company_id = e.company_id
FROM public.employees e
WHERE va.employee_id = e.id
  AND va.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.vehicle_mileage vm
SET company_id = e.company_id
FROM public.employees e
WHERE vm.employee_id = e.id
  AND vm.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.vehicle_mileage_daily vmd
SET company_id = e.company_id
FROM public.employees e
WHERE vmd.employee_id = e.id
  AND vmd.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.vehicles v
SET company_id = va.company_id
FROM public.vehicle_assignments va
WHERE va.vehicle_id = v.id
  AND v.company_id IS NULL
  AND va.company_id IS NOT NULL;
UPDATE public.maintenance_logs ml
SET company_id = v.company_id
FROM public.vehicles v
WHERE ml.vehicle_id = v.id
  AND ml.company_id IS NULL
  AND v.company_id IS NOT NULL;
UPDATE public.departments d
SET company_id = e.company_id
FROM public.employees e
WHERE e.department_id = d.id
  AND d.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.positions p
SET company_id = e.company_id
FROM public.employees e
WHERE e.position_id = p.id
  AND p.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.salary_schemes ss
SET company_id = es.company_id
FROM public.employee_scheme es
WHERE es.scheme_id = ss.id
  AND ss.company_id IS NULL
  AND es.company_id IS NOT NULL;
UPDATE public.salary_scheme_tiers sst
SET company_id = ss.company_id
FROM public.salary_schemes ss
WHERE sst.scheme_id = ss.id
  AND sst.company_id IS NULL
  AND ss.company_id IS NOT NULL;
UPDATE public.scheme_month_snapshots sms
SET company_id = ss.company_id
FROM public.salary_schemes ss
WHERE sms.scheme_id = ss.id
  AND sms.company_id IS NULL
  AND ss.company_id IS NOT NULL;
UPDATE public.app_targets at
SET company_id = d.company_id
FROM (
  SELECT dorders.app_id, e.company_id
  FROM public.daily_orders dorders
  JOIN public.employees e ON e.id = dorders.employee_id
  GROUP BY dorders.app_id, e.company_id
) AS d
WHERE at.app_id = d.app_id
  AND at.company_id IS NULL
  AND d.company_id IS NOT NULL;
UPDATE public.apps a
SET company_id = pa.company_id
FROM public.platform_accounts pa
WHERE pa.app_id = a.id
  AND a.company_id IS NULL
  AND pa.company_id IS NOT NULL;
UPDATE public.pl_records pl
SET company_id = s.company_id
FROM public.salary_records s
WHERE s.month_year = pl.month_year
  AND pl.company_id IS NULL
  AND s.company_id IS NOT NULL;
UPDATE public.alerts al
SET company_id = e.company_id
FROM public.employees e
WHERE al.entity_type = 'employee'
  AND al.entity_id = e.id
  AND al.company_id IS NULL
  AND e.company_id IS NOT NULL;
UPDATE public.alerts al
SET company_id = p.company_id
FROM public.profiles p
WHERE al.company_id IS NULL
  AND al.resolved_by = p.id
  AND p.company_id IS NOT NULL;
UPDATE public.locked_months lm
SET company_id = p.company_id
FROM public.profiles p
WHERE lm.locked_by = p.id
  AND lm.company_id IS NULL
  AND p.company_id IS NOT NULL;
UPDATE public.audit_log al
SET company_id = p.company_id
FROM public.profiles p
WHERE al.user_id = p.id
  AND al.company_id IS NULL
  AND p.company_id IS NOT NULL;
ALTER TABLE public.user_roles ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.user_permissions ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.departments ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.positions ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.apps ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.app_targets ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.salary_schemes ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.salary_scheme_tiers ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.scheme_month_snapshots ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.employee_scheme ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.employee_apps ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.employee_tiers ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.vehicles ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.vehicle_assignments ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.maintenance_logs ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.vehicle_mileage ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.vehicle_mileage_daily ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.pl_records ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.alerts ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.locked_months ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.system_settings ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
ALTER TABLE public.audit_log ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_roles_company_id_fkey') THEN
    ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_permissions_company_id_fkey') THEN
    ALTER TABLE public.user_permissions ADD CONSTRAINT user_permissions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'departments_company_id_fkey') THEN
    ALTER TABLE public.departments ADD CONSTRAINT departments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'positions_company_id_fkey') THEN
    ALTER TABLE public.positions ADD CONSTRAINT positions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'apps_company_id_fkey') THEN
    ALTER TABLE public.apps ADD CONSTRAINT apps_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'app_targets_company_id_fkey') THEN
    ALTER TABLE public.app_targets ADD CONSTRAINT app_targets_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'salary_schemes_company_id_fkey') THEN
    ALTER TABLE public.salary_schemes ADD CONSTRAINT salary_schemes_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'salary_scheme_tiers_company_id_fkey') THEN
    ALTER TABLE public.salary_scheme_tiers ADD CONSTRAINT salary_scheme_tiers_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'scheme_month_snapshots_company_id_fkey') THEN
    ALTER TABLE public.scheme_month_snapshots ADD CONSTRAINT scheme_month_snapshots_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_scheme_company_id_fkey') THEN
    ALTER TABLE public.employee_scheme ADD CONSTRAINT employee_scheme_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_apps_company_id_fkey') THEN
    ALTER TABLE public.employee_apps ADD CONSTRAINT employee_apps_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employee_tiers_company_id_fkey') THEN
    ALTER TABLE public.employee_tiers ADD CONSTRAINT employee_tiers_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_company_id_fkey') THEN
    ALTER TABLE public.vehicles ADD CONSTRAINT vehicles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_assignments_company_id_fkey') THEN
    ALTER TABLE public.vehicle_assignments ADD CONSTRAINT vehicle_assignments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'maintenance_logs_company_id_fkey') THEN
    ALTER TABLE public.maintenance_logs ADD CONSTRAINT maintenance_logs_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_mileage_company_id_fkey') THEN
    ALTER TABLE public.vehicle_mileage ADD CONSTRAINT vehicle_mileage_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_mileage_daily_company_id_fkey') THEN
    ALTER TABLE public.vehicle_mileage_daily ADD CONSTRAINT vehicle_mileage_daily_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pl_records_company_id_fkey') THEN
    ALTER TABLE public.pl_records ADD CONSTRAINT pl_records_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'alerts_company_id_fkey') THEN
    ALTER TABLE public.alerts ADD CONSTRAINT alerts_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'locked_months_company_id_fkey') THEN
    ALTER TABLE public.locked_months ADD CONSTRAINT locked_months_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'system_settings_company_id_fkey') THEN
    ALTER TABLE public.system_settings ADD CONSTRAINT system_settings_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_log_company_id_fkey') THEN
    ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_user_roles_company_id ON public.user_roles(company_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_company_id ON public.user_permissions(company_id);
CREATE INDEX IF NOT EXISTS idx_departments_company_id ON public.departments(company_id);
CREATE INDEX IF NOT EXISTS idx_positions_company_id ON public.positions(company_id);
CREATE INDEX IF NOT EXISTS idx_apps_company_id ON public.apps(company_id);
CREATE INDEX IF NOT EXISTS idx_app_targets_company_id ON public.app_targets(company_id);
CREATE INDEX IF NOT EXISTS idx_salary_schemes_company_id ON public.salary_schemes(company_id);
CREATE INDEX IF NOT EXISTS idx_salary_scheme_tiers_company_id ON public.salary_scheme_tiers(company_id);
CREATE INDEX IF NOT EXISTS idx_scheme_month_snapshots_company_id ON public.scheme_month_snapshots(company_id);
CREATE INDEX IF NOT EXISTS idx_employee_scheme_company_id ON public.employee_scheme(company_id);
CREATE INDEX IF NOT EXISTS idx_employee_apps_company_id ON public.employee_apps(company_id);
CREATE INDEX IF NOT EXISTS idx_employee_tiers_company_id ON public.employee_tiers(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_company_id ON public.vehicles(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_assignments_company_id ON public.vehicle_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_company_id ON public.maintenance_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_mileage_company_id ON public.vehicle_mileage(company_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_mileage_daily_company_id ON public.vehicle_mileage_daily(company_id);
CREATE INDEX IF NOT EXISTS idx_pl_records_company_id ON public.pl_records(company_id);
CREATE INDEX IF NOT EXISTS idx_alerts_company_id ON public.alerts(company_id);
CREATE INDEX IF NOT EXISTS idx_locked_months_company_id ON public.locked_months(company_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_company_id ON public.system_settings(company_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_company_id ON public.audit_log(company_id);

-- FILE: 20260325210500_employees_name_not_empty_check.sql
DO $$
DECLARE
  v_invalid_count bigint;
BEGIN
  SELECT COUNT(*) INTO v_invalid_count
  FROM public.employees
  WHERE name IS NULL OR length(btrim(name)) = 0;
  IF v_invalid_count > 0 THEN
    RAISE EXCEPTION
      'employees.name validation failed: % rows have NULL/empty names. Clean data first, then re-run migration.',
      v_invalid_count;
  END IF;
END
$$;
ALTER TABLE public.employees
  ADD CONSTRAINT employees_name_not_empty
  CHECK (name IS NOT NULL AND length(btrim(name)) > 0);

-- FILE: 20260325211000_edge_rate_limit_guard.sql
CREATE TABLE IF NOT EXISTS public.edge_rate_limits (
  key text PRIMARY KEY,
  window_start timestamptz NOT NULL,
  request_count integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- FILE: 20260325213500_generate_missing_multitenant_rls_policies.sql
DO $$
DECLARE
  t record;
  v_policy_count integer;
BEGIN
  FOR t IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables tb
      ON tb.table_schema = c.table_schema
     AND tb.table_name = c.table_name
    WHERE c.table_schema = 'public'
      AND c.column_name = 'company_id'
      AND tb.table_type = 'BASE TABLE'
  LOOP
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
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- FILE: 20260325234500_admin_action_log.sql
﻿-- Dedicated admin action log (application-level audit trail).
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
CREATE INDEX IF NOT EXISTS idx_admin_action_log_created_at
  ON public.admin_action_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_action_log_table_record
  ON public.admin_action_log (table_name, record_id);
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;

-- FILE: 20260326001000_dashboard_overview_rpc.sql
﻿-- Dashboard overview aggregation (server-side).

-- FILE: 20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql
﻿-- ============================================================================
INSERT INTO public.roles (title, permissions, is_active)
VALUES
  ('admin', '{}'::jsonb, true),
  ('hr', '{}'::jsonb, true),
  ('finance', '{}'::jsonb, true),
  ('accountant', '{}'::jsonb, true),
  ('operations', '{}'::jsonb, true),
  ('viewer', '{}'::jsonb, true)
ON CONFLICT (title) DO UPDATE
SET is_active = EXCLUDED.is_active;
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  '*', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true, 'approve', true),
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'approve', true),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true, 'approve', true),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', true),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = _const_role_admin()::text;
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = 'hr';
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'approve', true),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false, 'approve', true),
  'roles',      jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title IN ('finance', 'accountant');
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', true, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', false, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', true, 'write', true)
)
WHERE title = 'operations';
UPDATE public.roles
SET permissions = jsonb_build_object /* NOSONAR */(
  'employees',  jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  _const_work_orders(),     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'attendance', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false),
  'salary',     jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'approve', false),
  'financials', jsonb_build_object /* NOSONAR */('view', true, 'write', false, 'delete', false, 'approve', false),
  'roles',      jsonb_build_object /* NOSONAR */('view', false, 'write', false, 'delete', false),
  'audit',      jsonb_build_object /* NOSONAR */('view', false, 'write', false)
)
WHERE title = _const_role_viewer()::text;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advance_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_deductions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pl_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_action_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees            ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.employees            ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.daily_orders         ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.attendance           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advances             ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advances             ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advance_installments ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.external_deductions  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.external_deductions  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.salary_records       ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.salary_records       ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.pl_records           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS total_hours NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS late BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS early_leave BOOLEAN NOT NULL DEFAULT false;

-- FILE: 20260326021000_phase_1_1_remove_company_id_single_org.sql
BEGIN;
DROP FUNCTION IF EXISTS public.jwt_company_id() CASCADE;
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
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260327124500_assert_no_company_id_leftovers.sql
DO $$
DECLARE
  v_count integer;
  v_sample text;
BEGIN
  SELECT COUNT(*)::int
  INTO v_count
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND lower(c.column_name) = 'company_id';
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I', c.table_schema, c.table_name), ', ' ORDER BY c.table_name)
    INTO v_sample
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND lower(c.column_name) = 'company_id';
    RAISE EXCEPTION 'Assertion failed: company_id columns still exist (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
  SELECT COUNT(*)::int
  INTO v_count
  FROM pg_constraint pc
  JOIN pg_class tbl ON tbl.oid = pc.conrelid
  JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
  WHERE ns.nspname = 'public'
    AND pg_get_constraintdef(pc.oid) ILIKE '%company_id%';
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I (%s)', ns.nspname, tbl.relname, pc.conname), ', ' ORDER BY tbl.relname, pc.conname)
    INTO v_sample
    FROM pg_constraint pc
    JOIN pg_class tbl ON tbl.oid = pc.conrelid
    JOIN pg_namespace ns ON ns.oid = tbl.relnamespace
    WHERE ns.nspname = 'public'
      AND pg_get_constraintdef(pc.oid) ILIKE '%company_id%';
    RAISE EXCEPTION 'Assertion failed: constraints still reference company_id (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
  SELECT COUNT(*)::int
  INTO v_count
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND (
      COALESCE(p.qual, '') ILIKE '%company_id%'
      OR COALESCE(p.with_check, '') ILIKE '%company_id%'
    );
  IF v_count > 0 THEN
    SELECT string_agg(format('%I.%I [%I]', p.schemaname, p.tablename, p.policyname), ', ' ORDER BY p.tablename, p.policyname)
    INTO v_sample
    FROM pg_policies p
    WHERE p.schemaname = 'public'
      AND (
        COALESCE(p.qual, '') ILIKE '%company_id%'
        OR COALESCE(p.with_check, '') ILIKE '%company_id%'
      );
    RAISE EXCEPTION 'Assertion failed: RLS policies still reference company_id (%): %', v_count, COALESCE(v_sample, 'n/a');
  END IF;
END
$$;

-- FILE: 20260327130000_allow_attendance_viewers_to_read_employees.sql
BEGIN;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260328100000_single_org_platform_accounts_triggers_and_rls.sql
﻿-- Single-organization: remove platform_accounts / account_assignments sync triggers
BEGIN;
DROP FUNCTION IF EXISTS public.sync_platform_accounts_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_account_assignments_company_id() CASCADE;
ALTER TABLE IF EXISTS public.account_assignments DROP COLUMN IF EXISTS company_id CASCADE;
COMMIT;

-- FILE: 20260328220000_fleet_spare_parts.sql
﻿-- Fleet: spare parts inventory (single-org RLS aligned with vehicles / fuel)
BEGIN;
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
COMMIT;

-- FILE: 20260328221000_fleet_maintenance_logs_and_parts.sql
﻿-- Replace legacy maintenance_logs with fleet maintenance + line-item parts.
BEGIN;
ALTER TABLE IF EXISTS public.maintenance_logs RENAME TO maintenance_logs_legacy_pre_fleet;
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  maintenance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  type TEXT NOT NULL
    CHECK (type IN (
      'غيار زيت', 'صيانة دورية', 'إطارات', 'بطارية', 'فرامل', 'أعطال', 'أخرى'
    )),
  odometer_reading NUMERIC(10, 0),
  total_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'مكتملة'
    CHECK (status IN ('مكتملة', 'جارية', 'ملغاة')),
  notes TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.maintenance_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maintenance_log_id UUID NOT NULL REFERENCES public.maintenance_logs(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES public.spare_parts(id) ON DELETE RESTRICT,
  quantity_used NUMERIC(10, 2) NOT NULL,
  cost_at_time NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_vehicle_id ON public.maintenance_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_maintenance_date ON public.maintenance_logs(maintenance_date DESC);
CREATE INDEX IF NOT EXISTS idx_maintenance_parts_log_id ON public.maintenance_parts(maintenance_log_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_parts_part_id ON public.maintenance_parts(part_id);
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_parts ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260328222000_fleet_maintenance_triggers.sql
BEGIN;
COMMIT;

-- FILE: 20260329123000_ensure_spare_parts_exists.sql
﻿-- Ensure fleet spare parts table exists on environments that missed prior migration.
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
COMMIT;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260329143000_supervisor_targets_and_assignments.sql
﻿-- Supervisor monthly targets + rider assignments (single-org safe).
BEGIN;
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
CREATE INDEX IF NOT EXISTS idx_supervisor_targets_month ON public.supervisor_targets (month_year);
ALTER TABLE public.supervisor_targets ENABLE ROW LEVEL SECURITY;
COMMIT;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260329210000_salary_per_order_band_and_calc_tiers.sql
BEGIN;
ALTER TABLE public.salary_scheme_tiers
  DROP CONSTRAINT IF EXISTS salary_scheme_tiers_tier_type_check;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
  CHECK (tier_type IN (
    'total_multiplier',
    _const_tier_fixed(),
    _const_tier_incremental(),
    'per_order_band'
  ));
COMMENT ON FUNCTION public.calc_tier_salary(INTEGER) IS
  'Default tier curve (single-band): 1–300×3، 301–400×4، 401–449×5، 450–470 ثابت 2500، فوق 470: 2500+(n-470)×5. Schemes UI may use per_order_band tiers for the same logic per app.';
COMMIT;

-- FILE: 20260330120000_salary_slip_templates.sql
CREATE TABLE IF NOT EXISTS public.salary_slip_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    header_html TEXT DEFAULT '',
    footer_html TEXT DEFAULT '',
    selected_columns JSONB DEFAULT '[]'::jsonb,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.salary_slip_templates ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';
INSERT INTO public.salary_slip_templates (name, header_html, footer_html, selected_columns, is_default)
VALUES (
    'Default Enterprise Template',
    '<div class="header"><div><div class="header-brand">Muhimmat Delivery</div><div class="header-subtitle">Monthly Salary Slip</div></div></div>',
    '<div class="footer"><div class="signature-box"><div class="signature-line"></div><div>Employee Signature</div></div><div class="signature-box"><div class="signature-line"></div><div>Management Approval</div></div></div>',
    '["employeeName", "nationalId", "totalOrders", "baseSalary", "incentives", "netSalary"]'::jsonb,
    true
) ON CONFLICT DO NOTHING;

-- FILE: 20260401000000_fix_tier_type_constraint.sql
ALTER TABLE public.salary_scheme_tiers
  DROP CONSTRAINT IF EXISTS salary_scheme_tiers_tier_type_check;
ALTER TABLE public.salary_scheme_tiers
  ADD CONSTRAINT salary_scheme_tiers_tier_type_check
  CHECK (tier_type IN (
    'total_multiplier',
    _const_tier_fixed(),
    _const_tier_incremental(),
    'per_order_band'
  ));

-- FILE: 20260402010000_assign_platform_account_rpc.sql
﻿BEGIN;
COMMIT;

-- FILE: 20260403000000_add_commercial_record_to_employees.sql
ALTER TABLE public.employees
ADD COLUMN IF NOT EXISTS commercial_record TEXT;
COMMENT ON COLUMN public.employees.commercial_record IS 'رقم السجل التجاري للمندوب - يستخدم في التنبيهات والتقارير';

-- FILE: 20260403000001_update_salary_engine_for_shifts.sql
BEGIN;
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_month(TEXT, TEXT);
COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS 'v4: Calculates salary supporting orders, shift, and hybrid work types';
COMMIT;

-- FILE: 20260404000000_remove_company_id_from_platform_accounts.sql
﻿-- ══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS public.sync_platform_accounts_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.sync_account_assignments_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.platform_account_in_my_company(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.assignment_in_my_company(uuid) CASCADE;
DROP INDEX IF EXISTS idx_platform_accounts_company_id;
DROP INDEX IF EXISTS idx_account_assignments_company_id;
ALTER TABLE public.platform_accounts DROP CONSTRAINT IF EXISTS platform_accounts_company_id_fkey;
ALTER TABLE public.account_assignments DROP CONSTRAINT IF EXISTS account_assignments_company_id_fkey;
ALTER TABLE public.platform_accounts DROP COLUMN IF EXISTS company_id;
ALTER TABLE public.account_assignments DROP COLUMN IF EXISTS company_id;

-- FILE: 20260404010000_cleanup_employee_code_and_employee_cities.sql
BEGIN;
UPDATE public.employees
SET preferred_language = 'ar'
WHERE preferred_language = 'ur';
ALTER TABLE public.employees
  DROP CONSTRAINT IF EXISTS employees_preferred_language_check;
ALTER TABLE public.employees
  ALTER COLUMN preferred_language SET DEFAULT 'ar';
ALTER TABLE public.employees
  ADD CONSTRAINT employees_preferred_language_check
  CHECK (preferred_language IN ('ar', 'en'));
DROP VIEW IF EXISTS public.v_rider_daily_platform_orders CASCADE;
ALTER TABLE public.employees
  ALTER COLUMN city TYPE text
  USING city::text;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS cities text[];
UPDATE public.employees
SET cities = CASE
  WHEN cities IS NOT NULL AND array_length(cities, 1) > 0 THEN cities
  WHEN city IS NULL THEN '{}'::text[]
  ELSE ARRAY[city]
END;
UPDATE public.employees
SET cities = COALESCE(
  (
    SELECT array_agg(DISTINCT normalized_city)
    FROM (
      SELECT NULLIF(trim(value), '') AS normalized_city
      FROM unnest(COALESCE(cities, '{}'::text[])) AS value
    ) AS normalized
    WHERE normalized_city IS NOT NULL
  ),
  '{}'::text[]
);
UPDATE public.employees
SET city = NULLIF(cities[1], '');
ALTER TABLE public.employees
  ALTER COLUMN cities SET DEFAULT '{}'::text[];
DROP INDEX IF EXISTS public.employees_employee_code_unique;
ALTER TABLE public.employees
  DROP COLUMN IF EXISTS employee_code;
COMMENT ON COLUMN public.employees.cities IS
  'قائمة المدن المسموح للموظف العمل فيها، وأول عنصر منها يمثل المدينة الرئيسية.';
COMMIT;

-- FILE: 20260405000000_add_shifts_and_hybrid_work_types.sql
ALTER TABLE apps ADD COLUMN IF NOT EXISTS work_type TEXT DEFAULT _const_work_orders() 
  CHECK (work_type IN (_const_work_orders(), _const_work_shift(), _const_work_hybrid()));
COMMENT ON COLUMN apps.work_type IS 'نوع العمل: orders (طلبات), shift (دوام), hybrid (مختلط)';
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
ALTER TABLE daily_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_hybrid_rules ENABLE ROW LEVEL SECURITY;

-- FILE: 20260406000000_fix_salary_preview_for_shifts.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.preview_salary_for_month IS 'v2: Preview salary supporting orders, shift, and hybrid work types';
COMMIT;

-- FILE: 20260407000000_concurrent_editing_protection.sql
ALTER TABLE public.salary_records 
ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1 NOT NULL;
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
CREATE INDEX IF NOT EXISTS idx_salary_drafts_user_month 
ON public.salary_drafts(user_id, month_year);
ALTER TABLE public.salary_drafts ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'salary_drafts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.salary_drafts;
  END IF;
END $$;
COMMENT ON COLUMN public.salary_records.version IS 'Optimistic locking version - increments on each update to detect concurrent modifications';
COMMENT ON TABLE public.salary_drafts IS 'Server-side storage for salary editing drafts - replaces localStorage to enable cross-device and multi-user scenarios';
COMMENT ON COLUMN public.salary_drafts.draft_data IS 'JSONB containing: incentives, violations, customDeductions, sickAllowance, transfer, etc.';

-- FILE: 20260407000001_salary_preview_platform_breakdown.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.preview_salary_for_month IS 'v3: Preview salary with shift/hybrid-aware per-platform breakdown';
COMMIT;

-- FILE: 20260407110000_employee_commercial_records_and_iqama_docs.sql
﻿BEGIN;
CREATE TABLE IF NOT EXISTS public.commercial_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT commercial_records_name_not_blank CHECK (btrim(name) <> '')
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_commercial_records_name_ci
  ON public.commercial_records (lower(btrim(name)));
ALTER TABLE public.commercial_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS iqama_photo_url text;
CREATE INDEX IF NOT EXISTS idx_employees_commercial_record
  ON public.employees (commercial_record)
  WHERE commercial_record IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_employees_residency_expiry
  ON public.employees (residency_expiry)
  WHERE residency_expiry IS NOT NULL;
INSERT INTO public.commercial_records (name)
SELECT DISTINCT btrim(commercial_record)
FROM public.employees
WHERE NULLIF(btrim(commercial_record), '') IS NOT NULL
ON CONFLICT DO NOTHING;
UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
WHERE id = 'employee-documents';
COMMIT;

-- FILE: 20260408000000_align_salary_engine_with_sheet_and_admin_titles.sql
BEGIN;
DROP FUNCTION IF EXISTS public.is_salary_admin_job_title(TEXT);
DROP FUNCTION IF EXISTS public.calculate_order_salary_for_app(UUID, INTEGER, INTEGER, UUID[], BOOLEAN);
DROP FUNCTION IF EXISTS public.is_salary_month_visible_employee(UUID, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS public.calculate_salary_for_month(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.preview_salary_for_month(TEXT);
COMMENT ON FUNCTION public.calculate_salary_for_employee_month IS
  'v5: Sheet-aligned salary calculation using app pricing rules, salary schemes, and admin-title visibility';
COMMENT ON FUNCTION public.preview_salary_for_month IS
  'v4: Sheet-aligned preview with per-platform breakdown and admin-title visibility';
COMMIT;

-- FILE: 20260409000000_salary_record_sheet_snapshot.sql
ALTER TABLE public.salary_records
ADD COLUMN IF NOT EXISTS sheet_snapshot JSONB;
COMMENT ON COLUMN public.salary_records.sheet_snapshot IS
'Canonical UI snapshot for approved/paid salary rows so the salary sheet can be restored exactly after reload.';

-- FILE: 20260410000000_performance_engine_foundation.sql
﻿BEGIN;
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
CREATE INDEX IF NOT EXISTS idx_employee_targets_employee_month
  ON public.employee_targets(employee_id, month_year);
CREATE INDEX IF NOT EXISTS idx_employee_targets_month
  ON public.employee_targets(month_year);
ALTER TABLE public.employee_targets ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.employee_targets IS
'Monthly and daily delivery targets per employee.';
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
CREATE INDEX IF NOT EXISTS idx_order_import_batches_month_year
  ON public.order_import_batches(month_year, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_import_batches_status
  ON public.order_import_batches(status);
ALTER TABLE public.order_import_batches ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.order_import_batches IS
'Audit trail for orders imports and month replacements.';
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS import_batch_id UUID REFERENCES public.order_import_batches(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_daily_orders_import_batch_id
  ON public.daily_orders(import_batch_id);
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
CREATE INDEX IF NOT EXISTS idx_salary_month_snapshots_month
  ON public.salary_month_snapshots(month_year);
ALTER TABLE public.salary_month_snapshots ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.salary_month_snapshots IS
'Frozen accounting snapshot of salary records for each month.';
COMMENT ON VIEW public.v_rider_daily_platform_orders IS
'Performance write-model projection: daily orders per employee and platform.';
COMMENT ON VIEW public.v_rider_daily_performance IS
'Performance read-model: one daily summary row per rider with platform breakdown.';
COMMENT ON VIEW public.v_rider_monthly_performance IS
'Performance read-model: monthly rider metrics, consistency, and target achievement.';
COMMENT ON FUNCTION public.replace_daily_orders_month_rpc(TEXT, JSONB, TEXT, TEXT, UUID) IS
'Transactional month replacement for daily orders with import-batch tracking.';
COMMENT ON FUNCTION public.capture_salary_month_snapshot(TEXT) IS
'Freeze a month-level salary snapshot for accounting and reload parity.';
COMMIT;

-- FILE: 20260410010000_performance_dashboard_rpcs.sql
﻿BEGIN;
CREATE INDEX IF NOT EXISTS idx_daily_orders_perf_date_employee
  ON public.daily_orders(date, employee_id, app_id)
  WHERE orders_count > 0;
CREATE INDEX IF NOT EXISTS idx_daily_orders_perf_employee_date
  ON public.daily_orders(employee_id, date)
  WHERE orders_count > 0;
CREATE INDEX IF NOT EXISTS idx_salary_records_month_employee
  ON public.salary_records(month_year, employee_id);
COMMENT ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) IS
'Single backend source for dashboard KPIs, comparisons, rankings, alerts, and performance trends.';
COMMENT ON FUNCTION public.rider_profile_performance_rpc(UUID, TEXT, DATE) IS
'Single backend source for rider profile performance, comparisons, targets, alerts, and salary snapshot.';
COMMIT;

-- FILE: 20260410011000_fix_performance_dashboard_avg_orders.sql
BEGIN;
DO $$
DECLARE
  v_definition TEXT;
  v_updated_definition TEXT;
  v_old_crlf TEXT;
  v_old_lf TEXT;
  v_new_block TEXT;
BEGIN
  SELECT pg_get_functiondef('public.performance_dashboard_rpc(text, date)'::regprocedure)
    INTO v_definition;
  IF v_definition IS NULL THEN
    RAISE EXCEPTION 'Function public.performance_dashboard_rpc(text, date) was not found';
  END IF;
  v_old_crlf :=
    '          SELECT ROUND(current_orders::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE total_orders > 0), 0), 2)'
    || E'\r\n'
    || '          FROM month_comparison, current_month';
  v_old_lf :=
    '          SELECT ROUND(current_orders::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE total_orders > 0), 0), 2)'
    || E'\n'
    || '          FROM month_comparison, current_month';
  v_new_block :=
    '          SELECT ROUND('
    || E'\n'
    || '            COALESCE((SELECT current_orders FROM month_comparison), 0)::NUMERIC'
    || E'\n'
    || '            / NULLIF((SELECT COUNT(*)::INTEGER FROM current_month WHERE total_orders > 0), 0),'
    || E'\n'
    || '            2'
    || E'\n'
    || '          )';
  v_updated_definition := replace(v_definition, v_old_crlf, v_new_block);
  IF v_updated_definition = v_definition THEN
    v_updated_definition := replace(v_definition, v_old_lf, v_new_block);
  END IF;
  IF v_updated_definition = v_definition THEN
    RAISE NOTICE 'Hotfix pattern was not found in public.performance_dashboard_rpc(text, date). It may have already been applied.';
    RETURN;
  END IF;
  EXECUTE v_updated_definition;
END;
$$;
COMMENT ON FUNCTION public.performance_dashboard_rpc(TEXT, DATE) IS
'Single backend source for dashboard KPIs, comparisons, rankings, alerts, and performance trends.';
COMMIT;

-- FILE: 20260410020000_fix_auth_users_fk_cascade_for_delete.sql
ALTER TABLE public.employee_scheme
  DROP CONSTRAINT IF EXISTS employee_scheme_assigned_by_fkey;
ALTER TABLE public.employee_scheme
  ADD CONSTRAINT employee_scheme_assigned_by_fkey
  FOREIGN KEY (assigned_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.vehicle_assignments
  DROP CONSTRAINT IF EXISTS vehicle_assignments_created_by_fkey;
ALTER TABLE public.vehicle_assignments
  ADD CONSTRAINT vehicle_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.maintenance_logs
  DROP CONSTRAINT IF EXISTS maintenance_logs_created_by_fkey;
ALTER TABLE public.maintenance_logs
  ADD CONSTRAINT maintenance_logs_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.attendance
  DROP CONSTRAINT IF EXISTS attendance_created_by_fkey;
ALTER TABLE public.attendance
  ADD CONSTRAINT attendance_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.daily_orders
  DROP CONSTRAINT IF EXISTS daily_orders_created_by_fkey;
ALTER TABLE public.daily_orders
  ADD CONSTRAINT daily_orders_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.advances
  DROP CONSTRAINT IF EXISTS advances_approved_by_fkey;
ALTER TABLE public.advances
  ADD CONSTRAINT advances_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.external_deductions
  DROP CONSTRAINT IF EXISTS external_deductions_approved_by_fkey;
ALTER TABLE public.external_deductions
  ADD CONSTRAINT external_deductions_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.salary_records
  DROP CONSTRAINT IF EXISTS salary_records_approved_by_fkey;
ALTER TABLE public.salary_records
  ADD CONSTRAINT salary_records_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.pl_records
  DROP CONSTRAINT IF EXISTS pl_records_created_by_fkey;
ALTER TABLE public.pl_records
  ADD CONSTRAINT pl_records_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.alerts
  DROP CONSTRAINT IF EXISTS alerts_resolved_by_fkey;
ALTER TABLE public.alerts
  ADD CONSTRAINT alerts_resolved_by_fkey
  FOREIGN KEY (resolved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.audit_log
  DROP CONSTRAINT IF EXISTS audit_log_user_id_fkey;
ALTER TABLE public.audit_log
  ADD CONSTRAINT audit_log_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.account_assignments
  DROP CONSTRAINT IF EXISTS account_assignments_created_by_fkey;
ALTER TABLE public.account_assignments
  ADD CONSTRAINT account_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.locked_months
  DROP CONSTRAINT IF EXISTS locked_months_locked_by_fkey;
ALTER TABLE public.locked_months
  ADD CONSTRAINT locked_months_locked_by_fkey
  FOREIGN KEY (locked_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- FILE: 20260410030000_fix_salary_engine_ambiguous_column.sql
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260410040000_fix_security_definer_views.sql
ALTER VIEW public.v_rider_daily_platform_orders SET (security_invoker = true);
ALTER VIEW public.v_rider_daily_performance SET (security_invoker = true);
ALTER VIEW public.v_rider_monthly_performance SET (security_invoker = true);

-- FILE: 20260410050000_fix_search_path_and_security_invoker.sql
ALTER FUNCTION public.is_salary_admin_job_title(TEXT)
  SET search_path = 'public';
ALTER FUNCTION public.check_no_overlap_orders_shifts()
  SET search_path = 'public';
ALTER FUNCTION public.update_daily_shifts_updated_at()
  SET search_path = 'public';
ALTER FUNCTION public.update_salary_drafts_updated_at()
  SET search_path = 'public';
ALTER FUNCTION public.increment_salary_record_version()
  SET search_path = 'public';
ALTER FUNCTION public.update_updated_at_column()
  SET search_path = 'public';
ALTER FUNCTION public.calc_tier_salary(INTEGER)
  SET search_path = 'public';
ALTER FUNCTION public.fn_handle_employee_sponsorship_alerts()
  SET search_path = 'public';

-- FILE: 20260410060000_fix_sponsorship_alerts_company_id.sql
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  trade_cr TEXT;
  msg TEXT;
  accounts_json JSONB;
  vehicles_json JSONB;
  trade_json JSONB;
BEGIN
  status := NEW.sponsorship_status::TEXT;
  IF (NEW.sponsorship_status IS DISTINCT FROM OLD.sponsorship_status)
     AND (status IN ('absconded', 'terminated')) THEN
    IF status = 'terminated' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.platform_accounts WHERE employee_id = NEW.id
      ) THEN
        RETURN NEW;
      END IF;
    END IF;
    SELECT
      STRING_AGG(format('%s: %s', a.name, pa.account_username), ', ' ORDER BY a.name),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'app', a.name,
          'username', pa.account_username,
          'account_id_on_platform', pa.account_id_on_platform,
          'iqama_number', pa.iqama_number
        )
      ), '[]'::jsonb)
    INTO account_list, accounts_json
    FROM public.platform_accounts pa
    JOIN public.apps a ON a.id = pa.app_id
    WHERE pa.employee_id = NEW.id;
    SELECT
      COUNT(*)::int,
      STRING_AGG(v.plate_number, ', ' ORDER BY v.plate_number),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT('vehicle_id', v.id, 'plate_number', v.plate_number)
      ), '[]'::jsonb)
    INTO vehicle_count, vehicle_plate_list, vehicles_json
    FROM public.vehicle_assignments va
    JOIN public.vehicles v ON v.id = va.vehicle_id
    WHERE va.employee_id = NEW.id
      AND va.end_date IS NULL
      AND va.returned_at IS NULL;
    trade_name := NEW.commercial_record;
    trade_cr := NULL;
    trade_json := '{}'::jsonb;
    IF NEW.commercial_record IS NOT NULL AND NEW.commercial_record <> '' THEN
      SELECT
        cr.name,
        cr.cr_number,
        JSONB_BUILD_OBJECT(
          'name', cr.name,
          'cr_number', cr.cr_number
        )
      INTO trade_name, trade_cr, trade_json
      FROM public.commercial_records cr
      WHERE cr.name = NEW.commercial_record
      LIMIT 1;
    END IF;
    msg :=
      format(
        'الموظف: %s (الهوية: %s) | منصات: %s | مركبات: %s | سجل تجاري: %s',
        COALESCE(NEW.name, '—'),
        COALESCE(NEW.national_id, '—'),
        COALESCE(account_list, '—'),
        COALESCE(vehicle_plate_list, CASE WHEN vehicle_count IS NULL THEN '—' ELSE vehicle_count::TEXT || ' مركبة' END),
        COALESCE(trade_name, '—')
      );
    INSERT INTO public.alerts (
      type,
      entity_id,
      entity_type,
      due_date,
      message,
      details
    )
    VALUES (
      CASE WHEN status = 'absconded' THEN 'employee_absconded' ELSE 'employee_terminated' END,
      NEW.id,
      'employee',
      CURRENT_DATE,
      msg,
      JSONB_BUILD_OBJECT(
        'employee_id', NEW.id,
        'employee_name', NEW.name,
        'national_id', NEW.national_id,
        'sponsorship_status', status,
        'platform_accounts', accounts_json,
        'vehicle_count', COALESCE(vehicle_count, 0),
        'vehicle_plates', COALESCE(vehicle_plate_list, ''),
        'vehicles', vehicles_json,
        'trade_register', trade_json,
        'trade_cr_number', trade_cr
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = 'public';

-- FILE: 20260411000000_attendance_status_configs.sql
﻿CREATE TABLE IF NOT EXISTS public.attendance_status_configs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#6366f1',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.attendance_status_configs ENABLE ROW LEVEL SECURITY;

-- FILE: 20260411010000_rls_edge_rate_limits.sql
ALTER TABLE public.edge_rate_limits ENABLE ROW LEVEL SECURITY;

-- FILE: 20260411030000_fix_preview_salary_shift_threshold.sql
BEGIN;
COMMIT;

-- FILE: 20260411040000_fix_preview_salary_read_scheme.sql
BEGIN;
COMMIT;

-- FILE: 20260411050000_finance_transactions.sql
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
CREATE INDEX IF NOT EXISTS idx_finance_transactions_month ON public.finance_transactions(month_year);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_type ON public.finance_transactions(type);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_date ON public.finance_transactions(date);
ALTER TABLE public.finance_transactions ENABLE ROW LEVEL SECURITY;

-- FILE: 20260413000000_fix_sponsorship_alert_cr_number.sql
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
RETURNS TRIGGER AS $$
DECLARE
  status TEXT;
  account_list TEXT;
  vehicle_plate_list TEXT;
  vehicle_count INT;
  trade_name TEXT;
  msg TEXT;
  accounts_json JSONB;
  vehicles_json JSONB;
  trade_json JSONB;
BEGIN
  status := NEW.sponsorship_status::TEXT;
  IF (NEW.sponsorship_status IS DISTINCT FROM OLD.sponsorship_status)
     AND (status IN ('absconded', 'terminated')) THEN
    IF status = 'terminated' THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.platform_accounts WHERE employee_id = NEW.id
      ) THEN
        RETURN NEW;
      END IF;
    END IF;
    SELECT
      STRING_AGG(format('%s: %s', a.name, pa.account_username), ', ' ORDER BY a.name),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT(
          'app', a.name,
          'username', pa.account_username,
          'account_id_on_platform', pa.account_id_on_platform,
          'iqama_number', pa.iqama_number
        )
      ), '[]'::jsonb)
    INTO account_list, accounts_json
    FROM public.platform_accounts pa
    JOIN public.apps a ON a.id = pa.app_id
    WHERE pa.employee_id = NEW.id;
    SELECT
      COUNT(*)::int,
      STRING_AGG(v.plate_number, ', ' ORDER BY v.plate_number),
      COALESCE(JSONB_AGG(
        JSONB_BUILD_OBJECT('vehicle_id', v.id, 'plate_number', v.plate_number)
      ), '[]'::jsonb)
    INTO vehicle_count, vehicle_plate_list, vehicles_json
    FROM public.vehicle_assignments va
    JOIN public.vehicles v ON v.id = va.vehicle_id
    WHERE va.employee_id = NEW.id
      AND va.end_date IS NULL
      AND va.returned_at IS NULL;
    trade_name := NEW.commercial_record;
    trade_json := JSONB_BUILD_OBJECT('name', COALESCE(NEW.commercial_record, ''));
    msg :=
      format(
        'الموظف: %s (الهوية: %s) | منصات: %s | مركبات: %s | سجل تجاري: %s',
        COALESCE(NEW.name, '—'),
        COALESCE(NEW.national_id, '—'),
        COALESCE(account_list, '—'),
        COALESCE(vehicle_plate_list, CASE WHEN vehicle_count IS NULL THEN '—' ELSE vehicle_count::TEXT || ' مركبة' END),
        COALESCE(trade_name, '—')
      );
    INSERT INTO public.alerts (
      type,
      entity_id,
      entity_type,
      due_date,
      message,
      details
    )
    VALUES (
      CASE WHEN status = 'absconded' THEN 'employee_absconded' ELSE 'employee_terminated' END,
      NEW.id,
      'employee',
      CURRENT_DATE,
      msg,
      JSONB_BUILD_OBJECT(
        'employee_id', NEW.id,
        'employee_name', NEW.name,
        'national_id', NEW.national_id,
        'sponsorship_status', status,
        'platform_accounts', accounts_json,
        'vehicle_count', COALESCE(vehicle_count, 0),
        'vehicle_plates', COALESCE(vehicle_plate_list, ''),
        'vehicles', vehicles_json,
        'trade_register', trade_json
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = 'public';

-- FILE: 20260413090000_fix_salary_preview_skip_unlinked_platforms.sql
BEGIN;
COMMENT ON FUNCTION public.preview_salary_for_month IS
  'Preview salary while ignoring apps that no longer have a linked salary scheme.';
COMMIT;

-- FILE: 20260413100000_fix_salary_rpc_flat_rate_and_scheme.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(INTEGER) CASCADE;

-- FILE: 20260414000000_add_salary_slip_template_columns.sql
ALTER TABLE public.salary_slip_templates
  ADD COLUMN IF NOT EXISTS header_html TEXT,
  ADD COLUMN IF NOT EXISTS footer_html TEXT,
  ADD COLUMN IF NOT EXISTS selected_columns JSONB DEFAULT '[]'::jsonb;

-- FILE: 20260415000000_audit_log_performance.sql
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON public.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON public.audit_log(table_name);

-- FILE: 20260415000001_constants.sql
﻿-- =============================================================================
DO $$ BEGIN
  CREATE TEMP TABLE IF NOT EXISTS _order_statuses AS
  SELECT _const_order_cancelled()::TEXT AS cancelled;
  CREATE TEMP TABLE IF NOT EXISTS _installment_statuses AS
  SELECT 
    _const_installment_pending()::TEXT AS pending,
    _const_installment_deferred()::TEXT AS deferred;
  CREATE TEMP TABLE IF NOT EXISTS _approval_statuses AS
  SELECT _const_approval_approved()::TEXT AS approved;
  CREATE TEMP TABLE IF NOT EXISTS _work_types AS
  SELECT
    _const_work_orders()::TEXT AS orders,
    _const_work_shift()::TEXT AS shift,
    _const_work_hybrid()::TEXT AS hybrid;
  CREATE TEMP TABLE IF NOT EXISTS _calc_methods AS
  SELECT
    _const_work_orders()::TEXT AS orders,
    _const_work_shift()::TEXT AS shift,
    _const_calc_method_shift_fixed()::TEXT AS shift_fixed,
    _const_calc_method_shift_full_month()::TEXT AS shift_full_month,
    _const_calc_method_mixed()::TEXT AS mixed,
    _const_calc_method_orders_fallback()::TEXT AS orders_fallback;
  CREATE TEMP TABLE IF NOT EXISTS _tier_types AS
  SELECT
    _const_tier_fixed()::TEXT AS fixed_amount,
    _const_tier_incremental()::TEXT AS base_plus_incremental,
    'per_order'::TEXT AS per_order;
  CREATE TEMP TABLE IF NOT EXISTS _payment_methods AS
  SELECT
    _const_payment_cash()::TEXT AS cash,
    _const_payment_bank()::TEXT AS bank;
  CREATE TEMP TABLE IF NOT EXISTS _calc_statuses AS
  SELECT _const_calc_calculated()::TEXT AS calculated;
  CREATE TEMP TABLE IF NOT EXISTS _calc_sources AS
  SELECT
    _const_calc_source_v6()::TEXT AS v6_shift_fallback,
    _const_calc_source_v7()::TEXT AS v7_shift_fixed;
  CREATE TEMP TABLE IF NOT EXISTS _employee_statuses AS
  SELECT _const_employee_active()::TEXT AS active;
  CREATE TEMP TABLE IF NOT EXISTS _numeric_constants AS
  SELECT
    _const_days_per_month()::NUMERIC AS days_per_month,
    0::NUMERIC AS zero;
END $$;
CREATE OR REPLACE FUNCTION _const_order_cancelled() RETURNS TEXT AS $$
  SELECT 'cancelled'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_installment_pending() RETURNS TEXT AS $$
  SELECT 'pending'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_installment_deferred() RETURNS TEXT AS $$
  SELECT 'deferred'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_approval_approved() RETURNS TEXT AS $$
  SELECT 'approved'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_orders() RETURNS TEXT AS $$
  SELECT 'orders'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_shift() RETURNS TEXT AS $$
  SELECT 'shift'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_work_hybrid() RETURNS TEXT AS $$
  SELECT 'hybrid'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_days_per_month() RETURNS NUMERIC AS $$
  SELECT 30.0::NUMERIC;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_employee_active() RETURNS TEXT AS $$
  SELECT 'active'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_payment_cash() RETURNS TEXT AS $$
  SELECT 'cash'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_payment_bank() RETURNS TEXT AS $$
  SELECT 'bank'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_calculated() RETURNS TEXT AS $$
  SELECT 'calculated'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_source_v6() RETURNS TEXT AS $$
  SELECT 'engine_v6_shift_fallback'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_source_v7() RETURNS TEXT AS $$
  SELECT 'engine_v7_shift_fixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_orders() RETURNS TEXT AS $$
  SELECT _const_work_orders()::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift() RETURNS TEXT AS $$
  SELECT _const_work_shift()::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift_fixed() RETURNS TEXT AS $$
  SELECT 'shift_fixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_shift_full_month() RETURNS TEXT AS $$
  SELECT 'shift_full_month'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_mixed() RETURNS TEXT AS $$
  SELECT 'mixed'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_calc_method_orders_fallback() RETURNS TEXT AS $$
  SELECT 'orders_fallback'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_tier_fixed() RETURNS TEXT AS $$
  SELECT 'fixed_amount'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
CREATE OR REPLACE FUNCTION _const_tier_incremental() RETURNS TEXT AS $$
  SELECT 'base_plus_incremental'::TEXT;
$$ LANGUAGE SQL IMMUTABLE SET search_path = public;
COMMENT ON FUNCTION _const_order_cancelled() IS 'Constant: cancelled order status';
COMMENT ON FUNCTION _const_installment_pending() IS 'Constant: pending installment status';
COMMENT ON FUNCTION _const_installment_deferred() IS 'Constant: deferred installment status';
COMMENT ON FUNCTION _const_approval_approved() IS 'Constant: approved status';
COMMENT ON FUNCTION _const_work_orders() IS 'Constant: orders work type';
COMMENT ON FUNCTION _const_work_shift() IS 'Constant: shift work type';
COMMENT ON FUNCTION _const_work_hybrid() IS 'Constant: hybrid work type';
COMMENT ON FUNCTION _const_days_per_month() IS 'Constant: 30 days per month for salary calculations';
COMMENT ON FUNCTION _const_employee_active() IS 'Constant: active employee status';
COMMENT ON FUNCTION _const_payment_cash() IS 'Constant: cash payment method';
COMMENT ON FUNCTION _const_payment_bank() IS 'Constant: bank payment method';
COMMENT ON FUNCTION _const_calc_calculated() IS 'Constant: calculated status';
COMMENT ON FUNCTION _const_tier_fixed() IS 'Constant: fixed_amount tier type';
COMMENT ON FUNCTION _const_tier_incremental() IS 'Constant: base_plus_incremental tier type';
COMMENT ON FUNCTION _const_calc_source_v6() IS 'Constant: engine_v6_shift_fallback calc source';
COMMENT ON FUNCTION _const_calc_source_v7() IS 'Constant: engine_v7_shift_fixed calc source';
COMMENT ON FUNCTION _const_calc_method_orders() IS 'Constant: orders calculation method';
COMMENT ON FUNCTION _const_calc_method_shift() IS 'Constant: shift calculation method';
COMMENT ON FUNCTION _const_calc_method_shift_fixed() IS 'Constant: shift_fixed calculation method';
COMMENT ON FUNCTION _const_calc_method_shift_full_month() IS 'Constant: shift_full_month calculation method';
COMMENT ON FUNCTION _const_calc_method_mixed() IS 'Constant: mixed calculation method';
COMMENT ON FUNCTION _const_calc_method_orders_fallback() IS 'Constant: orders_fallback calculation method';

-- FILE: 20260415100000_fix_calc_tier_with_scheme_id.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(integer);

-- FILE: 20260415200000_debug_and_fix_shift_salary.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);

-- FILE: 20260415210000_shift_salary_fallback_full_month.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260415220000_shift_salary_always_full_month.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';

-- FILE: 20260416000000_apply_constants_pattern.sql
DROP FUNCTION IF EXISTS public.calc_tier_salary(integer, uuid);
COMMENT ON FUNCTION public.calc_tier_salary(INTEGER, UUID) IS 
  'Refactored to use constants - fixes SonarCloud literal duplication';
COMMENT ON FUNCTION public.preview_salary_for_month_v2(TEXT) IS 
  'Example function showing constant usage - replace preview_salary_for_month in production';

-- FILE: 20260416000001_refactor_shift_salary_with_constants.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
NOTIFY pgrst, 'reload schema';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS 
  'Refactored with constants - fixes SonarCloud CRITICAL: 10+ literal duplications removed';
COMMENT ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) IS 
  'Refactored with constants - fixes SonarCloud CRITICAL: 10+ literal duplications removed';

-- FILE: 20260416000002_fix_security_definer_permissions.sql
COMMENT ON FUNCTION public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT) IS 
  'SECURITY DEFINER - service_role only. Calculates and saves salary for an employee.';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS 
  'SECURITY DEFINER - service_role only. Previews salary calculations for all employees.';
COMMENT ON FUNCTION public.has_permission(TEXT, TEXT) IS 
  'SECURITY DEFINER - authenticated only. Checks if current user has a specific permission.';
COMMENT ON FUNCTION public.has_role(UUID, public.app_role) IS 
  'SECURITY DEFINER - authenticated only. Checks if a user has a specific role.';
COMMENT ON FUNCTION public.is_admin_or_hr(UUID) IS 
  'SECURITY DEFINER - authenticated only. Checks if user is admin or HR.';
NOTIFY pgrst, 'reload schema';

-- FILE: 20260416000003_unique_default_slip_template.sql
DO $$
BEGIN
  IF (SELECT count(*) FROM salary_slip_templates WHERE is_default = true) > 1 THEN
    UPDATE salary_slip_templates
    SET is_default = false
    WHERE is_default = true
      AND id != (
        SELECT id FROM salary_slip_templates
        WHERE is_default = true
        ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST
        LIMIT 1
      );
  END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS idx_salary_slip_templates_single_default
  ON salary_slip_templates (is_default)
  WHERE is_default = true;

-- FILE: 20260501000000_fix_security_warnings.sql
ALTER FUNCTION public.calc_tier_salary SET search_path = public;

-- FILE: 20260502000000_flip_admin_rider_logic.sql
DROP FUNCTION IF EXISTS public.is_salary_admin_job_title(TEXT);

-- FILE: 20260503000000_leave_requests.sql
CREATE TABLE IF NOT EXISTS public.leave_requests (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id      uuid        NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  type             text        NOT NULL CHECK (type IN ('annual','sick','emergency','unpaid','other')),
  start_date       date        NOT NULL,
  end_date         date        NOT NULL,
  days_count       integer     NOT NULL CHECK (days_count > 0),
  status           text        NOT NULL DEFAULT _const_installment_pending() CHECK (status IN (_const_installment_pending(),_const_approval_approved(),'rejected')),
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
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee   ON public.leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status     ON public.leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_start_date ON public.leave_requests(start_date DESC);
CREATE INDEX IF NOT EXISTS idx_leave_requests_type       ON public.leave_requests(type);

-- FILE: 20260503000001_performance_reviews.sql
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
ALTER TABLE public.apps
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_apps_is_archived ON public.apps(is_archived);
COMMENT ON COLUMN public.apps.is_archived IS
  'Soft archive flag. Archived apps are hidden from all UI lists and salary calculations. '
  'Use is_active to temporarily disable an app for a month.';

-- FILE: 20260504000000_fix_remaining_auth_users_fk.sql
ALTER TABLE public.account_assignments
  DROP CONSTRAINT IF EXISTS account_assignments_created_by_fkey;
ALTER TABLE public.account_assignments
  ADD CONSTRAINT account_assignments_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.finance_transactions
  DROP CONSTRAINT IF EXISTS finance_transactions_created_by_fkey;
ALTER TABLE public.finance_transactions
  ADD CONSTRAINT finance_transactions_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- FILE: 20260504000001_fix_security_warnings_v3.sql
﻿-- ============================================================
ALTER FUNCTION public.is_salary_admin_job_title(text) SET search_path = public;
CREATE OR REPLACE FUNCTION public.is_admin_or_hr(uid uuid) RETURNS boolean AS $$
BEGIN
  RETURN is_active_user(uid) AND (has_role(uid, _const_role_admin()) OR has_role(uid, _const_role_hr()));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.dashboard_overview_rpc(text, integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(text, text, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview_rpc(text, date) SECURITY INVOKER;
ALTER FUNCTION public.performance_dashboard_rpc(text, date) SECURITY INVOKER;
ALTER FUNCTION public.rider_profile_performance_rpc(uuid, text, date) SECURITY INVOKER;
ALTER FUNCTION public.calculate_salary_for_month(text, text) SECURITY INVOKER;
ALTER FUNCTION public.capture_salary_month_snapshot(text) SECURITY INVOKER;
ALTER FUNCTION public.preview_salary_for_month(text) SECURITY INVOKER;
ALTER FUNCTION public.advance_in_my_company(uuid) SECURITY INVOKER;
ALTER FUNCTION public.calculate_employee_salary(uuid, text, text, numeric, text) SECURITY INVOKER;
ALTER FUNCTION public.calculate_order_salary_for_app(uuid, integer, integer, uuid[], boolean) SECURITY INVOKER;
ALTER FUNCTION public.calculate_salary(uuid, text, text, numeric, text) SECURITY INVOKER;
ALTER FUNCTION public.check_employee_operational_records(uuid) SECURITY INVOKER;
ALTER FUNCTION public.check_in(uuid, timestamp with time zone) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(text, integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(text, text, date) SECURITY INVOKER;
ALTER FUNCTION public.dashboard_overview(integer, integer, date) SECURITY INVOKER;
ALTER FUNCTION public.employee_in_my_company(uuid) SECURITY INVOKER;
ALTER FUNCTION public.is_salary_month_visible_employee(uuid, text, text, text, text) SECURITY INVOKER;
ALTER FUNCTION public.replace_daily_orders_month_rpc(text, jsonb, text, text, uuid) SECURITY INVOKER;

-- FILE: 20260504000002_fix_logo_upload.sql
UPDATE storage.buckets
SET 
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/gif'],
  file_size_limit = 5242880
WHERE id = 'avatars';

-- FILE: 20260504000003_fix_remaining_security_warnings.sql
ALTER FUNCTION public.is_salary_month_visible_employee(uuid, text, text, text, text) SECURITY INVOKER;

-- FILE: 20260510000000_fix_employee_status_cast.sql
BEGIN;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_cast
    WHERE castsource = 'text'::regtype
      AND casttarget = 'public.employee_status'::regtype
      AND castcontext = 'i'  -- 'i' = implicit
  ) THEN
    CREATE CAST (text AS public.employee_status)
      WITH FUNCTION public.text_to_employee_status(text)
      AS IMPLICIT;
  END IF;
END $$;
COMMIT;

-- FILE: 20260510010000_fix_security_warnings.sql
﻿-- =============================================================================
COMMIT;

-- FILE: 20260511000000_auto_enum_operators.sql
DO $$
DECLARE
  e record;
  func_eq1 text;
  func_eq2 text;
  func_neq1 text;
  func_neq2 text;
BEGIN
  FOR e IN 
    SELECT t.typname
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typtype = 'e' AND n.nspname = 'public'
  LOOP
    func_eq1 := 'eq_' || e.typname || '_text';
    func_eq2 := 'eq_text_' || e.typname;
    func_neq1 := 'neq_' || e.typname || '_text';
    func_neq2 := 'neq_text_' || e.typname;
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a::text = b; $f$;', func_eq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a = b::text; $f$;', func_eq2, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a::text <> b; $f$;', func_neq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $f$ SELECT a <> b::text; $f$;', func_neq2, e.typname);
    EXECUTE format('DROP OPERATOR IF EXISTS public.= (public.%I, text)', e.typname);
    EXECUTE format('CREATE OPERATOR public.= (LEFTARG = public.%I, RIGHTARG = text, PROCEDURE = public.%I, COMMUTATOR = ''='')', e.typname, func_eq1);
    EXECUTE format('DROP OPERATOR IF EXISTS public.= (text, public.%I)', e.typname);
    EXECUTE format('CREATE OPERATOR public.= (LEFTARG = text, RIGHTARG = public.%I, PROCEDURE = public.%I, COMMUTATOR = ''='')', e.typname, func_eq2);
    EXECUTE format('DROP OPERATOR IF EXISTS public.<> (public.%I, text)', e.typname);
    EXECUTE format('CREATE OPERATOR public.<> (LEFTARG = public.%I, RIGHTARG = text, PROCEDURE = public.%I, COMMUTATOR = ''<>'')', e.typname, func_neq1);
    EXECUTE format('DROP OPERATOR IF EXISTS public.<> (text, public.%I)', e.typname);
    EXECUTE format('CREATE OPERATOR public.<> (LEFTARG = text, RIGHTARG = public.%I, PROCEDURE = public.%I, COMMUTATOR = ''<>'')', e.typname, func_neq2);
  END LOOP;
END $$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260605000000_fix_rpc_security_definer.sql
WITH ranked AS (
  SELECT
    id,
    user_id,
    role,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY CASE role
        WHEN 'admin'      THEN 1
        WHEN 'finance'    THEN 2
        WHEN 'hr'         THEN 3
        WHEN 'operations' THEN 4
        WHEN 'viewer'     THEN 5
        ELSE 99
      END
    ) AS rn
  FROM public.user_roles
)
DELETE FROM public.user_roles
WHERE id IN (
  SELECT id FROM ranked WHERE rn > 1
);
ALTER FUNCTION public.performance_dashboard_rpc(text, date)
  SECURITY DEFINER
  SET search_path = public;
ALTER FUNCTION public.rider_profile_performance_rpc(uuid, text, date)
  SECURITY DEFINER
  SET search_path = public;

-- FILE: 20260606000000_fix_ambiguous_column_references.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: ambiguous employee_id column reference in daily_shifts query (lint error 42702)';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS
  'Fixed: ambiguous employee_id column reference in daily_shifts query (lint error 42702)';
COMMENT ON FUNCTION public.preview_salary_for_month_v2(TEXT) IS
  'Fixed: removed unused variable c_days_per_month (lint warning)';

-- FILE: 20260606000001_fix_advance_due_date_and_unused_vars.sql
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: ai.due_date → ai.month_year (advance_installments has no due_date column)';
COMMENT ON FUNCTION public.preview_salary_for_month(TEXT) IS
  'Fixed: removed unused v_tier variable (lint warning)';

-- FILE: 20260606000002_fix_external_deductions_columns.sql
COMMENT ON FUNCTION public.calculate_employee_salary(UUID, TEXT, TEXT, NUMERIC, TEXT) IS
  'Fixed: external_deductions uses apply_month + approval_status (not month_year/status)';

-- FILE: 20260606000003_fix_enum_search_path_and_duplicate_indexes.sql
DO $$
DECLARE
  e record;
  func_eq1 text;
  func_eq2 text;
  func_neq1 text;
  func_neq2 text;
BEGIN
  FOR e IN
    SELECT t.typname
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typtype = 'e' AND n.nspname = 'public'
  LOOP
    func_eq1 := 'eq_' || e.typname || '_text';
    func_eq2 := 'eq_text_' || e.typname;
    func_neq1 := 'neq_' || e.typname || '_text';
    func_neq2 := 'neq_text_' || e.typname;
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a::text = b; $f$;', func_eq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a = b::text; $f$;', func_eq2, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a public.%I, b text) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a::text <> b; $f$;', func_neq1, e.typname);
    EXECUTE format('CREATE OR REPLACE FUNCTION public.%I(a text, b public.%I) RETURNS boolean LANGUAGE sql IMMUTABLE STRICT SET search_path = public AS $f$ SELECT a <> b::text; $f$;', func_neq2, e.typname);
  END LOOP;
END $$;
DROP INDEX IF EXISTS public.uq_attendance_employee_date;
DROP INDEX IF EXISTS public.salary_slip_templates_one_default_idx;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000004_fix_emp_status_search_path.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000006_consolidate_rls_policies.sql
﻿-- Migration to consolidate multiple permissive RLS policies
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000007_unified_rls_policies.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000009_index_foreign_keys.sql
CREATE INDEX IF NOT EXISTS "idx_salary_scheme_tiers_scheme_id" ON public."salary_scheme_tiers" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_employee_id" ON public."employee_scheme" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_scheme_id" ON public."employee_scheme" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_vehicle_id" ON public."vehicle_assignments" ("vehicle_id");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_employee_id" ON public."vehicle_assignments" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_vehicle_id" ON public."maintenance_logs_legacy_pre_fleet" ("vehicle_id");
CREATE INDEX IF NOT EXISTS "idx_advances_employee_id" ON public."advances" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_advance_id" ON public."advance_installments" ("advance_id");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_employee_id" ON public."external_deductions" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_source_app_id" ON public."external_deductions" ("source_app_id");
CREATE INDEX IF NOT EXISTS "idx_apps_scheme_id" ON public."apps" ("scheme_id");
CREATE INDEX IF NOT EXISTS "idx_positions_department_id" ON public."positions" ("department_id");
CREATE INDEX IF NOT EXISTS "idx_employees_department_id" ON public."employees" ("department_id");
CREATE INDEX IF NOT EXISTS "idx_employees_position_id" ON public."employees" ("position_id");
CREATE INDEX IF NOT EXISTS "idx_employee_tiers_employee_id" ON public."employee_tiers" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_scheme_assigned_by" ON public."employee_scheme" ("assigned_by");
CREATE INDEX IF NOT EXISTS "idx_vehicle_assignments_created_by" ON public."vehicle_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_platform_accounts_app_id" ON public."platform_accounts" ("app_id");
CREATE INDEX IF NOT EXISTS "idx_platform_accounts_employee_id" ON public."platform_accounts" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_employee_roles_assigned_by" ON public."employee_roles" ("assigned_by");
CREATE INDEX IF NOT EXISTS "idx_leave_requests_reviewer_id" ON public."leave_requests" ("reviewer_id");
CREATE INDEX IF NOT EXISTS "idx_leave_requests_created_by" ON public."leave_requests" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_attendance_created_by" ON public."attendance" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_daily_orders_created_by" ON public."daily_orders" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advances_approved_by" ON public."advances" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_approved_by" ON public."external_deductions" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_approved_by" ON public."salary_records" ("approved_by");
CREATE INDEX IF NOT EXISTS "idx_pl_records_created_by" ON public."pl_records" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_alerts_resolved_by" ON public."alerts" ("resolved_by");
CREATE INDEX IF NOT EXISTS "idx_audit_log_user_id" ON public."audit_log" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_admin_action_log_user_id" ON public."admin_action_log" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_employees_created_by" ON public."employees" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_employees_updated_by" ON public."employees" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_daily_orders_updated_by" ON public."daily_orders" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_attendance_updated_by" ON public."attendance" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_advances_created_by" ON public."advances" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advances_updated_by" ON public."advances" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_created_by" ON public."advance_installments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_advance_installments_updated_by" ON public."advance_installments" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_created_by" ON public."external_deductions" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_external_deductions_updated_by" ON public."external_deductions" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_created_by" ON public."salary_records" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_records_updated_by" ON public."salary_records" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_pl_records_updated_by" ON public."pl_records" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_user_roles_created_by" ON public."user_roles" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_user_roles_updated_by" ON public."user_roles" ("updated_by");
CREATE INDEX IF NOT EXISTS "idx_locked_months_locked_by" ON public."locked_months" ("locked_by");
CREATE INDEX IF NOT EXISTS "idx_supervisor_employee_assignments_created_by" ON public."supervisor_employee_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_supervisor_targets_created_by" ON public."supervisor_targets" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_slip_templates_created_by" ON public."salary_slip_templates" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_employee_id" ON public."maintenance_logs_legacy_pre_fleet" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_hr_performance_reviews_reviewer_id" ON public."hr_performance_reviews" ("reviewer_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_employee_id" ON public."maintenance_logs" ("employee_id");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_created_by" ON public."maintenance_logs" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_account_assignments_created_by" ON public."account_assignments" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_finance_transactions_created_by" ON public."finance_transactions" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_salary_month_snapshots_captured_by" ON public."salary_month_snapshots" ("captured_by");
CREATE INDEX IF NOT EXISTS "idx_employee_targets_created_by" ON public."employee_targets" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_order_import_batches_target_app_id" ON public."order_import_batches" ("target_app_id");
CREATE INDEX IF NOT EXISTS "idx_order_import_batches_started_by" ON public."order_import_batches" ("started_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");
CREATE INDEX IF NOT EXISTS "idx_maintenance_logs_legacy_pre_fleet_created_by" ON public."maintenance_logs_legacy_pre_fleet" ("created_by");

-- FILE: 20260606000012_fix_remaining_fkeys.sql
CREATE INDEX IF NOT EXISTS "idx_employee_apps_app_id" ON public."employee_apps" ("app_id");
CREATE INDEX IF NOT EXISTS "idx_salary_drafts_employee_id" ON public."salary_drafts" ("employee_id");

-- FILE: 20260606000013_restore_rls_security_definer.sql
ALTER FUNCTION public.has_role(_user_id uuid, _role app_role) SECURITY DEFINER;
ALTER FUNCTION public.get_my_role() SECURITY DEFINER;
ALTER FUNCTION public.has_permission(p_resource text, p_action text) SECURITY DEFINER;
ALTER FUNCTION public.is_internal_user() SECURITY DEFINER;
ALTER FUNCTION public.is_admin_or_hr(uid uuid) SECURITY DEFINER;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000014_fix_rls_performance_timeouts.sql
ALTER FUNCTION public.employee_in_my_company(_employee_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.advance_in_my_company(_advance_id uuid) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.is_active_user(_user_id uuid) SET search_path = public;
ALTER FUNCTION public.has_role(_user_id uuid, _role app_role) SET search_path = public;
ALTER FUNCTION public.get_my_role() SET search_path = public;
ALTER FUNCTION public.has_permission(p_resource text, p_action text) SET search_path = public;
ALTER FUNCTION public.is_internal_user() SET search_path = public;
ALTER FUNCTION public.is_admin_or_hr(uid uuid) SET search_path = public;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260606000015_fix_rpc_performance_timeouts.sql
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT p.oid::regprocedure::text AS func_signature
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname IN (
            'dashboard_overview_rpc',
            'dashboard_overview',
            'performance_dashboard_rpc',
            'rider_profile_performance_rpc',
            'preview_salary_for_month',
            'preview_salary_for_month_v2',
            'calculate_employee_salary',
            'calculate_order_salary_for_app',
            'calculate_salary',
            'calculate_salary_for_month',
            'capture_salary_month_snapshot',
            'assign_platform_account',
            'replace_daily_orders_month_rpc'
          )
    LOOP
        EXECUTE format('ALTER FUNCTION %s SECURITY DEFINER SET search_path = public;', rec.func_signature);
    END LOOP;
END
$$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628000003_fix_database_linter_warnings.sql
ALTER FUNCTION public.calc_tier_salary(integer, uuid) SET search_path = public;

-- FILE: 20260628000004_prioritize_app_scheme_over_pricing_rules.sql
BEGIN;
COMMIT;

-- FILE: 20260628000005_fix_preview_salary_for_month_to_use_app_salary.sql
BEGIN;
DROP FUNCTION IF EXISTS public.preview_salary_for_month(text);
DROP FUNCTION IF EXISTS public.calculate_salary_for_employee_month(UUID, TEXT, TEXT, NUMERIC, TEXT);
COMMIT;

-- FILE: 20260628000006_fix_recursive_role_const_functions.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628130000_fix_rls_policies_with_constants.sql
NOTIFY pgrst, 'reload schema';

-- FILE: 20260628135000_add_performance_indexes.sql
CREATE INDEX IF NOT EXISTS idx_employees_name ON public.employees(name);
CREATE INDEX IF NOT EXISTS idx_daily_orders_date ON public.daily_orders(date);

-- FILE: 20260628170000_fix_performance_dashboard_rpc_500.sql
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260629171000_restore_performance_dashboard_rpc_real.sql
NOTIFY pgrst, 'reload schema';
