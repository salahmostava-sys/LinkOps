-- ================================================================
-- Full Schema Dump: public schema
-- Host: aws-1-ap-south-1.pooler.supabase.com
-- Generated: 2026-07-08T19:05:16.139Z
-- ================================================================

-- ================================================================
-- ENUMS
-- ================================================================
CREATE TYPE public.advance_status AS ENUM (
  'active',
  'completed',
  'paused'
);

CREATE TYPE public.app_role AS ENUM (
  'admin',
  'hr',
  'finance',
  'operations',
  'viewer'
);

CREATE TYPE public.approval_status AS ENUM (
  'pending',
  'approved',
  'rejected'
);

CREATE TYPE public.attendance_status AS ENUM (
  'present',
  'absent',
  'leave',
  'sick',
  'late'
);

CREATE TYPE public.city_enum AS ENUM (
  'makkah',
  'jeddah'
);

CREATE TYPE public.deduction_type AS ENUM (
  'fine',
  'return',
  'delay',
  'accident',
  'other'
);

CREATE TYPE public.employee_status AS ENUM (
  'active',
  'inactive',
  'ended'
);

CREATE TYPE public.installment_status AS ENUM (
  'pending',
  'deducted',
  'deferred'
);

CREATE TYPE public.license_status_enum AS ENUM (
  'has_license',
  'no_license',
  'applied'
);

CREATE TYPE public.maintenance_type AS ENUM (
  'routine',
  'breakdown',
  'accident'
);

CREATE TYPE public.salary_type AS ENUM (
  'shift',
  'orders'
);

CREATE TYPE public.scheme_status AS ENUM (
  'active',
  'archived'
);

CREATE TYPE public.sponsorship_status_enum AS ENUM (
  'sponsored',
  'not_sponsored',
  'absconded',
  'terminated'
);

CREATE TYPE public.vehicle_status AS ENUM (
  'active',
  'maintenance',
  'inactive',
  'breakdown',
  'rental',
  'ended'
);

CREATE TYPE public.vehicle_type AS ENUM (
  'motorcycle',
  'car'
);

-- ================================================================
-- TABLES
-- ================================================================
CREATE TABLE IF NOT EXISTS public."account_assignments" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "account_id" uuid NOT NULL,
    "employee_id" uuid NOT NULL,
    "start_date" date NOT NULL,
    "end_date" date,
    "month_year" text NOT NULL,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."admin_action_log" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "user_id" uuid,
    "action" text NOT NULL,
    "table_name" text,
    "record_id" text,
    "meta" jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public."advance_installments" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "advance_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "status" installment_status NOT NULL DEFAULT 'pending'::installment_status,
    "deducted_at" timestamp with time zone,
    "notes" text,
    "created_by" uuid,
    "updated_by" uuid
);

CREATE TABLE IF NOT EXISTS public."advances" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "disbursement_date" date NOT NULL DEFAULT CURRENT_DATE,
    "total_installments" integer NOT NULL DEFAULT 1,
    "monthly_amount" numeric(10,2) NOT NULL,
    "first_deduction_month" text NOT NULL,
    "note" text,
    "status" advance_status NOT NULL DEFAULT 'active'::advance_status,
    "approved_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "is_written_off" boolean NOT NULL DEFAULT false,
    "written_off_at" timestamp with time zone,
    "written_off_reason" text,
    "created_by" uuid,
    "updated_by" uuid,
    "attachment_url" text
);

CREATE TABLE IF NOT EXISTS public."alerts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "type" text NOT NULL,
    "entity_id" uuid,
    "entity_type" text,
    "due_date" date,
    "is_resolved" boolean NOT NULL DEFAULT false,
    "resolved_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "message" text,
    "details" jsonb
);

CREATE TABLE IF NOT EXISTS public."app_hybrid_rules" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "app_id" uuid NOT NULL,
    "min_hours_for_shift" numeric(4,2) NOT NULL,
    "shift_rate" numeric(10,2) NOT NULL,
    "fallback_to_orders" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."app_targets" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "app_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "target_orders" integer NOT NULL DEFAULT 0,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "employee_target_orders" integer
);

CREATE TABLE IF NOT EXISTS public."apps" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "logo_url" text,
    "is_active" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "brand_color" text NOT NULL DEFAULT '#6366f1'::text,
    "text_color" text NOT NULL DEFAULT '#ffffff'::text,
    "scheme_id" uuid,
    "custom_columns" jsonb DEFAULT '[]'::jsonb,
    "work_type" text DEFAULT 'orders'::text,
    "is_archived" boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public."attendance" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "date" date NOT NULL,
    "status" attendance_status NOT NULL DEFAULT 'present'::attendance_status,
    "check_in" time without time zone,
    "check_out" time without time zone,
    "note" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "total_hours" numeric(6,2),
    "late" boolean NOT NULL DEFAULT false,
    "early_leave" boolean NOT NULL DEFAULT false,
    "updated_by" uuid
);

CREATE TABLE IF NOT EXISTS public."attendance_status_configs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "color" text NOT NULL DEFAULT '#6366f1'::text,
    "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."audit_log" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid,
    "action" text NOT NULL,
    "table_name" text NOT NULL,
    "record_id" uuid,
    "old_value" jsonb,
    "new_value" jsonb,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."commercial_records" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."daily_orders" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "date" date NOT NULL,
    "app_id" uuid NOT NULL,
    "orders_count" integer NOT NULL DEFAULT 0,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "status" text NOT NULL DEFAULT 'confirmed'::text,
    "source" text NOT NULL DEFAULT 'manual'::text,
    "updated_by" uuid,
    "import_batch_id" uuid
);

CREATE TABLE IF NOT EXISTS public."daily_shifts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "app_id" uuid NOT NULL,
    "date" date NOT NULL,
    "hours_worked" numeric(4,2) NOT NULL,
    "notes" text,
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."departments" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "description" text,
    "manager_id" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."edge_rate_limits" (
    "key" text NOT NULL,
    "window_start" timestamp with time zone NOT NULL,
    "request_count" integer NOT NULL DEFAULT 0,
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."employee_apps" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "app_id" uuid NOT NULL,
    "username" text,
    "status" text NOT NULL DEFAULT 'active'::text,
    "joined_date" date
);

CREATE TABLE IF NOT EXISTS public."employee_roles" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "role_id" uuid NOT NULL,
    "assigned_at" timestamp with time zone NOT NULL DEFAULT now(),
    "assigned_by" uuid,
    "is_primary" boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public."employee_scheme" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "scheme_id" uuid NOT NULL,
    "assigned_date" date NOT NULL DEFAULT CURRENT_DATE,
    "assigned_by" uuid
);

CREATE TABLE IF NOT EXISTS public."employee_targets" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "monthly_target_orders" integer NOT NULL DEFAULT 0,
    "daily_target_orders" integer NOT NULL DEFAULT 0,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."employee_tiers" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "package_type" text NOT NULL DEFAULT 'شريحة أساسية'::text,
    "start_date" date NOT NULL DEFAULT CURRENT_DATE,
    "renewal_date" date NOT NULL,
    "delivery_status" text NOT NULL DEFAULT 'pending'::text,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "sim_number" text,
    "app_ids" jsonb NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS public."employee_wallet_transactions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "transaction_type" text NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "transaction_date" date NOT NULL DEFAULT CURRENT_DATE,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."employees" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "phone" text,
    "national_id" text,
    "iban" text,
    "is_sponsored" boolean NOT NULL DEFAULT false,
    "dob" date,
    "residency_expiry" date,
    "license_has" boolean NOT NULL DEFAULT false,
    "license_expiry" date,
    "email" text,
    "salary_type" salary_type NOT NULL DEFAULT 'orders'::salary_type,
    "base_salary" numeric(10,2) NOT NULL DEFAULT 0,
    "allowances" jsonb DEFAULT '{}'::jsonb,
    "status" employee_status NOT NULL DEFAULT 'active'::employee_status,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "job_title" text,
    "bank_account_number" text,
    "city" text,
    "join_date" date,
    "license_status" license_status_enum DEFAULT 'no_license'::license_status_enum,
    "sponsorship_status" sponsorship_status_enum DEFAULT 'not_sponsored'::sponsorship_status_enum,
    "id_photo_url" text,
    "license_photo_url" text,
    "personal_photo_url" text,
    "preferred_language" text NOT NULL DEFAULT 'ar'::text,
    "nationality" text,
    "birth_date" date,
    "department_id" uuid,
    "position_id" uuid,
    "probation_end_date" date,
    "health_insurance_expiry" date,
    "role_id" uuid,
    "created_by" uuid,
    "updated_by" uuid,
    "commercial_record" text,
    "cities" text[] DEFAULT '{}'::text[],
    "iqama_photo_url" text
);

CREATE TABLE IF NOT EXISTS public."external_deductions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "source_app_id" uuid,
    "type" deduction_type NOT NULL DEFAULT 'fine'::deduction_type,
    "amount" numeric(10,2) NOT NULL,
    "incident_date" date,
    "apply_month" text NOT NULL,
    "approval_status" approval_status NOT NULL DEFAULT 'pending'::approval_status,
    "note" text,
    "approved_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "linked_advance_id" uuid,
    "created_by" uuid,
    "updated_by" uuid
);

CREATE TABLE IF NOT EXISTS public."finance_transactions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "type" text NOT NULL,
    "category" text NOT NULL,
    "description" text,
    "amount" numeric(12,2) NOT NULL,
    "month_year" text NOT NULL,
    "date" date NOT NULL DEFAULT CURRENT_DATE,
    "is_auto" boolean NOT NULL DEFAULT false,
    "reference_type" text,
    "reference_id" uuid,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."hr_performance_reviews" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "reviewer_id" uuid,
    "attendance_score" integer NOT NULL DEFAULT 5,
    "performance_score" integer NOT NULL DEFAULT 5,
    "behavior_score" integer NOT NULL DEFAULT 5,
    "commitment_score" integer NOT NULL DEFAULT 5,
    "notes" text,
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."leave_requests" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "type" text NOT NULL,
    "start_date" date NOT NULL,
    "end_date" date NOT NULL,
    "days_count" integer NOT NULL,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "reason" text,
    "reviewer_id" uuid,
    "review_note" text,
    "reviewed_at" timestamp with time zone,
    "created_by" uuid,
    "created_at" timestamp with time zone DEFAULT now(),
    "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."locked_months" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "month_year" text NOT NULL,
    "locked_at" timestamp with time zone NOT NULL DEFAULT now(),
    "locked_by" uuid
);

CREATE TABLE IF NOT EXISTS public."maintenance_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "vehicle_id" uuid NOT NULL,
    "employee_id" uuid,
    "maintenance_date" date NOT NULL DEFAULT CURRENT_DATE,
    "type" text NOT NULL,
    "odometer_reading" numeric(10,0),
    "total_cost" numeric(10,2) NOT NULL DEFAULT 0,
    "status" text NOT NULL DEFAULT 'مكتملة'::text,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."maintenance_logs_legacy_pre_fleet" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "vehicle_id" uuid NOT NULL,
    "type" text NOT NULL DEFAULT 'routine'::maintenance_type,
    "description" text,
    "cost" numeric(10,2) DEFAULT 0,
    "paid_by" text DEFAULT 'company'::text,
    "date" date NOT NULL DEFAULT CURRENT_DATE,
    "status" text DEFAULT 'completed'::text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "employee_id" uuid,
    "maintenance_date" date NOT NULL,
    "odometer_reading" numeric(10,0),
    "total_cost" numeric(10,2) NOT NULL DEFAULT 0,
    "notes" text,
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."maintenance_parts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "maintenance_log_id" uuid NOT NULL,
    "part_id" uuid NOT NULL,
    "quantity_used" numeric(10,2) NOT NULL,
    "cost_at_time" numeric(10,2) NOT NULL DEFAULT 0,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."order_import_batches" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "month_year" text NOT NULL,
    "source_type" text NOT NULL DEFAULT 'manual'::text,
    "file_name" text,
    "target_app_id" uuid,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "total_rows" integer NOT NULL DEFAULT 0,
    "imported_rows" integer NOT NULL DEFAULT 0,
    "skipped_rows" integer NOT NULL DEFAULT 0,
    "error_count" integer NOT NULL DEFAULT 0,
    "error_summary" jsonb NOT NULL DEFAULT '[]'::jsonb,
    "meta" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "started_by" uuid,
    "started_at" timestamp with time zone NOT NULL DEFAULT now(),
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."pl_records" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "month_year" text NOT NULL,
    "revenue_riders" numeric(10,2) NOT NULL DEFAULT 0,
    "revenue_other" numeric(10,2) NOT NULL DEFAULT 0,
    "cost_salaries" numeric(10,2) NOT NULL DEFAULT 0,
    "cost_vehicles" numeric(10,2) NOT NULL DEFAULT 0,
    "cost_deductions" numeric(10,2) NOT NULL DEFAULT 0,
    "cost_other" numeric(10,2) NOT NULL DEFAULT 0,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_by" uuid
);

CREATE TABLE IF NOT EXISTS public."platform_accounts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "app_id" uuid NOT NULL,
    "account_username" text NOT NULL,
    "account_id_on_platform" text,
    "iqama_number" text,
    "iqama_expiry_date" date,
    "status" text NOT NULL DEFAULT 'active'::text,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "employee_id" uuid
);

CREATE TABLE IF NOT EXISTS public."positions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "department_id" uuid,
    "description" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."pricing_rules" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "app_id" uuid NOT NULL,
    "min_orders" integer NOT NULL DEFAULT 0,
    "max_orders" integer,
    "rule_type" text NOT NULL DEFAULT 'per_order'::text,
    "rate_per_order" numeric(10,2),
    "fixed_salary" numeric(10,2),
    "bonus_target_orders" integer,
    "bonus_amount" numeric(10,2),
    "is_active" boolean NOT NULL DEFAULT true,
    "priority" integer NOT NULL DEFAULT 0,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."profiles" (
    "id" uuid NOT NULL,
    "email" text,
    "name" text,
    "name_en" text,
    "is_active" boolean NOT NULL DEFAULT false,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "avatar_url" text
);

CREATE TABLE IF NOT EXISTS public."roles" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "title" text NOT NULL,
    "permissions" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "is_active" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."salary_drafts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "employee_id" uuid NOT NULL,
    "draft_data" jsonb NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."salary_month_snapshots" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "month_year" text NOT NULL,
    "snapshot" jsonb NOT NULL DEFAULT '[]'::jsonb,
    "summary" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "captured_by" uuid,
    "captured_at" timestamp with time zone NOT NULL DEFAULT now(),
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."salary_records" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "base_salary" numeric(10,2) NOT NULL DEFAULT 0,
    "allowances" numeric(10,2) NOT NULL DEFAULT 0,
    "attendance_deduction" numeric(10,2) NOT NULL DEFAULT 0,
    "advance_deduction" numeric(10,2) NOT NULL DEFAULT 0,
    "external_deduction" numeric(10,2) NOT NULL DEFAULT 0,
    "manual_deduction" numeric(10,2) NOT NULL DEFAULT 0,
    "manual_deduction_note" text,
    "net_salary" numeric(10,2) NOT NULL DEFAULT 0,
    "is_approved" boolean NOT NULL DEFAULT false,
    "approved_by" uuid,
    "approved_at" timestamp with time zone,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "payment_method" text NOT NULL DEFAULT 'cash'::text,
    "calc_status" text NOT NULL DEFAULT 'calculated'::text,
    "calc_source" text NOT NULL DEFAULT 'engine_v1'::text,
    "created_by" uuid,
    "updated_by" uuid,
    "version" integer NOT NULL DEFAULT 1,
    "sheet_snapshot" jsonb
);

CREATE TABLE IF NOT EXISTS public."salary_scheme_tiers" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "scheme_id" uuid NOT NULL,
    "tier_order" integer NOT NULL DEFAULT 1,
    "from_orders" integer NOT NULL DEFAULT 0,
    "to_orders" integer,
    "price_per_order" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "tier_type" text NOT NULL DEFAULT 'total_multiplier'::text,
    "incremental_threshold" integer,
    "incremental_price" numeric
);

CREATE TABLE IF NOT EXISTS public."salary_schemes" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "target_orders" integer,
    "target_bonus" numeric(10,2),
    "status" scheme_status NOT NULL DEFAULT 'active'::scheme_status,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "scheme_type" text NOT NULL DEFAULT 'order_based'::text,
    "monthly_amount" numeric
);

CREATE TABLE IF NOT EXISTS public."salary_slip_templates" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "is_default" boolean NOT NULL DEFAULT false,
    "template_json" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "header_html" text,
    "footer_html" text,
    "selected_columns" jsonb DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS public."salary_tiers" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "app_id" uuid NOT NULL,
    "min_orders" integer NOT NULL DEFAULT 0,
    "max_orders" integer,
    "tier_type" text NOT NULL DEFAULT 'per_order'::text,
    "rate_per_order" numeric(10,2),
    "fixed_amount" numeric(10,2),
    "extra_rate" numeric(10,2),
    "priority" integer NOT NULL DEFAULT 0,
    "is_active" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."scheme_month_snapshots" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "scheme_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "snapshot" jsonb NOT NULL DEFAULT '[]'::jsonb,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."spare_parts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name_ar" text NOT NULL,
    "part_number" text,
    "stock_quantity" numeric(10,2) NOT NULL DEFAULT 0,
    "min_stock_alert" numeric(10,2) DEFAULT 5,
    "unit" text DEFAULT 'قطعة'::text,
    "unit_cost" numeric(10,2) NOT NULL DEFAULT 0,
    "supplier" text,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "invoice_number" text,
    "invoice_date" date,
    "invoice_attachment_url" text
);

CREATE TABLE IF NOT EXISTS public."supervisor_employee_assignments" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "supervisor_id" uuid NOT NULL,
    "employee_id" uuid NOT NULL,
    "start_date" date NOT NULL DEFAULT CURRENT_DATE,
    "end_date" date,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."system_settings" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "project_name_ar" text NOT NULL DEFAULT 'مهمة التوصيل'::text,
    "project_name_en" text NOT NULL DEFAULT 'Muhimmat alTawseel'::text,
    "project_subtitle_ar" text NOT NULL DEFAULT 'إدارة المناديب'::text,
    "project_subtitle_en" text NOT NULL DEFAULT 'Rider Management'::text,
    "logo_url" text,
    "default_language" text NOT NULL DEFAULT 'ar'::text,
    "theme" text NOT NULL DEFAULT 'light'::text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "iqama_alert_days" integer NOT NULL DEFAULT 90
);

CREATE TABLE IF NOT EXISTS public."trade_registers" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "name_en" text,
    "cr_number" text,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."treasury_accounts" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "type" text NOT NULL,
    "initial_balance" numeric(12,2) NOT NULL DEFAULT 0,
    "is_active" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."treasury_categories" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "type" text NOT NULL,
    "is_active" boolean NOT NULL DEFAULT true,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."treasury_transactions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "transaction_date" date NOT NULL DEFAULT CURRENT_DATE,
    "account_id" uuid NOT NULL,
    "category_id" uuid,
    "type" text NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "description" text,
    "attachment_url" text,
    "transfer_to_account_id" uuid,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "app_id" uuid
);

CREATE TABLE IF NOT EXISTS public."user_permissions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "permission_key" text NOT NULL,
    "can_view" boolean NOT NULL DEFAULT false,
    "can_edit" boolean NOT NULL DEFAULT false,
    "can_delete" boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public."user_roles" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "role" app_role NOT NULL,
    "role_id" uuid,
    "created_by" uuid,
    "updated_by" uuid
);

CREATE TABLE IF NOT EXISTS public."vehicle_assignments" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "vehicle_id" uuid NOT NULL,
    "employee_id" uuid NOT NULL,
    "start_date" date NOT NULL DEFAULT CURRENT_DATE,
    "end_date" date,
    "reason" text,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "returned_at" timestamp with time zone,
    "start_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."vehicle_documents" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "vehicle_id" uuid NOT NULL,
    "doc_type" text NOT NULL DEFAULT 'other'::text,
    "title" text,
    "file_path" text NOT NULL,
    "file_name" text NOT NULL,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."vehicle_mileage" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "month_year" text NOT NULL,
    "km_total" numeric NOT NULL DEFAULT 0,
    "fuel_cost" numeric NOT NULL DEFAULT 0,
    "cost_per_km" numeric DEFAULT 
CASE
    WHEN (km_total > (0)::numeric) THEN (fuel_cost / km_total)
    ELSE NULL::numeric
END,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."vehicle_mileage_daily" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "employee_id" uuid NOT NULL,
    "date" date NOT NULL,
    "km_total" numeric NOT NULL DEFAULT 0,
    "fuel_cost" numeric NOT NULL DEFAULT 0,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."vehicles" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "plate_number" text NOT NULL,
    "type" vehicle_type NOT NULL DEFAULT 'motorcycle'::vehicle_type,
    "brand" text,
    "model" text,
    "year" integer,
    "insurance_expiry" date,
    "registration_expiry" date,
    "status" vehicle_status NOT NULL DEFAULT 'active'::vehicle_status,
    "notes" text,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "authorization_expiry" date,
    "plate_number_en" text,
    "chassis_number" text,
    "serial_number" text,
    "has_fuel_chip" boolean NOT NULL DEFAULT false
);

-- ================================================================
-- FOREIGN KEYS
-- ================================================================

-- ================================================================
-- INDEXES
-- ================================================================
CREATE INDEX idx_account_assignments_account_id ON public.account_assignments USING btree (account_id);
CREATE INDEX idx_account_assignments_created_by ON public.account_assignments USING btree (created_by);
CREATE INDEX idx_account_assignments_employee_id ON public.account_assignments USING btree (employee_id);
CREATE INDEX idx_account_assignments_open ON public.account_assignments USING btree (end_date) WHERE (end_date IS NULL);
CREATE INDEX idx_admin_action_log_created_at ON public.admin_action_log USING btree (created_at DESC);
CREATE INDEX idx_admin_action_log_table_record ON public.admin_action_log USING btree (table_name, record_id);
CREATE INDEX idx_admin_action_log_user_id ON public.admin_action_log USING btree (user_id);
CREATE INDEX idx_advance_installments_advance_id ON public.advance_installments USING btree (advance_id);
CREATE INDEX idx_advance_installments_created_by ON public.advance_installments USING btree (created_by);
CREATE INDEX idx_advance_installments_updated_by ON public.advance_installments USING btree (updated_by);
CREATE INDEX idx_advances_approved_by ON public.advances USING btree (approved_by);
CREATE INDEX idx_advances_created_by ON public.advances USING btree (created_by);
CREATE INDEX idx_advances_employee_id ON public.advances USING btree (employee_id);
CREATE INDEX idx_advances_updated_by ON public.advances USING btree (updated_by);
CREATE INDEX idx_alerts_resolved_by ON public.alerts USING btree (resolved_by);
CREATE UNIQUE INDEX app_hybrid_rules_app_id_key ON public.app_hybrid_rules USING btree (app_id);
CREATE UNIQUE INDEX app_targets_app_id_month_year_key ON public.app_targets USING btree (app_id, month_year);
CREATE INDEX idx_apps_is_archived ON public.apps USING btree (is_archived);
CREATE INDEX idx_apps_scheme_id ON public.apps USING btree (scheme_id);
CREATE UNIQUE INDEX attendance_employee_id_date_key ON public.attendance USING btree (employee_id, date);
CREATE INDEX idx_attendance_created_by ON public.attendance USING btree (created_by);
CREATE INDEX idx_attendance_employee_date_early_leave ON public.attendance USING btree (employee_id, date, early_leave);
CREATE INDEX idx_attendance_employee_date_late ON public.attendance USING btree (employee_id, date, late);
CREATE INDEX idx_attendance_employee_status_date ON public.attendance USING btree (employee_id, status, date);
CREATE INDEX idx_attendance_updated_by ON public.attendance USING btree (updated_by);
CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);
CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at DESC);
CREATE INDEX idx_audit_log_table_name ON public.audit_log USING btree (table_name);
CREATE INDEX idx_audit_log_user_id ON public.audit_log USING btree (user_id);
CREATE UNIQUE INDEX idx_commercial_records_name_ci ON public.commercial_records USING btree (lower(btrim(name)));
CREATE UNIQUE INDEX daily_orders_employee_id_date_app_id_key ON public.daily_orders USING btree (employee_id, date, app_id);
CREATE INDEX idx_daily_orders_app_date ON public.daily_orders USING btree (app_id, date);
CREATE INDEX idx_daily_orders_created_by ON public.daily_orders USING btree (created_by);
CREATE INDEX idx_daily_orders_date ON public.daily_orders USING btree (date);
CREATE INDEX idx_daily_orders_employee_date ON public.daily_orders USING btree (employee_id, date);
CREATE INDEX idx_daily_orders_import_batch_id ON public.daily_orders USING btree (import_batch_id);
CREATE INDEX idx_daily_orders_perf_date_employee ON public.daily_orders USING btree (date, employee_id, app_id) WHERE (orders_count > 0);
CREATE INDEX idx_daily_orders_perf_employee_date ON public.daily_orders USING btree (employee_id, date) WHERE (orders_count > 0);
CREATE INDEX idx_daily_orders_status ON public.daily_orders USING btree (status);
CREATE INDEX idx_daily_orders_updated_by ON public.daily_orders USING btree (updated_by);
CREATE UNIQUE INDEX daily_shifts_unique_employee_app_date ON public.daily_shifts USING btree (employee_id, app_id, date);
CREATE INDEX idx_daily_shifts_app_date ON public.daily_shifts USING btree (app_id, date);
CREATE INDEX idx_daily_shifts_date ON public.daily_shifts USING btree (date);
CREATE INDEX idx_daily_shifts_employee_date ON public.daily_shifts USING btree (employee_id, date);
CREATE UNIQUE INDEX employee_apps_employee_id_app_id_key ON public.employee_apps USING btree (employee_id, app_id);
CREATE INDEX idx_employee_apps_app_id ON public.employee_apps USING btree (app_id);
CREATE UNIQUE INDEX employee_roles_employee_id_role_id_key ON public.employee_roles USING btree (employee_id, role_id);
CREATE INDEX idx_employee_roles_assigned_by ON public.employee_roles USING btree (assigned_by);
CREATE INDEX idx_employee_roles_employee ON public.employee_roles USING btree (employee_id);
CREATE INDEX idx_employee_roles_role ON public.employee_roles USING btree (role_id);
CREATE INDEX idx_employee_scheme_assigned_by ON public.employee_scheme USING btree (assigned_by);
CREATE INDEX idx_employee_scheme_employee_id ON public.employee_scheme USING btree (employee_id);
CREATE INDEX idx_employee_scheme_scheme_id ON public.employee_scheme USING btree (scheme_id);
CREATE UNIQUE INDEX employee_targets_employee_id_month_year_key ON public.employee_targets USING btree (employee_id, month_year);
CREATE INDEX idx_employee_targets_created_by ON public.employee_targets USING btree (created_by);
CREATE INDEX idx_employee_targets_employee_month ON public.employee_targets USING btree (employee_id, month_year);
CREATE INDEX idx_employee_targets_month ON public.employee_targets USING btree (month_year);
CREATE INDEX idx_employee_tiers_employee_id ON public.employee_tiers USING btree (employee_id);
CREATE UNIQUE INDEX employees_national_id_key ON public.employees USING btree (national_id);
CREATE INDEX idx_employees_commercial_record ON public.employees USING btree (commercial_record) WHERE (commercial_record IS NOT NULL);
CREATE INDEX idx_employees_created_by ON public.employees USING btree (created_by);
CREATE INDEX idx_employees_department_id ON public.employees USING btree (department_id);
CREATE INDEX idx_employees_name ON public.employees USING btree (name);
CREATE INDEX idx_employees_position_id ON public.employees USING btree (position_id);
CREATE INDEX idx_employees_residency_expiry ON public.employees USING btree (residency_expiry) WHERE (residency_expiry IS NOT NULL);
CREATE INDEX idx_employees_role_id ON public.employees USING btree (role_id);
CREATE INDEX idx_employees_updated_by ON public.employees USING btree (updated_by);
CREATE INDEX idx_external_deductions_approved_by ON public.external_deductions USING btree (approved_by);
CREATE INDEX idx_external_deductions_created_by ON public.external_deductions USING btree (created_by);
CREATE INDEX idx_external_deductions_employee_id ON public.external_deductions USING btree (employee_id);
CREATE INDEX idx_external_deductions_linked_advance_id ON public.external_deductions USING btree (linked_advance_id) WHERE (linked_advance_id IS NOT NULL);
CREATE INDEX idx_external_deductions_source_app_id ON public.external_deductions USING btree (source_app_id);
CREATE INDEX idx_external_deductions_updated_by ON public.external_deductions USING btree (updated_by);
CREATE INDEX idx_finance_transactions_created_by ON public.finance_transactions USING btree (created_by);
CREATE INDEX idx_finance_transactions_date ON public.finance_transactions USING btree (date);
CREATE INDEX idx_finance_transactions_month ON public.finance_transactions USING btree (month_year);
CREATE INDEX idx_finance_transactions_type ON public.finance_transactions USING btree (type);
CREATE UNIQUE INDEX uniq_finance_tx_auto_month_reference ON public.finance_transactions USING btree (month_year, reference_type) WHERE (is_auto IS TRUE);
CREATE UNIQUE INDEX hr_reviews_unique_employee_month ON public.hr_performance_reviews USING btree (employee_id, month_year);
CREATE INDEX idx_hr_performance_reviews_reviewer_id ON public.hr_performance_reviews USING btree (reviewer_id);
CREATE INDEX idx_hr_reviews_employee ON public.hr_performance_reviews USING btree (employee_id);
CREATE INDEX idx_hr_reviews_month ON public.hr_performance_reviews USING btree (month_year);
CREATE INDEX idx_leave_requests_created_by ON public.leave_requests USING btree (created_by);
CREATE INDEX idx_leave_requests_employee ON public.leave_requests USING btree (employee_id);
CREATE INDEX idx_leave_requests_reviewer_id ON public.leave_requests USING btree (reviewer_id);
CREATE INDEX idx_leave_requests_start_date ON public.leave_requests USING btree (start_date DESC);
CREATE INDEX idx_leave_requests_status ON public.leave_requests USING btree (status);
CREATE INDEX idx_leave_requests_type ON public.leave_requests USING btree (type);
CREATE INDEX idx_locked_months_locked_by ON public.locked_months USING btree (locked_by);
CREATE UNIQUE INDEX locked_months_month_year_key ON public.locked_months USING btree (month_year);
CREATE INDEX idx_maintenance_logs_created_by ON public.maintenance_logs USING btree (created_by);
CREATE INDEX idx_maintenance_logs_employee_id ON public.maintenance_logs USING btree (employee_id);
CREATE INDEX idx_maintenance_logs_maintenance_date ON public.maintenance_logs USING btree (maintenance_date DESC);
CREATE INDEX idx_maintenance_logs_vehicle_id ON public.maintenance_logs USING btree (vehicle_id);
CREATE UNIQUE INDEX maintenance_logs_pkey1 ON public.maintenance_logs USING btree (id);
CREATE INDEX idx_maintenance_logs_legacy_pre_fleet_created_by ON public.maintenance_logs_legacy_pre_fleet USING btree (created_by);
CREATE INDEX idx_maintenance_logs_legacy_pre_fleet_employee_id ON public.maintenance_logs_legacy_pre_fleet USING btree (employee_id);
CREATE INDEX idx_maintenance_logs_legacy_pre_fleet_vehicle_id ON public.maintenance_logs_legacy_pre_fleet USING btree (vehicle_id);
CREATE INDEX idx_maintenance_parts_log_id ON public.maintenance_parts USING btree (maintenance_log_id);
CREATE INDEX idx_maintenance_parts_part_id ON public.maintenance_parts USING btree (part_id);
CREATE UNIQUE INDEX maintenance_parts_unique_log_part ON public.maintenance_parts USING btree (maintenance_log_id, part_id);
CREATE INDEX idx_order_import_batches_month_year ON public.order_import_batches USING btree (month_year, started_at DESC);
CREATE INDEX idx_order_import_batches_started_by ON public.order_import_batches USING btree (started_by);
CREATE INDEX idx_order_import_batches_status ON public.order_import_batches USING btree (status);
CREATE INDEX idx_order_import_batches_target_app_id ON public.order_import_batches USING btree (target_app_id);
CREATE INDEX idx_pl_records_created_by ON public.pl_records USING btree (created_by);
CREATE INDEX idx_pl_records_updated_by ON public.pl_records USING btree (updated_by);
CREATE UNIQUE INDEX pl_records_month_year_key ON public.pl_records USING btree (month_year);
CREATE INDEX idx_platform_accounts_app_id ON public.platform_accounts USING btree (app_id);
CREATE INDEX idx_platform_accounts_employee_id ON public.platform_accounts USING btree (employee_id);
CREATE INDEX idx_positions_department_id ON public.positions USING btree (department_id);
CREATE INDEX idx_pricing_rules_active_priority ON public.pricing_rules USING btree (is_active, priority DESC);
CREATE INDEX idx_pricing_rules_app_id ON public.pricing_rules USING btree (app_id);
CREATE UNIQUE INDEX roles_title_key ON public.roles USING btree (title);
CREATE INDEX idx_salary_drafts_employee_id ON public.salary_drafts USING btree (employee_id);
CREATE INDEX idx_salary_drafts_user_month ON public.salary_drafts USING btree (user_id, month_year);
CREATE UNIQUE INDEX salary_drafts_user_id_month_year_employee_id_key ON public.salary_drafts USING btree (user_id, month_year, employee_id);
CREATE INDEX idx_salary_month_snapshots_captured_by ON public.salary_month_snapshots USING btree (captured_by);
CREATE INDEX idx_salary_month_snapshots_month ON public.salary_month_snapshots USING btree (month_year);
CREATE UNIQUE INDEX salary_month_snapshots_month_year_key ON public.salary_month_snapshots USING btree (month_year);
CREATE INDEX idx_salary_records_approved_by ON public.salary_records USING btree (approved_by);
CREATE INDEX idx_salary_records_calc_status ON public.salary_records USING btree (calc_status);
CREATE INDEX idx_salary_records_created_by ON public.salary_records USING btree (created_by);
CREATE INDEX idx_salary_records_employee_month ON public.salary_records USING btree (employee_id, month_year);
CREATE INDEX idx_salary_records_month_employee ON public.salary_records USING btree (month_year, employee_id);
CREATE INDEX idx_salary_records_updated_by ON public.salary_records USING btree (updated_by);
CREATE UNIQUE INDEX salary_records_employee_id_month_year_key ON public.salary_records USING btree (employee_id, month_year);
CREATE INDEX idx_salary_scheme_tiers_scheme_id ON public.salary_scheme_tiers USING btree (scheme_id);
CREATE INDEX idx_salary_slip_templates_created_by ON public.salary_slip_templates USING btree (created_by);
CREATE UNIQUE INDEX idx_salary_slip_templates_single_default ON public.salary_slip_templates USING btree (is_default) WHERE (is_default = true);
CREATE INDEX idx_salary_tiers_app_priority ON public.salary_tiers USING btree (app_id, is_active, priority DESC);
CREATE UNIQUE INDEX scheme_month_snapshots_scheme_id_month_year_key ON public.scheme_month_snapshots USING btree (scheme_id, month_year);
CREATE INDEX idx_supervisor_employee_assignments_created_by ON public.supervisor_employee_assignments USING btree (created_by);
CREATE INDEX idx_supervisor_employee_assignments_employee ON public.supervisor_employee_assignments USING btree (employee_id, start_date DESC);
CREATE INDEX idx_supervisor_employee_assignments_supervisor ON public.supervisor_employee_assignments USING btree (supervisor_id, start_date DESC);
CREATE UNIQUE INDEX supervisor_employee_assignments_unique_open ON public.supervisor_employee_assignments USING btree (supervisor_id, employee_id, start_date);
CREATE UNIQUE INDEX system_settings_singleton ON public.system_settings USING btree ((true));
CREATE INDEX idx_treasury_transactions_account ON public.treasury_transactions USING btree (account_id);
CREATE INDEX idx_treasury_transactions_date ON public.treasury_transactions USING btree (transaction_date);
CREATE UNIQUE INDEX user_permissions_user_id_permission_key_key ON public.user_permissions USING btree (user_id, permission_key);
CREATE INDEX idx_user_roles_created_by ON public.user_roles USING btree (created_by);
CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);
CREATE INDEX idx_user_roles_updated_by ON public.user_roles USING btree (updated_by);
CREATE UNIQUE INDEX uq_user_roles_user_role_id ON public.user_roles USING btree (user_id, role_id) WHERE (role_id IS NOT NULL);
CREATE UNIQUE INDEX user_roles_user_id_role_key ON public.user_roles USING btree (user_id, role);
CREATE INDEX idx_vehicle_assignments_created_by ON public.vehicle_assignments USING btree (created_by);
CREATE INDEX idx_vehicle_assignments_employee_id ON public.vehicle_assignments USING btree (employee_id);
CREATE INDEX idx_vehicle_assignments_vehicle_id ON public.vehicle_assignments USING btree (vehicle_id);
CREATE INDEX idx_vehicle_documents_vehicle_id ON public.vehicle_documents USING btree (vehicle_id);
CREATE UNIQUE INDEX vehicle_mileage_employee_id_month_year_key ON public.vehicle_mileage USING btree (employee_id, month_year);
CREATE INDEX idx_vehicle_mileage_daily_employee_date ON public.vehicle_mileage_daily USING btree (employee_id, date);
CREATE UNIQUE INDEX vehicle_mileage_daily_employee_id_date_key ON public.vehicle_mileage_daily USING btree (employee_id, date);
CREATE UNIQUE INDEX vehicles_plate_number_key ON public.vehicles USING btree (plate_number);

-- ================================================================
-- RLS POLICIES
-- ================================================================
-- Table: account_assignments, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."account_assignments"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: account_assignments, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."account_assignments"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: account_assignments, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."account_assignments"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: admin_action_log, Policy: admin_action_log_insert_policy (INSERT)
CREATE POLICY "admin_action_log_insert_policy" ON public."admin_action_log"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND (NOT (user_id IS DISTINCT FROM auth.uid()))))
;

-- Table: admin_action_log, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."admin_action_log"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND (NOT (user_id IS DISTINCT FROM auth.uid()))))
;

-- Table: admin_action_log, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."admin_action_log"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND has_permission('audit'::text, 'view'::text)))
;

-- Table: advance_installments, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."advance_installments"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'delete'::text))))
;

-- Table: advance_installments, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."advance_installments"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: advance_installments, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."advance_installments"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR ((is_internal_user() AND has_permission('financials'::text, 'view'::text)) OR (is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))))
;

-- Table: advance_installments, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."advance_installments"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND advance_in_my_company(advance_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: advances, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."advances"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'delete'::text))))
;

-- Table: advances, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."advances"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: advances, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."advances"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR ((is_internal_user() AND has_permission('financials'::text, 'view'::text)) OR (is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))))
;

-- Table: advances, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."advances"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: alerts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."alerts"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: alerts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."alerts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: alerts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."alerts"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: alerts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."alerts"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: app_hybrid_rules, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."app_hybrid_rules"
  AS PERMISSIVE FOR DELETE
  USING (is_active_user(auth.uid()))
;

-- Table: app_hybrid_rules, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."app_hybrid_rules"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (is_active_user(auth.uid()))
;

-- Table: app_hybrid_rules, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."app_hybrid_rules"
  AS PERMISSIVE FOR SELECT
  USING (is_active_user(auth.uid()))
;

-- Table: app_hybrid_rules, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."app_hybrid_rules"
  AS PERMISSIVE FOR UPDATE
  USING (is_active_user(auth.uid()))
  WITH CHECK (is_active_user(auth.uid()))
;

-- Table: app_targets, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."app_targets"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: app_targets, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."app_targets"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: app_targets, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."app_targets"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: app_targets, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."app_targets"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: apps, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."apps"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: apps, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."apps"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: apps, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."apps"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR is_active_user(auth.uid())))
;

-- Table: apps, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."apps"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: attendance, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."attendance"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_internal_user() AND has_permission('attendance'::text, 'delete'::text))))
;

-- Table: attendance, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."attendance"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_internal_user() AND has_permission('attendance'::text, 'write'::text))))
;

-- Table: attendance, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."attendance"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('attendance'::text, 'view'::text))))
;

-- Table: attendance, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."attendance"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_internal_user() AND has_permission('attendance'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_internal_user() AND has_permission('attendance'::text, 'write'::text))))
;

-- Table: attendance_status_configs, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."attendance_status_configs"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: attendance_status_configs, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."attendance_status_configs"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: attendance_status_configs, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."attendance_status_configs"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR true))
;

-- Table: attendance_status_configs, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."attendance_status_configs"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: audit_log, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."audit_log"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (auth.uid() = user_id)))
;

-- Table: audit_log, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."audit_log"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: commercial_records, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."commercial_records"
  AS PERMISSIVE FOR DELETE
  USING ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
;

-- Table: commercial_records, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."commercial_records"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
;

-- Table: commercial_records, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."commercial_records"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND has_permission('employees'::text, 'view'::text)))
;

-- Table: commercial_records, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."commercial_records"
  AS PERMISSIVE FOR UPDATE
  USING ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
  WITH CHECK ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
;

-- Table: daily_orders, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."daily_orders"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_internal_user() AND has_permission('orders'::text, 'delete'::text))))
;

-- Table: daily_orders, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."daily_orders"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_internal_user() AND has_permission('orders'::text, 'write'::text))))
;

-- Table: daily_orders, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."daily_orders"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR ((is_internal_user() AND has_permission('orders'::text, 'view'::text)) OR (is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))))
;

-- Table: daily_orders, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."daily_orders"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_internal_user() AND has_permission('orders'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_internal_user() AND has_permission('orders'::text, 'write'::text))))
;

-- Table: daily_shifts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."daily_shifts"
  AS PERMISSIVE FOR DELETE
  USING (is_active_user(auth.uid()))
;

-- Table: daily_shifts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."daily_shifts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (is_active_user(auth.uid()))
;

-- Table: daily_shifts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."daily_shifts"
  AS PERMISSIVE FOR SELECT
  USING (is_active_user(auth.uid()))
;

-- Table: daily_shifts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."daily_shifts"
  AS PERMISSIVE FOR UPDATE
  USING (is_active_user(auth.uid()))
  WITH CHECK (is_active_user(auth.uid()))
;

-- Table: departments, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."departments"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: departments, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."departments"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: departments, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."departments"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: departments, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."departments"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: edge_rate_limits, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."edge_rate_limits"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: edge_rate_limits, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."edge_rate_limits"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: edge_rate_limits, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."edge_rate_limits"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: edge_rate_limits, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."edge_rate_limits"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: employee_apps, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employee_apps"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_apps, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employee_apps"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_apps, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employee_apps"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role)))))
;

-- Table: employee_apps, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employee_apps"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_roles, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employee_roles"
  AS PERMISSIVE FOR DELETE
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role)))
;

-- Table: employee_roles, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employee_roles"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role)))
;

-- Table: employee_roles, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employee_roles"
  AS PERMISSIVE FOR SELECT
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR is_active_user(auth.uid())))
;

-- Table: employee_roles, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employee_roles"
  AS PERMISSIVE FOR UPDATE
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role)))
;

-- Table: employee_scheme, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employee_scheme"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_scheme, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employee_scheme"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_scheme, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employee_scheme"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
;

-- Table: employee_scheme, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employee_scheme"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_targets, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employee_targets"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_targets, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employee_targets"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_targets, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employee_targets"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: employee_targets, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employee_targets"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_tiers, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employee_tiers"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_tiers, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employee_tiers"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_tiers, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employee_tiers"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_tiers, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employee_tiers"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: employee_wallet_transactions, Policy: wallet_delete_policy (DELETE)
CREATE POLICY "wallet_delete_policy" ON public."employee_wallet_transactions"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_wallet_transactions, Policy: wallet_insert_policy (INSERT)
CREATE POLICY "wallet_insert_policy" ON public."employee_wallet_transactions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_wallet_transactions, Policy: wallet_select_policy (SELECT)
CREATE POLICY "wallet_select_policy" ON public."employee_wallet_transactions"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employee_wallet_transactions, Policy: wallet_update_policy (UPDATE)
CREATE POLICY "wallet_update_policy" ON public."employee_wallet_transactions"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: employees, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."employees"
  AS PERMISSIVE FOR DELETE
  USING ((is_internal_user() AND has_permission('employees'::text, 'delete'::text)))
;

-- Table: employees, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."employees"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
;

-- Table: employees, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."employees"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND (has_permission('employees'::text, 'view'::text) OR has_permission('attendance'::text, 'view'::text))))
;

-- Table: employees, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."employees"
  AS PERMISSIVE FOR UPDATE
  USING ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
  WITH CHECK ((is_internal_user() AND has_permission('employees'::text, 'write'::text)))
;

-- Table: external_deductions, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."external_deductions"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'delete'::text))))
;

-- Table: external_deductions, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."external_deductions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: external_deductions, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."external_deductions"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR ((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'view'::text)))))
;

-- Table: external_deductions, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."external_deductions"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('financials'::text, 'write'::text))))
;

-- Table: finance_transactions, Policy: finance_transactions_delete (DELETE)
CREATE POLICY "finance_transactions_delete" ON public."finance_transactions"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: finance_transactions, Policy: finance_transactions_insert (INSERT)
CREATE POLICY "finance_transactions_insert" ON public."finance_transactions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: finance_transactions, Policy: finance_transactions_select (SELECT)
CREATE POLICY "finance_transactions_select" ON public."finance_transactions"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: finance_transactions, Policy: finance_transactions_update (UPDATE)
CREATE POLICY "finance_transactions_update" ON public."finance_transactions"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: locked_months, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."locked_months"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
;

-- Table: locked_months, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."locked_months"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
;

-- Table: locked_months, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."locked_months"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: locked_months, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."locked_months"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
  WITH CHECK (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
;

-- Table: maintenance_logs, Policy: Active users can view maintenance_logs (SELECT)
CREATE POLICY "Active users can view maintenance_logs" ON public."maintenance_logs"
  AS PERMISSIVE FOR SELECT
  USING (is_active_user(auth.uid()))
;

-- Table: maintenance_logs, Policy: Operations/admin can manage maintenance_logs (ALL)
CREATE POLICY "Operations/admin can manage maintenance_logs" ON public."maintenance_logs"
  AS PERMISSIVE FOR ALL
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
;

-- Table: maintenance_logs, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."maintenance_logs"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: maintenance_logs, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."maintenance_logs"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: maintenance_logs, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."maintenance_logs"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: maintenance_logs, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."maintenance_logs"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: maintenance_parts, Policy: Active users can view maintenance_parts (SELECT)
CREATE POLICY "Active users can view maintenance_parts" ON public."maintenance_parts"
  AS PERMISSIVE FOR SELECT
  USING (is_active_user(auth.uid()))
;

-- Table: maintenance_parts, Policy: Operations/admin can manage maintenance_parts (ALL)
CREATE POLICY "Operations/admin can manage maintenance_parts" ON public."maintenance_parts"
  AS PERMISSIVE FOR ALL
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
;

-- Table: maintenance_parts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."maintenance_parts"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: maintenance_parts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."maintenance_parts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: maintenance_parts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."maintenance_parts"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: maintenance_parts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."maintenance_parts"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: order_import_batches, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."order_import_batches"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: order_import_batches, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."order_import_batches"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: order_import_batches, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."order_import_batches"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: order_import_batches, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."order_import_batches"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: pl_records, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."pl_records"
  AS PERMISSIVE FOR DELETE
  USING ((is_internal_user() AND has_permission('financials'::text, 'delete'::text)))
;

-- Table: pl_records, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."pl_records"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND has_permission('financials'::text, 'write'::text)))
;

-- Table: pl_records, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."pl_records"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND has_permission('financials'::text, 'view'::text)))
;

-- Table: pl_records, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."pl_records"
  AS PERMISSIVE FOR UPDATE
  USING ((is_internal_user() AND has_permission('financials'::text, 'write'::text)))
  WITH CHECK ((is_internal_user() AND has_permission('financials'::text, 'write'::text)))
;

-- Table: platform_accounts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."platform_accounts"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: platform_accounts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."platform_accounts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: platform_accounts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."platform_accounts"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))))
;

-- Table: platform_accounts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."platform_accounts"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: positions, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."positions"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: positions, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."positions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: positions, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."positions"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: positions, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."positions"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role))))
;

-- Table: pricing_rules, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."pricing_rules"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: pricing_rules, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."pricing_rules"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: pricing_rules, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."pricing_rules"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: pricing_rules, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."pricing_rules"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: profiles, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."profiles"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: profiles, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."profiles"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role))
;

-- Table: profiles, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."profiles"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) OR (auth.uid() = id)))
;

-- Table: profiles, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."profiles"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (auth.uid() = id)))
  WITH CHECK (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR (auth.uid() = id)))
;

-- Table: roles, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."roles"
  AS PERMISSIVE FOR DELETE
  USING ((is_internal_user() AND has_permission('roles'::text, 'delete'::text)))
;

-- Table: roles, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."roles"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
;

-- Table: roles, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."roles"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND has_permission('roles'::text, 'view'::text)))
;

-- Table: roles, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."roles"
  AS PERMISSIVE FOR UPDATE
  USING ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
  WITH CHECK ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
;

-- Table: salary_drafts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_drafts"
  AS PERMISSIVE FOR DELETE
  USING ((auth.uid() = user_id))
;

-- Table: salary_drafts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_drafts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((auth.uid() = user_id))
;

-- Table: salary_drafts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_drafts"
  AS PERMISSIVE FOR SELECT
  USING ((auth.uid() = user_id))
;

-- Table: salary_drafts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_drafts"
  AS PERMISSIVE FOR UPDATE
  USING ((auth.uid() = user_id))
  WITH CHECK ((auth.uid() = user_id))
;

-- Table: salary_month_snapshots, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_month_snapshots"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_month_snapshots, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_month_snapshots"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_month_snapshots, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_month_snapshots"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_month_snapshots, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_month_snapshots"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_records, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_records"
  AS PERMISSIVE FOR DELETE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('salary'::text, 'delete'::text))))
;

-- Table: salary_records, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_records"
  AS PERMISSIVE FOR INSERT
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('salary'::text, 'write'::text))))
;

-- Table: salary_records, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_records"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR ((is_internal_user() AND has_permission('salary'::text, 'view'::text)) OR (is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))))
;

-- Table: salary_records, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_records"
  AS PERMISSIVE FOR UPDATE
  USING (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('salary'::text, 'write'::text))))
  WITH CHECK (((is_active_user(auth.uid()) AND employee_in_my_company(employee_id) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR (is_internal_user() AND has_permission('salary'::text, 'write'::text))))
;

-- Table: salary_scheme_tiers, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_scheme_tiers"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_scheme_tiers, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_scheme_tiers"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_scheme_tiers, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_scheme_tiers"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: salary_scheme_tiers, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_scheme_tiers"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_schemes, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_schemes"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_schemes, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_schemes"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_schemes, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_schemes"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: salary_schemes, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_schemes"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: salary_slip_templates, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_slip_templates"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: salary_slip_templates, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_slip_templates"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: salary_slip_templates, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_slip_templates"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: salary_slip_templates, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_slip_templates"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: salary_tiers, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."salary_tiers"
  AS PERMISSIVE FOR DELETE
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))
;

-- Table: salary_tiers, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."salary_tiers"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))
;

-- Table: salary_tiers, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."salary_tiers"
  AS PERMISSIVE FOR SELECT
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role) OR is_active_user(auth.uid())))
;

-- Table: salary_tiers, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."salary_tiers"
  AS PERMISSIVE FOR UPDATE
  USING ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))
  WITH CHECK ((has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role)))
;

-- Table: scheme_month_snapshots, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."scheme_month_snapshots"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: scheme_month_snapshots, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."scheme_month_snapshots"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: scheme_month_snapshots, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."scheme_month_snapshots"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: scheme_month_snapshots, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."scheme_month_snapshots"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: spare_parts, Policy: Active users can view spare_parts (SELECT)
CREATE POLICY "Active users can view spare_parts" ON public."spare_parts"
  AS PERMISSIVE FOR SELECT
  USING (is_active_user(auth.uid()))
;

-- Table: spare_parts, Policy: Admin/operations can manage spare_parts (ALL)
CREATE POLICY "Admin/operations can manage spare_parts" ON public."spare_parts"
  AS PERMISSIVE FOR ALL
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), _const_role_admin()) OR has_role(auth.uid(), _const_role_operations()))))
;

-- Table: spare_parts, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."spare_parts"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: spare_parts, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."spare_parts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: spare_parts, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."spare_parts"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: spare_parts, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."spare_parts"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: supervisor_employee_assignments, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."supervisor_employee_assignments"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: supervisor_employee_assignments, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."supervisor_employee_assignments"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: supervisor_employee_assignments, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."supervisor_employee_assignments"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR is_active_user(auth.uid())))
;

-- Table: supervisor_employee_assignments, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."supervisor_employee_assignments"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: system_settings, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."system_settings"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: system_settings, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."system_settings"
  AS PERMISSIVE FOR SELECT
  USING (true)
;

-- Table: system_settings, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."system_settings"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: trade_registers, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."trade_registers"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: trade_registers, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."trade_registers"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: trade_registers, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."trade_registers"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR is_active_user(auth.uid())))
;

-- Table: trade_registers, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."trade_registers"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: treasury_accounts, Policy: treasury_accounts_delete (DELETE)
CREATE POLICY "treasury_accounts_delete" ON public."treasury_accounts"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_accounts, Policy: treasury_accounts_insert (INSERT)
CREATE POLICY "treasury_accounts_insert" ON public."treasury_accounts"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_accounts, Policy: treasury_accounts_select (SELECT)
CREATE POLICY "treasury_accounts_select" ON public."treasury_accounts"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_accounts, Policy: treasury_accounts_update (UPDATE)
CREATE POLICY "treasury_accounts_update" ON public."treasury_accounts"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_categories, Policy: treasury_categories_delete (DELETE)
CREATE POLICY "treasury_categories_delete" ON public."treasury_categories"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_categories, Policy: treasury_categories_insert (INSERT)
CREATE POLICY "treasury_categories_insert" ON public."treasury_categories"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_categories, Policy: treasury_categories_select (SELECT)
CREATE POLICY "treasury_categories_select" ON public."treasury_categories"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_categories, Policy: treasury_categories_update (UPDATE)
CREATE POLICY "treasury_categories_update" ON public."treasury_categories"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_transactions, Policy: treasury_transactions_delete (DELETE)
CREATE POLICY "treasury_transactions_delete" ON public."treasury_transactions"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_transactions, Policy: treasury_transactions_insert (INSERT)
CREATE POLICY "treasury_transactions_insert" ON public."treasury_transactions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_transactions, Policy: treasury_transactions_select (SELECT)
CREATE POLICY "treasury_transactions_select" ON public."treasury_transactions"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: treasury_transactions, Policy: treasury_transactions_update (UPDATE)
CREATE POLICY "treasury_transactions_update" ON public."treasury_transactions"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: user_permissions, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."user_permissions"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: user_permissions, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."user_permissions"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: user_permissions, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."user_permissions"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)) OR ((auth.uid() = user_id) OR (is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))))
;

-- Table: user_permissions, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."user_permissions"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
  WITH CHECK ((is_active_user(auth.uid()) AND has_role(auth.uid(), 'admin'::app_role)))
;

-- Table: user_roles, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."user_roles"
  AS PERMISSIVE FOR DELETE
  USING ((is_internal_user() AND has_permission('roles'::text, 'delete'::text)))
;

-- Table: user_roles, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."user_roles"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
;

-- Table: user_roles, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."user_roles"
  AS PERMISSIVE FOR SELECT
  USING ((is_internal_user() AND has_permission('roles'::text, 'view'::text)))
;

-- Table: user_roles, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."user_roles"
  AS PERMISSIVE FOR UPDATE
  USING ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
  WITH CHECK ((is_internal_user() AND has_permission('roles'::text, 'write'::text)))
;

-- Table: vehicle_assignments, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."vehicle_assignments"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_assignments, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."vehicle_assignments"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_assignments, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."vehicle_assignments"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role)))))
;

-- Table: vehicle_assignments, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."vehicle_assignments"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_documents, Policy: Authenticated users can delete vehicle documents (DELETE)
CREATE POLICY "Authenticated users can delete vehicle documents" ON public."vehicle_documents"
  AS PERMISSIVE FOR DELETE
  USING (((auth.uid() = created_by) OR is_internal_user()))
;

-- Table: vehicle_documents, Policy: Authenticated users can insert vehicle documents (INSERT)
CREATE POLICY "Authenticated users can insert vehicle documents" ON public."vehicle_documents"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((auth.uid() IS NOT NULL))
;

-- Table: vehicle_documents, Policy: Authenticated users can update vehicle documents (UPDATE)
CREATE POLICY "Authenticated users can update vehicle documents" ON public."vehicle_documents"
  AS PERMISSIVE FOR UPDATE
  USING (((auth.uid() = created_by) OR is_internal_user()))
;

-- Table: vehicle_documents, Policy: Authenticated users can view vehicle documents (SELECT)
CREATE POLICY "Authenticated users can view vehicle documents" ON public."vehicle_documents"
  AS PERMISSIVE FOR SELECT
  USING (true)
;

-- Table: vehicle_mileage, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."vehicle_mileage"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_mileage, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."vehicle_mileage"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_mileage, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."vehicle_mileage"
  AS PERMISSIVE FOR SELECT
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_mileage, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."vehicle_mileage"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicle_mileage_daily, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."vehicle_mileage_daily"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: vehicle_mileage_daily, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."vehicle_mileage_daily"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: vehicle_mileage_daily, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."vehicle_mileage_daily"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))) OR ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role) OR has_role(auth.uid(), 'hr'::app_role))) OR is_active_user(auth.uid()))))
;

-- Table: vehicle_mileage_daily, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."vehicle_mileage_daily"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role) OR has_role(auth.uid(), 'finance'::app_role))))
;

-- Table: vehicles, Policy: unified_delete_policy (DELETE)
CREATE POLICY "unified_delete_policy" ON public."vehicles"
  AS PERMISSIVE FOR DELETE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicles, Policy: unified_insert_policy (INSERT)
CREATE POLICY "unified_insert_policy" ON public."vehicles"
  AS PERMISSIVE FOR INSERT
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- Table: vehicles, Policy: unified_select_policy (SELECT)
CREATE POLICY "unified_select_policy" ON public."vehicles"
  AS PERMISSIVE FOR SELECT
  USING (((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))) OR (is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'hr'::app_role) OR has_role(auth.uid(), 'operations'::app_role)))))
;

-- Table: vehicles, Policy: unified_update_policy (UPDATE)
CREATE POLICY "unified_update_policy" ON public."vehicles"
  AS PERMISSIVE FOR UPDATE
  USING ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
  WITH CHECK ((is_active_user(auth.uid()) AND (has_role(auth.uid(), 'admin'::app_role) OR has_role(auth.uid(), 'operations'::app_role))))
;

-- ================================================================
-- FUNCTIONS
-- ================================================================
-- Function: public.advance_in_my_company(_advance_id uuid)
CREATE OR REPLACE FUNCTION public.advance_in_my_company(_advance_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.advances AS a
    WHERE a.id = _advance_id
  );
$function$


-- Function: public.assign_platform_account(p_account_id uuid, p_employee_id uuid, p_start_date date, p_notes text, p_created_by uuid)
CREATE OR REPLACE FUNCTION public.assign_platform_account(p_account_id uuid, p_employee_id uuid, p_start_date date, p_notes text DEFAULT NULL::text, p_created_by uuid DEFAULT NULL::uuid)
 RETURNS account_assignments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_assignment public.account_assignments;
BEGIN
  IF auth.uid() IS NULL
     OR NOT public.is_active_user(auth.uid())
     OR NOT (
       public.has_role(auth.uid(), 'admin'::public.app_role)
       OR public.has_role(auth.uid(), 'hr'::public.app_role)
     ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_account_id IS NULL THEN
    RAISE EXCEPTION 'account_id is required';
  END IF;

  IF p_employee_id IS NULL THEN
    RAISE EXCEPTION 'employee_id is required';
  END IF;

  IF p_start_date IS NULL THEN
    RAISE EXCEPTION 'start_date is required';
  END IF;

  PERFORM 1
  FROM public.platform_accounts
  WHERE id = p_account_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'platform account not found';
  END IF;

  PERFORM 1
  FROM public.employees
  WHERE id = p_employee_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'employee not found';
  END IF;

  UPDATE public.account_assignments
  SET end_date = CURRENT_DATE
  WHERE account_id = p_account_id
    AND end_date IS NULL;

  INSERT INTO public.account_assignments (
    account_id,
    employee_id,
    start_date,
    end_date,
    month_year,
    notes,
    created_by
  )
  VALUES (
    p_account_id,
    p_employee_id,
    p_start_date,
    NULL,
    to_char(p_start_date, 'YYYY-MM'),
    NULLIF(btrim(COALESCE(p_notes, '')), ''),
    COALESCE(p_created_by, auth.uid())
  )
  RETURNING * INTO v_assignment;

  UPDATE public.platform_accounts
  SET employee_id = p_employee_id
  WHERE id = p_account_id;

  RETURN v_assignment;
END;
$function$


-- Function: public.calc_tier_salary(p_orders integer, p_scheme_id uuid)
CREATE OR REPLACE FUNCTION public.calc_tier_salary(p_orders integer, p_scheme_id uuid DEFAULT NULL::uuid)
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tier RECORD;
  v_salary NUMERIC := 0;
  c_tier_fixed TEXT := _const_tier_fixed();
  c_tier_incremental TEXT := _const_tier_incremental();
BEGIN
  IF p_orders <= 0 OR p_scheme_id IS NULL THEN RETURN 0; END IF;

  FOR v_tier IN
    SELECT * FROM public.salary_scheme_tiers
    WHERE scheme_id = p_scheme_id
      AND from_orders <= p_orders
    ORDER BY from_orders DESC
    LIMIT 1
  LOOP
    IF v_tier.tier_type = c_tier_fixed THEN
      v_salary := v_tier.price_per_order;
    ELSIF v_tier.tier_type = c_tier_incremental THEN
      v_salary := v_tier.price_per_order
        + GREATEST(p_orders - COALESCE(v_tier.incremental_threshold, v_tier.from_orders), 0)
        * COALESCE(v_tier.incremental_price, 0);
    ELSE
      v_salary := p_orders * v_tier.price_per_order;
    END IF;
  END LOOP;

  RETURN ROUND(v_salary);
END;
$function$


-- Function: public.calculate_employee_salary(p_employee_id uuid, p_month_year text, p_payment_method text, p_manual_deduction numeric, p_manual_deduction_note text)
CREATE OR REPLACE FUNCTION public.calculate_employee_salary(p_employee_id uuid, p_month_year text, p_payment_method text DEFAULT NULL::text, p_manual_deduction numeric DEFAULT 0, p_manual_deduction_note text DEFAULT NULL::text)
 RETURNS TABLE(employee_id uuid, employee_name text, base_salary numeric, total_orders integer, total_shift_days integer, total_earnings numeric, advance_deduction numeric, external_deduction numeric, manual_deduction numeric, manual_deduction_note text, attendance_deduction numeric, net_salary numeric, platform_breakdown jsonb, payment_method text)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_employee RECORD;
  v_start DATE;
  v_end DATE;
  v_total_orders INTEGER := 0;
  v_total_shift_days INTEGER := 0;
  v_total_earnings NUMERIC := 0;
  v_advance_deduction NUMERIC := 0;
  v_external_deduction NUMERIC := 0;
  v_attendance_deduction NUMERIC := 0;
  v_app RECORD;
  v_app_orders INTEGER := 0;
  v_app_shifts INTEGER := 0;
  v_app_earnings NUMERIC := 0;
  v_pricing_rule RECORD;
  v_hybrid_rule RECORD;
  v_hours_worked NUMERIC;
  v_day RECORD;
  v_platform_breakdown JSONB := '[]'::JSONB;
  v_platform_item JSONB;
  v_payment_method TEXT;
BEGIN
  v_start := (p_month_year || '-01')::DATE;
  v_end := (v_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  SELECT * INTO v_employee FROM public.employees WHERE id = p_employee_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee not found: %', p_employee_id;
  END IF;

  FOR v_app IN
    SELECT a.id, a.name, COALESCE(a.work_type, _const_work_orders()) AS work_type
    FROM public.apps a
    JOIN public.employee_apps ea ON ea.app_id = a.id
    WHERE ea.employee_id = p_employee_id
      AND ea.status = _const_employee_active()
      AND a.is_active IS TRUE
    ORDER BY a.name
  LOOP
    v_app_orders := 0;
    v_app_shifts := 0;
    v_app_earnings := 0;

    IF v_app.work_type = _const_work_orders() THEN
      SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
      FROM public.daily_orders AS d
      WHERE d.employee_id = p_employee_id
        AND d.app_id = v_app.id
        AND d.date BETWEEN v_start AND v_end
        AND (d.status IS NULL OR d.status <> _const_order_cancelled());
      v_total_orders := v_total_orders + v_app_orders;
      v_app_earnings := public.calc_tier_salary(v_app_orders);

    ELSIF v_app.work_type = _const_work_shift() THEN
      SELECT COUNT(*)::INTEGER INTO v_app_shifts
      FROM public.daily_shifts AS s
      WHERE s.employee_id = p_employee_id
        AND s.app_id = v_app.id
        AND s.date BETWEEN v_start AND v_end
        AND s.hours_worked > 0;
      v_total_shift_days := v_total_shift_days + v_app_shifts;

      SELECT * INTO v_pricing_rule
      FROM public.pricing_rules
      WHERE app_id = v_app.id AND is_active IS TRUE
      ORDER BY priority DESC LIMIT 1;

      IF v_pricing_rule.fixed_salary IS NOT NULL THEN
        v_app_earnings := v_app_shifts * v_pricing_rule.fixed_salary;
      ELSE
        v_app_earnings := v_app_shifts * 150;
      END IF;

    ELSIF v_app.work_type = _const_work_hybrid() THEN
      SELECT * INTO v_hybrid_rule FROM public.app_hybrid_rules WHERE app_id = v_app.id;

      IF v_hybrid_rule IS NULL THEN
        SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
        FROM public.daily_orders AS d
        WHERE d.employee_id = p_employee_id
          AND d.app_id = v_app.id
          AND d.date BETWEEN v_start AND v_end
          AND (d.status IS NULL OR d.status <> _const_order_cancelled());
        v_total_orders := v_total_orders + v_app_orders;
        v_app_earnings := public.calc_tier_salary(v_app_orders);
      ELSE
        FOR v_day IN
          SELECT generate_series(v_start, v_end, '1 day'::interval)::date AS day_date
        LOOP
          SELECT ds.hours_worked INTO v_hours_worked
          FROM public.daily_shifts AS ds
          WHERE ds.employee_id = p_employee_id
            AND ds.app_id = v_app.id
            AND ds.date = v_day.day_date;

          IF v_hours_worked IS NOT NULL AND v_hours_worked > 0 THEN
            v_app_earnings := v_app_earnings + v_hybrid_rule.shift_rate;
            v_total_shift_days := v_total_shift_days + 1;
          ELSE
            IF v_hybrid_rule.fallback_to_orders THEN
              SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
              FROM public.daily_orders AS d
              WHERE d.employee_id = p_employee_id
                AND d.app_id = v_app.id
                AND d.date = v_day.day_date
                AND (d.status IS NULL OR d.status <> _const_order_cancelled());
              v_total_orders := v_total_orders + v_app_orders;
              IF v_app_orders > 0 THEN
                v_app_earnings := v_app_earnings + public.calc_tier_salary(v_app_orders);
              END IF;
            END IF;
          END IF;
        END LOOP;
      END IF;
    END IF;

    v_total_earnings := v_total_earnings + v_app_earnings;
    v_platform_item := jsonb_build_object(
      'app_id', v_app.id,
      'app_name', v_app.name,
      'work_type', v_app.work_type,
      _const_work_orders(), v_app_orders,
      'shift_days', v_app_shifts,
      'earnings', v_app_earnings
    );
    v_platform_breakdown := v_platform_breakdown || jsonb_build_array(v_platform_item);
  END LOOP;

  -- Advance deductions (month_year is correct for advance_installments)
  SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance_deduction
  FROM public.advance_installments ai
  JOIN public.advances a ON a.id = ai.advance_id
  WHERE a.employee_id = p_employee_id
    AND ai.month_year = p_month_year
    AND ai.status = _const_installment_pending();

  -- FIX: external_deductions uses apply_month (not month_year)
  --      and approval_status (not status)
  SELECT COALESCE(SUM(ed.amount), 0) INTO v_external_deduction
  FROM public.external_deductions ed
  WHERE ed.employee_id = p_employee_id
    AND ed.apply_month = p_month_year
    AND ed.approval_status = _const_approval_approved();

  v_payment_method := COALESCE(
    p_payment_method,
    CASE WHEN v_employee.iban IS NOT NULL
         THEN _const_payment_bank()
         ELSE _const_payment_cash()
    END
  );

  RETURN QUERY SELECT
    p_employee_id,
    v_employee.name::TEXT,
    v_total_earnings,
    v_total_orders,
    v_total_shift_days,
    v_total_earnings,
    v_advance_deduction,
    v_external_deduction,
    p_manual_deduction,
    p_manual_deduction_note,
    v_attendance_deduction,
    v_total_earnings - v_advance_deduction - v_external_deduction
      - p_manual_deduction - v_attendance_deduction,
    v_platform_breakdown,
    v_payment_method;
END;
$function$


-- Function: public.calculate_order_salary_for_app(p_app_id uuid, p_orders integer, p_attendance_days integer, p_fixed_scheme_ids uuid[], p_allow_target_bonus boolean)
CREATE OR REPLACE FUNCTION public.calculate_order_salary_for_app(p_app_id uuid, p_orders integer, p_attendance_days integer DEFAULT 0, p_fixed_scheme_ids uuid[] DEFAULT ARRAY[]::uuid[], p_allow_target_bonus boolean DEFAULT true)
 RETURNS TABLE(earnings numeric, calculation_method text, fixed_scheme_ids uuid[])
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_orders INTEGER := GREATEST(COALESCE(p_orders, 0), 0);
  v_attendance_days INTEGER := GREATEST(COALESCE(p_attendance_days, 0), 0);
  v_rule RECORD;
  v_scheme RECORD;
  v_tier RECORD;
  v_total NUMERIC := 0;
  v_tier_orders INTEGER;
  v_fixed_ids UUID[] := COALESCE(p_fixed_scheme_ids, ARRAY[]::UUID[]);
  v_threshold INTEGER;
  v_incremental_price NUMERIC;
BEGIN
  earnings := 0;
  calculation_method := _const_work_orders();
  fixed_scheme_ids := v_fixed_ids;

  -- 1. Check for attached salary scheme FIRST
  SELECT
    ss.id,
    ss.scheme_type,
    ss.monthly_amount,
    ss.target_orders,
    ss.target_bonus
  INTO v_scheme
  FROM public.apps a
  LEFT JOIN public.salary_schemes ss ON ss.id = a.scheme_id
  WHERE a.id = p_app_id;

  IF FOUND AND v_scheme.id IS NOT NULL THEN
    IF COALESCE(v_scheme.scheme_type, 'order_based') = 'fixed_monthly' THEN
      calculation_method := _const_work_shift();
      IF v_scheme.id = ANY(v_fixed_ids) THEN
        earnings := 0;
      ELSE
        earnings := ROUND((COALESCE(v_scheme.monthly_amount, 0) / _const_days_per_month()) * v_attendance_days);
        fixed_scheme_ids := array_append(v_fixed_ids, v_scheme.id);
      END IF;
      RETURN NEXT;
      RETURN;
    END IF;

    IF v_orders <= 0 THEN
      RETURN NEXT;
      RETURN;
    END IF;

    SELECT t.*
    INTO v_tier
    FROM public.salary_scheme_tiers t
    WHERE t.scheme_id = v_scheme.id
      AND v_orders >= t.from_orders
      AND (t.to_orders IS NULL OR v_orders <= t.to_orders)
    ORDER BY t.tier_order
    LIMIT 1;

    IF NOT FOUND THEN
      SELECT t.*
      INTO v_tier
      FROM public.salary_scheme_tiers t
      WHERE t.scheme_id = v_scheme.id
      ORDER BY t.tier_order DESC
      LIMIT 1;
    END IF;

    IF FOUND THEN
      IF COALESCE(v_tier.tier_type, 'total_multiplier') = _const_tier_fixed() THEN
        v_total := COALESCE(v_tier.price_per_order, 0);
      ELSIF COALESCE(v_tier.tier_type, 'total_multiplier') = _const_tier_incremental() THEN
        v_threshold := COALESCE(v_tier.incremental_threshold, v_tier.from_orders);
        v_incremental_price := COALESCE(v_tier.incremental_price, 0);
        v_total :=
          COALESCE(v_tier.price_per_order, 0)
          + (GREATEST(v_orders - v_threshold, 0) * v_incremental_price);
      ELSIF COALESCE(v_tier.tier_type, 'total_multiplier') = 'per_order_band' THEN
        v_total := v_orders * COALESCE(v_tier.price_per_order, 0);
      ELSE
        v_total := 0;
        FOR v_tier IN
          SELECT *
          FROM public.salary_scheme_tiers
          WHERE scheme_id = v_scheme.id
          ORDER BY tier_order
        LOOP
          EXIT WHEN v_orders < v_tier.from_orders;
          v_tier_orders :=
            LEAST(v_orders, COALESCE(v_tier.to_orders, v_orders)) - v_tier.from_orders + 1;
          IF v_tier_orders > 0 THEN
            v_total := v_total + (v_tier_orders * COALESCE(v_tier.price_per_order, 0));
          END IF;
        END LOOP;
      END IF;

      IF p_allow_target_bonus
        AND COALESCE(v_scheme.target_orders, 0) > 0
        AND COALESCE(v_scheme.target_bonus, 0) > 0
        AND v_orders >= v_scheme.target_orders THEN
        v_total := v_total + v_scheme.target_bonus;
      END IF;

      earnings := ROUND(v_total);
      RETURN NEXT;
      RETURN;
    END IF;
  END IF;

  -- 2. Fallback to legacy pricing_rules if no scheme is linked (or if it unexpectedly had no tiers)
  SELECT pr.*
  INTO v_rule
  FROM public.pricing_rules pr
  WHERE pr.app_id = p_app_id
    AND pr.is_active IS TRUE
    AND v_orders >= COALESCE(pr.min_orders, 0)
    AND (pr.max_orders IS NULL OR v_orders <= pr.max_orders)
  ORDER BY pr.priority DESC, pr.min_orders ASC
  LIMIT 1;

  IF FOUND THEN
    IF v_rule.rule_type = 'fixed' THEN
      earnings := ROUND(COALESCE(v_rule.fixed_salary, 0));
    ELSIF v_rule.rule_type = _const_work_hybrid() THEN
      earnings := ROUND(
        COALESCE(v_rule.fixed_salary, 0) + (v_orders * COALESCE(v_rule.rate_per_order, 0))
      );
    ELSE
      earnings := ROUND(v_orders * COALESCE(v_rule.rate_per_order, 0));
    END IF;
    RETURN NEXT;
    RETURN;
  END IF;

  RETURN NEXT;
END;
$function$


-- Function: public.calculate_salary(p_employee_id uuid, p_month_year text, p_payment_method text, p_manual_deduction numeric, p_manual_deduction_note text)
CREATE OR REPLACE FUNCTION public.calculate_salary(p_employee_id uuid, p_month_year text, p_payment_method text DEFAULT _const_payment_cash(), p_manual_deduction numeric DEFAULT 0, p_manual_deduction_note text DEFAULT NULL::text)
 RETURNS TABLE(employee_id uuid, month_year text, total_orders integer, attendance_days integer, base_salary numeric, attendance_deduction numeric, external_deduction numeric, advance_deduction numeric, manual_deduction numeric, net_salary numeric, calc_status text)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_internal_user() OR NOT public.has_permission('salary', 'approve') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.calculate_salary_for_employee_month(
    p_employee_id,
    p_month_year,
    p_payment_method,
    p_manual_deduction,
    p_manual_deduction_note
  );
END;
$function$


-- Function: public.calculate_salary_for_employee_month(p_employee_id uuid, p_month_year text, p_payment_method text, p_manual_deduction numeric, p_manual_deduction_note text)
CREATE OR REPLACE FUNCTION public.calculate_salary_for_employee_month(p_employee_id uuid, p_month_year text, p_payment_method text DEFAULT _const_payment_cash(), p_manual_deduction numeric DEFAULT 0, p_manual_deduction_note text DEFAULT NULL::text)
 RETURNS TABLE(employee_id uuid, month_year text, total_orders integer, total_shift_days integer, base_salary numeric, attendance_deduction numeric, external_deduction numeric, advance_deduction numeric, manual_deduction numeric, net_salary numeric, calc_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE; v_end DATE;
  v_app RECORD;
  v_app_orders INTEGER; v_app_shift_days INTEGER; v_app_earnings NUMERIC;
  v_total_orders INTEGER := 0; v_total_shift_days INTEGER := 0;
  v_base_salary NUMERIC := 0; v_attendance_deduction NUMERIC := 0;
  v_external_deduction NUMERIC := 0; v_advance_deduction NUMERIC := 0;
  v_net NUMERIC := 0; v_platform_breakdown JSONB := '[]'::jsonb;
  v_calculation_method TEXT;
  v_hybrid_rule RECORD; v_day RECORD; v_hours_worked NUMERIC;
  v_monthly_amount NUMERIC;
  v_fixed_scheme_ids UUID[] := ARRAY[]::UUID[];
  -- Constants
  c_cancelled TEXT := _const_order_cancelled();
  c_approved TEXT := _const_approval_approved();
  c_pending TEXT := _const_installment_pending();
  c_deferred TEXT := _const_installment_deferred();
  c_orders TEXT := _const_work_orders();
  c_shift TEXT := _const_work_shift();
  c_hybrid TEXT := _const_work_hybrid();
  c_days_per_month NUMERIC := _const_days_per_month();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.employees e WHERE e.id = p_employee_id) THEN
    RAISE EXCEPTION 'Employee not found';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::date;

  FOR v_app IN
    SELECT a.id AS app_id, a.name AS app_name, a.work_type,
           s.id AS scheme_id, s.scheme_type, s.monthly_amount
    FROM public.apps a
    LEFT JOIN public.salary_schemes s ON s.id = a.scheme_id
    WHERE a.is_active IS TRUE
  LOOP
    v_app_orders := 0; v_app_shift_days := 0; v_app_earnings := 0;
    v_calculation_method := c_orders;

    IF v_app.work_type = c_orders OR v_app.work_type IS NULL THEN
      SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
      FROM public.daily_orders d
      WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id
        AND d.date BETWEEN v_start AND v_end
        AND (d.status IS NULL OR d.status <> c_cancelled);

      v_total_orders := v_total_orders + v_app_orders;

      SELECT earnings, calculation_method, fixed_scheme_ids
      INTO v_app_earnings, v_calculation_method, v_fixed_scheme_ids
      FROM public.calculate_order_salary_for_app(
        v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, true
      );

    ELSIF v_app.work_type = c_shift THEN
      v_calculation_method := _const_calc_method_shift_fixed();
      IF EXISTS(
        SELECT 1 FROM public.employee_apps ea
        WHERE ea.employee_id = p_employee_id AND ea.app_id = v_app.app_id
      ) THEN
        SELECT COUNT(*)::INTEGER INTO v_app_shift_days
        FROM public.daily_shifts ds
        WHERE ds.employee_id = p_employee_id AND ds.app_id = v_app.app_id
          AND ds.date BETWEEN v_start AND v_end AND ds.hours_worked > 0;

        v_total_shift_days := v_total_shift_days + v_app_shift_days;

        v_monthly_amount := COALESCE(v_app.monthly_amount, 0);
        IF v_monthly_amount > 0 AND v_app_shift_days > 0 THEN
          v_app_earnings := ROUND((v_monthly_amount / c_days_per_month) * v_app_shift_days);
        ELSE
          v_app_earnings := 0;
        END IF;
      END IF;

    ELSIF v_app.work_type = c_hybrid THEN
      v_calculation_method := _const_calc_method_mixed();
      SELECT * INTO v_hybrid_rule FROM public.app_hybrid_rules WHERE app_id = v_app.app_id;

      IF v_hybrid_rule IS NULL THEN
        v_calculation_method := _const_calc_method_orders_fallback();
        SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
        FROM public.daily_orders d
        WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id
          AND d.date BETWEEN v_start AND v_end
          AND (d.status IS NULL OR d.status <> c_cancelled);
        v_total_orders := v_total_orders + v_app_orders;

        SELECT earnings INTO v_app_earnings
        FROM public.calculate_order_salary_for_app(
          v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, true
        );
      ELSE
        FOR v_day IN SELECT generate_series(v_start, v_end, '1 day'::interval)::date AS day_date LOOP
          SELECT hours_worked INTO v_hours_worked
          FROM public.daily_shifts
          WHERE employee_id = p_employee_id AND app_id = v_app.app_id AND date = v_day.day_date;

          IF v_hours_worked IS NOT NULL AND v_hours_worked > 0 THEN
            v_app_earnings := v_app_earnings + v_hybrid_rule.shift_rate;
            v_app_shift_days := v_app_shift_days + 1;
          ELSIF v_hybrid_rule.fallback_to_orders THEN
            SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
            FROM public.daily_orders d
            WHERE d.employee_id = p_employee_id AND d.app_id = v_app.app_id AND d.date = v_day.day_date
              AND (d.status IS NULL OR d.status <> c_cancelled);
            v_total_orders := v_total_orders + v_app_orders;
            IF v_app_orders > 0 THEN
              v_app_earnings := v_app_earnings + (
                SELECT earnings FROM public.calculate_order_salary_for_app(
                  v_app.app_id, v_app_orders, 0, v_fixed_scheme_ids, false
                )
              );
            END IF;
          END IF;
        END LOOP;
        v_total_shift_days := v_total_shift_days + v_app_shift_days;
      END IF;
    END IF;

    v_base_salary := v_base_salary + v_app_earnings;

    IF v_app_orders > 0 OR v_app_shift_days > 0 OR v_app_earnings > 0 THEN
      v_platform_breakdown := v_platform_breakdown || jsonb_build_object(
        'app_id', v_app.app_id, 'app_name', v_app.app_name,
        'work_type', COALESCE(v_app.work_type, c_orders),
        'calculation_method', v_calculation_method,
        'orders_count', v_app_orders, 'shift_days', v_app_shift_days,
        'earnings', ROUND(v_app_earnings)
      );
    END IF;
  END LOOP;

  SELECT COALESCE(SUM(ed.amount), 0) INTO v_external_deduction
  FROM public.external_deductions ed
  WHERE ed.employee_id = p_employee_id AND ed.apply_month = p_month_year
    AND ed.approval_status = c_approved;

  SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance_deduction
  FROM public.advances ad JOIN public.advance_installments ai ON ai.advance_id = ad.id
  WHERE ad.employee_id = p_employee_id AND ai.month_year = p_month_year
    AND ai.status IN (c_pending, c_deferred);

  v_net := GREATEST(
    v_base_salary - v_attendance_deduction - v_external_deduction - v_advance_deduction
      - COALESCE(p_manual_deduction, 0),
    0
  );

  -- FIX: only real public.salary_records columns are written here.
  -- (total_orders / total_shift_days / platform_breakdown / "status" do NOT
  -- exist on this table and previously made every call fail outright.)
  INSERT INTO public.salary_records (
    employee_id,
    month_year,
    base_salary,
    attendance_deduction,
    external_deduction,
    advance_deduction,
    manual_deduction,
    manual_deduction_note,
    net_salary,
    payment_method,
    calc_status,
    calc_source,
    is_approved,
    sheet_snapshot
  )
  VALUES (
    p_employee_id,
    p_month_year,
    v_base_salary,
    v_attendance_deduction,
    v_external_deduction,
    v_advance_deduction,
    COALESCE(p_manual_deduction, 0),
    p_manual_deduction_note,
    v_net,
    COALESCE(NULLIF(TRIM(p_payment_method), ''), _const_payment_cash()),
    _const_calc_calculated(),
    'engine_v6_platform_breakdown',
    false,
    NULL
  )
  -- FIX: was missing this upsert clause, even though the table has a
  -- UNIQUE(employee_id, month_year) constraint — recalculating an
  -- already-saved month previously failed with a duplicate key error.
  ON CONFLICT (employee_id, month_year)
  DO UPDATE SET
    base_salary = EXCLUDED.base_salary,
    attendance_deduction = EXCLUDED.attendance_deduction,
    external_deduction = EXCLUDED.external_deduction,
    advance_deduction = EXCLUDED.advance_deduction,
    manual_deduction = EXCLUDED.manual_deduction,
    manual_deduction_note = EXCLUDED.manual_deduction_note,
    net_salary = EXCLUDED.net_salary,
    payment_method = EXCLUDED.payment_method,
    calc_status = EXCLUDED.calc_status,
    calc_source = EXCLUDED.calc_source,
    updated_at = now()
  RETURNING
    public.salary_records.employee_id,
    public.salary_records.month_year,
    v_total_orders,
    v_total_shift_days,
    public.salary_records.base_salary,
    public.salary_records.attendance_deduction,
    public.salary_records.external_deduction,
    public.salary_records.advance_deduction,
    public.salary_records.manual_deduction,
    public.salary_records.net_salary,
    public.salary_records.calc_status
  INTO
    employee_id,
    month_year,
    total_orders,
    total_shift_days,
    base_salary,
    attendance_deduction,
    external_deduction,
    advance_deduction,
    manual_deduction,
    net_salary,
    calc_status;

  RETURN NEXT;
END;
$function$


-- Function: public.calculate_salary_for_month(p_month_year text, p_payment_method text)
CREATE OR REPLACE FUNCTION public.calculate_salary_for_month(p_month_year text, p_payment_method text DEFAULT _const_payment_cash())
 RETURNS TABLE(employee_id uuid, month_year text, total_orders integer, total_shift_days integer, base_salary numeric, attendance_deduction numeric, external_deduction numeric, advance_deduction numeric, manual_deduction numeric, net_salary numeric, calc_status text)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_emp RECORD;
BEGIN
  FOR v_emp IN
    SELECT e.id
    FROM public.employees AS e
    WHERE public.is_salary_month_visible_employee(
      e.id,
      p_month_year,
      COALESCE(e.status::text, ''),
      COALESCE(e.sponsorship_status::text, ''),
      e.job_title
    )
    ORDER BY e.name
  LOOP
    RETURN QUERY
    SELECT *
    FROM public.calculate_salary_for_employee_month(
      v_emp.id,
      p_month_year,
      p_payment_method,
      0,
      NULL
    );
  END LOOP;
END;
$function$


-- Function: public.capture_salary_month_snapshot(p_month_year text)
CREATE OR REPLACE FUNCTION public.capture_salary_month_snapshot(p_month_year text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_snapshot JSONB;
  v_summary JSONB;
BEGIN
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'finance'::app_role)
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'employee_id', sr.employee_id,
        'month_year', sr.month_year,
        'base_salary', COALESCE(sr.base_salary, 0),
        'allowances', COALESCE(sr.allowances, 0),
        'attendance_deduction', COALESCE(sr.attendance_deduction, 0),
        'advance_deduction', COALESCE(sr.advance_deduction, 0),
        'external_deduction', COALESCE(sr.external_deduction, 0),
        'manual_deduction', COALESCE(sr.manual_deduction, 0),
        'net_salary', COALESCE(sr.net_salary, 0),
        'is_approved', COALESCE(sr.is_approved, false),
        'payment_method', sr.payment_method,
        'sheet_snapshot', sr.sheet_snapshot
      )
      ORDER BY sr.employee_id
    ),
    '[]'::jsonb
  )
  INTO v_snapshot
  FROM public.salary_records AS sr
  WHERE sr.month_year = p_month_year;

  SELECT jsonb_build_object(
    'month_year', p_month_year,
    'records_count', COUNT(*)::INTEGER,
    'approved_count', COUNT(*) FILTER (WHERE COALESCE(sr.is_approved, false))::INTEGER,
    'total_base_salary', COALESCE(SUM(sr.base_salary), 0),
    'total_net_salary', COALESCE(SUM(sr.net_salary), 0),
    'captured_at', now()
  )
  INTO v_summary
  FROM public.salary_records AS sr
  WHERE sr.month_year = p_month_year;

  INSERT INTO public.salary_month_snapshots (
    month_year,
    snapshot,
    summary,
    captured_by,
    captured_at
  )
  VALUES (
    p_month_year,
    COALESCE(v_snapshot, '[]'::jsonb),
    COALESCE(v_summary, '{}'::jsonb),
    auth.uid(),
    now()
  )
  ON CONFLICT (month_year)
  DO UPDATE SET
    snapshot = EXCLUDED.snapshot,
    summary = EXCLUDED.summary,
    captured_by = EXCLUDED.captured_by,
    captured_at = EXCLUDED.captured_at,
    updated_at = now();

  RETURN COALESCE(v_summary, '{}'::jsonb);
END;
$function$


-- Function: public.check_employee_operational_records(p_employee_id uuid)
CREATE OR REPLACE FUNCTION public.check_employee_operational_records(p_employee_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.daily_orders        WHERE employee_id = p_employee_id
    UNION ALL
    SELECT 1 FROM public.advances            WHERE employee_id = p_employee_id
    UNION ALL
    SELECT 1 FROM public.attendance          WHERE employee_id = p_employee_id
    UNION ALL
    SELECT 1 FROM public.vehicle_assignments WHERE employee_id = p_employee_id
    UNION ALL
    SELECT 1 FROM public.platform_accounts   WHERE employee_id = p_employee_id
    UNION ALL
    SELECT 1 FROM public.salary_records      WHERE employee_id = p_employee_id
  );
$function$


-- Function: public.check_in(p_employee_id uuid, p_checkin_at timestamp with time zone)
CREATE OR REPLACE FUNCTION public.check_in(p_employee_id uuid, p_checkin_at timestamp with time zone DEFAULT now())
 RETURNS attendance
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.attendance;
  v_date date := (p_checkin_at AT TIME ZONE 'UTC')::date;
  v_time time := (p_checkin_at AT TIME ZONE 'UTC')::time;
  v_start time := time '09:00:00';
BEGIN
  IF NOT public.is_internal_user() OR NOT public.has_permission('attendance', 'write') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_employee_id IS NULL THEN
    RAISE EXCEPTION 'employee_id is required';
  END IF;

  INSERT INTO public.attendance (employee_id, date, status, check_in, late)
  VALUES (p_employee_id, v_date, 'present'::public.attendance_status, v_time, v_time > v_start)
  ON CONFLICT (employee_id, date)
  DO UPDATE SET
    check_in = EXCLUDED.check_in,
    status = 'present'::public.attendance_status,
    late = EXCLUDED.late
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$


-- Function: public.check_no_overlap_orders_shifts()
CREATE OR REPLACE FUNCTION public.check_no_overlap_orders_shifts()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  -- If inserting/updating daily_shifts, check for existing orders
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
  
  -- If inserting/updating daily_orders, check for existing shifts
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
$function$


-- Function: public.check_out(p_employee_id uuid, p_checkout_at timestamp with time zone)
CREATE OR REPLACE FUNCTION public.check_out(p_employee_id uuid, p_checkout_at timestamp with time zone DEFAULT now())
 RETURNS attendance
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_row public.attendance;
  v_date date := (p_checkout_at AT TIME ZONE 'UTC')::date;
  v_time time := (p_checkout_at AT TIME ZONE 'UTC')::time;
  v_end time := time '18:00:00';
  v_hours numeric(6,2);
BEGIN
  IF NOT public.is_internal_user() OR NOT public.has_permission('attendance', 'write') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_employee_id IS NULL THEN
    RAISE EXCEPTION 'employee_id is required';
  END IF;

  SELECT * INTO v_row
  FROM public.attendance a
  WHERE a.employee_id = p_employee_id
    AND a.date = v_date
  LIMIT 1;

  IF v_row.id IS NULL OR v_row.check_in IS NULL THEN
    RAISE EXCEPTION 'No check-in found for this employee/date';
  END IF;

  v_hours := ROUND(GREATEST(EXTRACT(EPOCH FROM (v_time - v_row.check_in)), 0) / 3600.0, 2);

  UPDATE public.attendance
  SET
    check_out = v_time,
    total_hours = v_hours,
    early_leave = (v_time < v_end)
  WHERE id = v_row.id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$


-- Function: public.dashboard_overview(p_cip text, p_month integer, p_year integer, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview(p_cip text, p_month integer, p_year integer, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  SELECT public.dashboard_overview_rpc(p_cip, p_month, p_year, COALESCE(p_today, CURRENT_DATE));
$function$


-- Function: public.dashboard_overview(p_cip text, p_monthly_year text, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview(p_cip text, p_monthly_year text, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  SELECT public.dashboard_overview_rpc(p_monthly_year, COALESCE(p_today, CURRENT_DATE));
$function$


-- Function: public.dashboard_overview(p_month integer, p_year integer, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview(p_month integer, p_year integer, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  SELECT public.dashboard_overview_rpc(p_month, p_year, COALESCE(p_today, CURRENT_DATE));
$function$


-- Function: public.dashboard_overview_rpc(p_month_year text, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(p_month_year text, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end DATE := (v_start + INTERVAL '1 month - 1 day')::date;
  v_prev_start DATE := (v_start - INTERVAL '1 month')::date;
  v_prev_end DATE := (v_start - INTERVAL '1 day')::date;
  v_week_start DATE := (p_today - INTERVAL '6 day')::date;
BEGIN
  IF NOT (
    is_active_user(auth.uid())
    AND (
      has_role(auth.uid(), 'admin'::app_role)
      OR has_role(auth.uid(), 'hr'::app_role)
      OR has_role(auth.uid(), 'finance'::app_role)
      OR has_role(auth.uid(), 'operations'::app_role)
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  RETURN (
    WITH
      apps_active AS (
        SELECT a.id, a.name, COALESCE(a.brand_color, '#6366f1') AS brand_color, COALESCE(a.text_color, '#ffffff') AS text_color
        FROM public.apps a
        WHERE a.is_active IS TRUE
      ),
      emp_details AS (
        SELECT e.id, e.city, e.license_status, e.sponsorship_status
        FROM public.employees e
        WHERE e.status = _const_employee_active()
      ),
      att_today AS (
        SELECT
          COUNT(*) FILTER (WHERE a.status = 'present')::INT AS present,
          COUNT(*) FILTER (WHERE a.status = 'absent')::INT  AS absent,
          COUNT(*) FILTER (WHERE a.status = 'late')::INT    AS late,
          COUNT(*) FILTER (WHERE a.status = 'leave')::INT   AS leave,
          COUNT(*) FILTER (WHERE a.status = 'sick')::INT    AS sick
        FROM public.attendance a
        WHERE a.date = p_today
      ),
      att_week AS (
        SELECT
          a.date::TEXT AS date,
          COUNT(*) FILTER (WHERE a.status = 'present')::INT AS present,
          COUNT(*) FILTER (WHERE a.status = 'absent')::INT  AS absent,
          COUNT(*) FILTER (WHERE a.status = 'late')::INT    AS late,
          COUNT(*) FILTER (WHERE a.status = 'leave')::INT   AS leave,
          COUNT(*) FILTER (WHERE a.status = 'sick')::INT    AS sick
        FROM public.attendance a
        WHERE a.date BETWEEN v_week_start AND p_today
        GROUP BY a.date
        ORDER BY a.date
      ),
      prev_month_orders AS (
        SELECT COALESCE(SUM(d.orders_count), 0)::INT AS total
        FROM public.daily_orders d
        WHERE d.date BETWEEN v_prev_start AND v_prev_end
      ),
      best_rate AS (
        SELECT DISTINCT ON (pr.app_id)
          pr.app_id,
          COALESCE(pr.rate_per_order, 0)::NUMERIC AS rate
        FROM public.pricing_rules pr
        WHERE pr.is_active IS TRUE
          AND pr.rule_type = 'per_order'
          AND pr.min_orders = 0
          AND pr.max_orders IS NULL
          AND pr.rate_per_order IS NOT NULL
        ORDER BY pr.app_id, COALESCE(pr.priority, 0) DESC
      ),
      targets AS (
        SELECT t.app_id, COALESCE(t.target_orders, 0)::INT AS target_orders
        FROM public.app_targets t
        WHERE t.month_year = p_month_year
      ),
      orders_by_app AS (
        SELECT
          d.app_id,
          COALESCE(a.name, '—') AS app,
          COALESCE(a.brand_color, '#6366f1') AS brand_color,
          COALESCE(a.text_color, '#ffffff') AS text_color,
          COALESCE(SUM(d.orders_count), 0)::INT AS orders,
          COUNT(DISTINCT d.employee_id)::INT AS riders,
          COALESCE(t.target_orders, 0)::INT AS target,
          COALESCE(br.rate, 0)::NUMERIC AS rate_per_order,
          (COALESCE(SUM(d.orders_count), 0) * COALESCE(br.rate, 0))::NUMERIC AS est_revenue
        FROM public.daily_orders d
        LEFT JOIN apps_active a ON a.id = d.app_id
        LEFT JOIN targets t ON t.app_id = d.app_id
        LEFT JOIN best_rate br ON br.app_id = d.app_id
        WHERE d.date BETWEEN v_start AND LEAST(v_end, p_today)
        GROUP BY d.app_id, a.name, a.brand_color, a.text_color, t.target_orders, br.rate
        ORDER BY orders DESC
      ),
      orders_by_city AS (
        SELECT
          COALESCE(e.city::TEXT, 'unknown') AS city,
          COALESCE(SUM(d.orders_count), 0)::INT AS orders
        FROM public.daily_orders d
        JOIN public.employees e ON e.id = d.employee_id
        WHERE d.date BETWEEN v_start AND LEAST(v_end, p_today)
          AND e.city::TEXT IN ('makkah', 'jeddah')
        GROUP BY e.city
        ORDER BY orders DESC
      ),
      rider_app AS (
        SELECT
          d.employee_id,
          d.app_id,
          COALESCE(SUM(d.orders_count), 0)::INT AS orders,
          ROW_NUMBER() OVER (PARTITION BY d.employee_id ORDER BY COALESCE(SUM(d.orders_count), 0) DESC) AS rn
        FROM public.daily_orders d
        WHERE d.date BETWEEN v_start AND LEAST(v_end, p_today)
        GROUP BY d.employee_id, d.app_id
      ),
      riders AS (
        SELECT
          r.employee_id,
          COALESCE(e.name, '') AS name,
          r.orders,
          r.app_id,
          COALESCE(a.name, '—') AS app,
          COALESCE(a.brand_color, '#6366f1') AS app_color
        FROM rider_app r
        LEFT JOIN public.employees e ON e.id = r.employee_id
        LEFT JOIN apps_active a ON a.id = r.app_id
        WHERE r.rn = 1
        ORDER BY r.orders DESC
      ),
      recent_activity AS (
        SELECT al.action, al.table_name, al.created_at, al.user_id
        FROM public.audit_log al
        ORDER BY al.created_at DESC
        LIMIT 6
      ),
      counts AS (
        SELECT
          (SELECT COUNT(*)::INT FROM public.vehicles v WHERE v.status = _const_employee_active()) AS active_vehicles,
          (SELECT COUNT(*)::INT FROM public.alerts al WHERE al.is_resolved IS FALSE) AS active_alerts,
          (SELECT COUNT(*)::INT FROM apps_active) AS active_apps
      ),
      totals AS (
        SELECT
          COALESCE((SELECT SUM(o.orders)::INT FROM orders_by_app o), 0) AS total_orders,
          COALESCE((SELECT SUM(o.est_revenue)::NUMERIC FROM orders_by_app o), 0) AS est_revenue_total
      )
    SELECT jsonb_build_object(
      'monthYear', p_month_year,
      'today', p_today::TEXT,
      'apps', COALESCE((SELECT jsonb_agg(to_jsonb(a) ORDER BY a.name) FROM apps_active a), '[]'::jsonb),
      'empDetails', COALESCE((SELECT jsonb_agg(to_jsonb(e) ORDER BY e.id) FROM emp_details e), '[]'::jsonb),
      'attendanceToday', (SELECT to_jsonb(t) FROM att_today t),
      'attendanceWeek', COALESCE((SELECT jsonb_agg(to_jsonb(w) ORDER BY w.date) FROM att_week w), '[]'::jsonb),
      'ordersByApp', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'appId', o.app_id,
            'app', o.app,
            _const_work_orders(), o.orders,
            'riders', o.riders,
            'brandColor', o.brand_color,
            'textColor', o.text_color,
            'target', o.target,
            'estRevenue', ROUND(o.est_revenue)
          )
          ORDER BY o.orders DESC
        )
        FROM orders_by_app o
      ), '[]'::jsonb),
      'ordersByCity', COALESCE((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.orders DESC) FROM orders_by_city c), '[]'::jsonb),
      'riders', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'employee_id', r.employee_id,
            'name', r.name,
            _const_work_orders(), r.orders,
            'appId', r.app_id,
            'app', r.app,
            'appColor', r.app_color
          )
          ORDER BY r.orders DESC
        )
        FROM riders r
      ), '[]'::jsonb),
      'recentActivity', COALESCE((SELECT jsonb_agg(to_jsonb(ra) ORDER BY ra.created_at DESC) FROM recent_activity ra), '[]'::jsonb),
      'kpis', jsonb_build_object(
        'prevMonthOrders', (SELECT total FROM prev_month_orders),
        'activeVehicles', (SELECT active_vehicles FROM counts),
        'activeAlerts', (SELECT active_alerts FROM counts),
        'activeApps', (SELECT active_apps FROM counts),
        'totalOrders', (SELECT total_orders FROM totals),
        'estRevenueTotal', (SELECT est_revenue_total FROM totals)
      )
    )
  );
END;
$function$


-- Function: public.dashboard_overview_rpc(p_cip text, p_month integer, p_year integer, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(p_cip text, p_month integer, p_year integer, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN public.dashboard_overview_rpc(p_month, p_year, COALESCE(p_today, CURRENT_DATE));
END;
$function$


-- Function: public.dashboard_overview_rpc(p_cip text, p_monthly_year text, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(p_cip text, p_monthly_year text, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  SELECT public.dashboard_overview_rpc(p_monthly_year, COALESCE(p_today, CURRENT_DATE));
$function$


-- Function: public.dashboard_overview_rpc(p_month integer, p_year integer, p_today date)
CREATE OR REPLACE FUNCTION public.dashboard_overview_rpc(p_month integer, p_year integer, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_month_year text;
BEGIN
  IF p_month IS NULL OR p_year IS NULL THEN
    RAISE EXCEPTION 'p_month and p_year are required';
  END IF;

  v_month_year := to_char(make_date(p_year, p_month, 1), 'YYYY-MM');
  RETURN public.dashboard_overview_rpc(v_month_year, COALESCE(p_today, CURRENT_DATE));
END;
$function$


-- Function: public.deduct_spare_part_stock()
CREATE OR REPLACE FUNCTION public.deduct_spare_part_stock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.spare_parts sp
  SET stock_quantity = sp.stock_quantity - NEW.quantity_used,
      updated_at = now()
  WHERE sp.id = NEW.part_id;

  IF (SELECT sp2.stock_quantity FROM public.spare_parts sp2 WHERE sp2.id = NEW.part_id) < 0 THEN
    RAISE EXCEPTION 'المخزون غير كافٍ للقطعة المطلوبة';
  END IF;

  RETURN NEW;
END;
$function$


-- Function: public.employee_in_my_company(_employee_id uuid)
CREATE OR REPLACE FUNCTION public.employee_in_my_company(_employee_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.employees AS e
    WHERE e.id = _employee_id
  );
$function$


-- Function: public.enforce_rate_limit(p_key text, p_limit integer, p_window_seconds integer)
CREATE OR REPLACE FUNCTION public.enforce_rate_limit(p_key text, p_limit integer, p_window_seconds integer)
 RETURNS TABLE(allowed boolean, remaining integer, reset_at timestamp with time zone)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_now timestamptz := now();
  v_window_start timestamptz;
  v_count integer;
BEGIN
  IF p_key IS NULL OR length(btrim(p_key)) = 0 THEN
    RAISE EXCEPTION 'p_key is required';
  END IF;
  IF p_limit <= 0 THEN
    RAISE EXCEPTION 'p_limit must be > 0';
  END IF;
  IF p_window_seconds <= 0 THEN
    RAISE EXCEPTION 'p_window_seconds must be > 0';
  END IF;

  v_window_start := to_timestamp(
    floor(extract(epoch from v_now) / p_window_seconds) * p_window_seconds
  );

  INSERT INTO public.edge_rate_limits AS rl (key, window_start, request_count, updated_at)
  VALUES (p_key, v_window_start, 1, v_now)
  ON CONFLICT (key) DO UPDATE SET
    window_start = CASE
      WHEN rl.window_start = EXCLUDED.window_start THEN rl.window_start
      ELSE EXCLUDED.window_start
    END,
    request_count = CASE
      WHEN rl.window_start = EXCLUDED.window_start THEN rl.request_count + 1
      ELSE 1
    END,
    updated_at = v_now
  RETURNING rl.request_count INTO v_count;

  RETURN QUERY
  SELECT
    (v_count <= p_limit) AS allowed,
    GREATEST(p_limit - v_count, 0) AS remaining,
    v_window_start + (p_window_seconds || ' seconds')::interval AS reset_at;
END;
$function$


-- Function: public.eq_advance_status_text(a advance_status, b text)
CREATE OR REPLACE FUNCTION public.eq_advance_status_text(a advance_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_app_role_text(a app_role, b text)
CREATE OR REPLACE FUNCTION public.eq_app_role_text(a app_role, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_approval_status_text(a approval_status, b text)
CREATE OR REPLACE FUNCTION public.eq_approval_status_text(a approval_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_attendance_status_text(a attendance_status, b text)
CREATE OR REPLACE FUNCTION public.eq_attendance_status_text(a attendance_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_city_enum_text(a city_enum, b text)
CREATE OR REPLACE FUNCTION public.eq_city_enum_text(a city_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_deduction_type_text(a deduction_type, b text)
CREATE OR REPLACE FUNCTION public.eq_deduction_type_text(a deduction_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_emp_status_text(a employee_status, b text)
CREATE OR REPLACE FUNCTION public.eq_emp_status_text(a employee_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_employee_status_text(a employee_status, b text)
CREATE OR REPLACE FUNCTION public.eq_employee_status_text(a employee_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_installment_status_text(a installment_status, b text)
CREATE OR REPLACE FUNCTION public.eq_installment_status_text(a installment_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_license_status_enum_text(a license_status_enum, b text)
CREATE OR REPLACE FUNCTION public.eq_license_status_enum_text(a license_status_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_maintenance_type_text(a maintenance_type, b text)
CREATE OR REPLACE FUNCTION public.eq_maintenance_type_text(a maintenance_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_salary_type_text(a salary_type, b text)
CREATE OR REPLACE FUNCTION public.eq_salary_type_text(a salary_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_scheme_status_text(a scheme_status, b text)
CREATE OR REPLACE FUNCTION public.eq_scheme_status_text(a scheme_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_sponsorship_status_enum_text(a sponsorship_status_enum, b text)
CREATE OR REPLACE FUNCTION public.eq_sponsorship_status_enum_text(a sponsorship_status_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_text_advance_status(a text, b advance_status)
CREATE OR REPLACE FUNCTION public.eq_text_advance_status(a text, b advance_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_app_role(a text, b app_role)
CREATE OR REPLACE FUNCTION public.eq_text_app_role(a text, b app_role)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_approval_status(a text, b approval_status)
CREATE OR REPLACE FUNCTION public.eq_text_approval_status(a text, b approval_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_attendance_status(a text, b attendance_status)
CREATE OR REPLACE FUNCTION public.eq_text_attendance_status(a text, b attendance_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_city_enum(a text, b city_enum)
CREATE OR REPLACE FUNCTION public.eq_text_city_enum(a text, b city_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_deduction_type(a text, b deduction_type)
CREATE OR REPLACE FUNCTION public.eq_text_deduction_type(a text, b deduction_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_emp_status(a text, b employee_status)
CREATE OR REPLACE FUNCTION public.eq_text_emp_status(a text, b employee_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_employee_status(a text, b employee_status)
CREATE OR REPLACE FUNCTION public.eq_text_employee_status(a text, b employee_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_installment_status(a text, b installment_status)
CREATE OR REPLACE FUNCTION public.eq_text_installment_status(a text, b installment_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_license_status_enum(a text, b license_status_enum)
CREATE OR REPLACE FUNCTION public.eq_text_license_status_enum(a text, b license_status_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_maintenance_type(a text, b maintenance_type)
CREATE OR REPLACE FUNCTION public.eq_text_maintenance_type(a text, b maintenance_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_salary_type(a text, b salary_type)
CREATE OR REPLACE FUNCTION public.eq_text_salary_type(a text, b salary_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_scheme_status(a text, b scheme_status)
CREATE OR REPLACE FUNCTION public.eq_text_scheme_status(a text, b scheme_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_sponsorship_status_enum(a text, b sponsorship_status_enum)
CREATE OR REPLACE FUNCTION public.eq_text_sponsorship_status_enum(a text, b sponsorship_status_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_vehicle_status(a text, b vehicle_status)
CREATE OR REPLACE FUNCTION public.eq_text_vehicle_status(a text, b vehicle_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_text_vehicle_type(a text, b vehicle_type)
CREATE OR REPLACE FUNCTION public.eq_text_vehicle_type(a text, b vehicle_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a = b::text; $function$


-- Function: public.eq_vehicle_status_text(a vehicle_status, b text)
CREATE OR REPLACE FUNCTION public.eq_vehicle_status_text(a vehicle_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.eq_vehicle_type_text(a vehicle_type, b text)
CREATE OR REPLACE FUNCTION public.eq_vehicle_type_text(a vehicle_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text = b; $function$


-- Function: public.fill_maintenance_employee()
CREATE OR REPLACE FUNCTION public.fill_maintenance_employee()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.employee_id IS NULL THEN
    SELECT va.employee_id INTO NEW.employee_id
    FROM public.vehicle_assignments va
    WHERE va.vehicle_id = NEW.vehicle_id
      AND va.returned_at IS NULL
    ORDER BY va.created_at DESC NULLS LAST
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$function$


-- Function: public.fn_handle_employee_sponsorship_alerts()
CREATE OR REPLACE FUNCTION public.fn_handle_employee_sponsorship_alerts()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
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

    -- Use commercial_record name directly (no cr_number in this table)
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
$function$


-- Function: public.get_my_role()
CREATE OR REPLACE FUNCTION public.get_my_role()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT role
  FROM public.user_roles
  WHERE user_id = auth.uid()
  ORDER BY CASE role
    WHEN 'admin'      THEN 1
    WHEN 'finance'    THEN 2
    WHEN 'hr'         THEN 3
    WHEN 'operations' THEN 4
    WHEN 'viewer'     THEN 5
    ELSE 99
  END
  LIMIT 1;
$function$


-- Function: public.handle_new_user()
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, name, is_active)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    false
  );
  RETURN NEW;
END;
$function$


-- Function: public.handle_new_user_role()
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN NEW;
END;
$function$


-- Function: public.has_permission(p_resource text, p_action text)
CREATE OR REPLACE FUNCTION public.has_permission(p_resource text, p_action text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_allowed boolean := FALSE;
BEGIN
  IF NOT public.is_internal_user() THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.user_roles ur
    LEFT JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND (
        ur.role = 'admin'::public.app_role
        OR lower(COALESCE(r.title, '')) = 'admin'
      )
  ) THEN
    RETURN true;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    LEFT JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND COALESCE(r.is_active, true) IS TRUE
      AND (
        COALESCE((r.permissions -> '*' ->> p_action)::boolean, false)
        OR COALESCE((r.permissions -> p_resource ->> p_action)::boolean, false)
      )
  ) INTO v_allowed;

  IF v_allowed THEN
    RETURN true;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND (
        (ur.role = 'hr'::public.app_role AND (
          (p_resource = 'employees'  AND p_action IN ('view','write')) OR
          (p_resource = _const_work_orders()     AND p_action IN ('view','write')) OR
          (p_resource = 'attendance' AND p_action IN ('view','write')) OR
          (p_resource = 'salary'     AND p_action = 'view') OR
          (p_resource = 'roles'      AND p_action = 'view') OR
          (p_resource = 'financials' AND p_action = 'view')
        ))
        OR
        (ur.role = 'finance'::public.app_role AND (
          (p_resource = 'employees'  AND p_action = 'view') OR
          (p_resource = _const_work_orders()     AND p_action = 'view') OR
          (p_resource = 'attendance' AND p_action = 'view') OR
          (p_resource = 'salary'     AND p_action IN ('view','write','approve')) OR
          (p_resource = 'financials' AND p_action IN ('view','write','approve')) OR
          (p_resource = 'roles'      AND p_action = 'view')
        ))
        OR
        (ur.role = 'operations'::public.app_role AND (
          (p_resource = 'employees'  AND p_action IN ('view','write')) OR
          (p_resource = _const_work_orders()     AND p_action IN ('view','write')) OR
          (p_resource = 'attendance' AND p_action IN ('view','write')) OR
          (p_resource = 'salary'     AND p_action = 'view') OR
          (p_resource = 'financials' AND p_action = 'view')
        ))
        OR
        (ur.role = 'viewer'::public.app_role AND p_action = 'view')
      )
  ) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$function$


-- Function: public.has_role(_user_id uuid, _role app_role)
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$function$


-- Function: public.increment_salary_record_version()
CREATE OR REPLACE FUNCTION public.increment_salary_record_version()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$function$


-- Function: public.is_active_user(_user_id uuid)
CREATE OR REPLACE FUNCTION public.is_active_user(_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    (SELECT is_active FROM public.profiles WHERE id = _user_id LIMIT 1),
    false
  )
$function$


-- Function: public.is_admin_or_hr(uid uuid)
CREATE OR REPLACE FUNCTION public.is_admin_or_hr(uid uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN (
    public.has_role(uid, _const_role_admin())
    OR public.has_role(uid, _const_role_hr())
  );
END;
$function$


-- Function: public.is_internal_user()
CREATE OR REPLACE FUNCTION public.is_internal_user()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND COALESCE(p.is_active, true) = true
    )
    AND EXISTS (
      SELECT 1
      FROM public.user_roles ur
      WHERE ur.user_id = auth.uid()
    );
$function$


-- Function: public.is_salary_admin_job_title(p_job_title text)
CREATE OR REPLACE FUNCTION public.is_salary_admin_job_title(p_job_title text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT
    COALESCE(p_job_title, '') <> ''
    AND NOT (
      COALESCE(p_job_title, '') ~* '(مندوب|سائق|توصيل|موصل|مرسال|rider|driver|delivery|courier|dispatch|messenger)'
    );
$function$


-- Function: public.is_salary_month_visible_employee(p_employee_id uuid, p_month_year text, p_status text, p_sponsorship_status text, p_job_title text)
CREATE OR REPLACE FUNCTION public.is_salary_month_visible_employee(p_employee_id uuid, p_month_year text, p_status text, p_sponsorship_status text, p_job_title text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end DATE := (v_start + INTERVAL '1 month - 1 day')::date;
  v_has_orders BOOLEAN;
  v_has_attendance BOOLEAN;
  v_has_shifts BOOLEAN;
  v_has_saved_salary BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.daily_orders d
    WHERE d.employee_id = p_employee_id
      AND d.date BETWEEN v_start AND v_end
      AND (d.status IS NULL OR d.status <> _const_order_cancelled())
  )
  INTO v_has_orders;

  SELECT EXISTS (
    SELECT 1
    FROM public.attendance a
    WHERE a.employee_id = p_employee_id
      AND a.date BETWEEN v_start AND v_end
  )
  INTO v_has_attendance;

  SELECT EXISTS (
    SELECT 1
    FROM public.daily_shifts s
    WHERE s.employee_id = p_employee_id
      AND s.date BETWEEN v_start AND v_end
  )
  INTO v_has_shifts;

  SELECT EXISTS (
    SELECT 1
    FROM public.salary_records sr
    WHERE sr.employee_id = p_employee_id
      AND sr.month_year = p_month_year
  )
  INTO v_has_saved_salary;

  IF v_has_orders OR v_has_attendance OR v_has_shifts OR v_has_saved_salary THEN
    RETURN TRUE;
  END IF;

  IF COALESCE(p_status, '') <> _const_employee_active() THEN
    RETURN FALSE;
  END IF;

  IF COALESCE(p_sponsorship_status, '') IN ('absconded', 'terminated') THEN
    RETURN FALSE;
  END IF;

  RETURN public.is_salary_admin_job_title(p_job_title);
END;
$function$


-- Function: public.jwt_company_id()
CREATE OR REPLACE FUNCTION public.jwt_company_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT NULL::uuid;
$function$


-- Function: public.log_admin_action_cud()
CREATE OR REPLACE FUNCTION public.log_admin_action_cud()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_actor uuid := auth.uid();
  v_record_id text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_record_id := COALESCE(OLD.id::text, NULL);
    INSERT INTO public.admin_action_log (user_id, action, table_name, record_id, meta)
    VALUES (
      v_actor,
      lower(TG_OP),
      TG_TABLE_NAME,
      v_record_id,
      jsonb_build_object('old', to_jsonb(OLD))
    );
    RETURN OLD;
  ELSE
    v_record_id := COALESCE(NEW.id::text, NULL);
    INSERT INTO public.admin_action_log (user_id, action, table_name, record_id, meta)
    VALUES (
      v_actor,
      lower(TG_OP),
      TG_TABLE_NAME,
      v_record_id,
      CASE
        WHEN TG_OP = 'INSERT' THEN jsonb_build_object('new', to_jsonb(NEW))
        ELSE jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW))
      END
    );
    RETURN NEW;
  END IF;
END;
$function$


-- Function: public.log_audit_event()
CREATE OR REPLACE FUNCTION public.log_audit_event()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.audit_log (user_id, table_name, action, record_id, old_value, new_value)
  VALUES (
    auth.uid(),
    TG_TABLE_NAME,
    TG_OP,
    CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$function$


-- Function: public.neq_advance_status_text(a advance_status, b text)
CREATE OR REPLACE FUNCTION public.neq_advance_status_text(a advance_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_app_role_text(a app_role, b text)
CREATE OR REPLACE FUNCTION public.neq_app_role_text(a app_role, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_approval_status_text(a approval_status, b text)
CREATE OR REPLACE FUNCTION public.neq_approval_status_text(a approval_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_attendance_status_text(a attendance_status, b text)
CREATE OR REPLACE FUNCTION public.neq_attendance_status_text(a attendance_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_city_enum_text(a city_enum, b text)
CREATE OR REPLACE FUNCTION public.neq_city_enum_text(a city_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_deduction_type_text(a deduction_type, b text)
CREATE OR REPLACE FUNCTION public.neq_deduction_type_text(a deduction_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_emp_status_text(a employee_status, b text)
CREATE OR REPLACE FUNCTION public.neq_emp_status_text(a employee_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_employee_status_text(a employee_status, b text)
CREATE OR REPLACE FUNCTION public.neq_employee_status_text(a employee_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_installment_status_text(a installment_status, b text)
CREATE OR REPLACE FUNCTION public.neq_installment_status_text(a installment_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_license_status_enum_text(a license_status_enum, b text)
CREATE OR REPLACE FUNCTION public.neq_license_status_enum_text(a license_status_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_maintenance_type_text(a maintenance_type, b text)
CREATE OR REPLACE FUNCTION public.neq_maintenance_type_text(a maintenance_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_salary_type_text(a salary_type, b text)
CREATE OR REPLACE FUNCTION public.neq_salary_type_text(a salary_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_scheme_status_text(a scheme_status, b text)
CREATE OR REPLACE FUNCTION public.neq_scheme_status_text(a scheme_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_sponsorship_status_enum_text(a sponsorship_status_enum, b text)
CREATE OR REPLACE FUNCTION public.neq_sponsorship_status_enum_text(a sponsorship_status_enum, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_text_advance_status(a text, b advance_status)
CREATE OR REPLACE FUNCTION public.neq_text_advance_status(a text, b advance_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_app_role(a text, b app_role)
CREATE OR REPLACE FUNCTION public.neq_text_app_role(a text, b app_role)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_approval_status(a text, b approval_status)
CREATE OR REPLACE FUNCTION public.neq_text_approval_status(a text, b approval_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_attendance_status(a text, b attendance_status)
CREATE OR REPLACE FUNCTION public.neq_text_attendance_status(a text, b attendance_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_city_enum(a text, b city_enum)
CREATE OR REPLACE FUNCTION public.neq_text_city_enum(a text, b city_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_deduction_type(a text, b deduction_type)
CREATE OR REPLACE FUNCTION public.neq_text_deduction_type(a text, b deduction_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_emp_status(a text, b employee_status)
CREATE OR REPLACE FUNCTION public.neq_text_emp_status(a text, b employee_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_employee_status(a text, b employee_status)
CREATE OR REPLACE FUNCTION public.neq_text_employee_status(a text, b employee_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_installment_status(a text, b installment_status)
CREATE OR REPLACE FUNCTION public.neq_text_installment_status(a text, b installment_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_license_status_enum(a text, b license_status_enum)
CREATE OR REPLACE FUNCTION public.neq_text_license_status_enum(a text, b license_status_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_maintenance_type(a text, b maintenance_type)
CREATE OR REPLACE FUNCTION public.neq_text_maintenance_type(a text, b maintenance_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_salary_type(a text, b salary_type)
CREATE OR REPLACE FUNCTION public.neq_text_salary_type(a text, b salary_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_scheme_status(a text, b scheme_status)
CREATE OR REPLACE FUNCTION public.neq_text_scheme_status(a text, b scheme_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_sponsorship_status_enum(a text, b sponsorship_status_enum)
CREATE OR REPLACE FUNCTION public.neq_text_sponsorship_status_enum(a text, b sponsorship_status_enum)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_vehicle_status(a text, b vehicle_status)
CREATE OR REPLACE FUNCTION public.neq_text_vehicle_status(a text, b vehicle_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_text_vehicle_type(a text, b vehicle_type)
CREATE OR REPLACE FUNCTION public.neq_text_vehicle_type(a text, b vehicle_type)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a <> b::text; $function$


-- Function: public.neq_vehicle_status_text(a vehicle_status, b text)
CREATE OR REPLACE FUNCTION public.neq_vehicle_status_text(a vehicle_status, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.neq_vehicle_type_text(a vehicle_type, b text)
CREATE OR REPLACE FUNCTION public.neq_vehicle_type_text(a vehicle_type, b text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$ SELECT a::text <> b; $function$


-- Function: public.performance_dashboard_rpc(p_month_year text, p_today date)
CREATE OR REPLACE FUNCTION public.performance_dashboard_rpc(p_month_year text, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE;
  v_end DATE;
  v_effective_end DATE;
  v_prev_month TEXT;
  v_week_start DATE;
  v_prev_week_end DATE;
  v_prev_week_start DATE;
BEGIN
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), _const_role_admin())
      OR public.has_role(auth.uid(), _const_role_hr())
      OR public.has_role(auth.uid(), _const_role_finance())
      OR public.has_role(auth.uid(), _const_role_operations())
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::DATE;
  v_effective_end := LEAST(COALESCE(p_today, CURRENT_DATE), v_end);
  v_prev_month := to_char((v_start - INTERVAL '1 month')::DATE, 'YYYY-MM');
  v_week_start := (v_effective_end - INTERVAL '6 day')::DATE;
  v_prev_week_end := (v_week_start - INTERVAL '1 day')::DATE;
  v_prev_week_start := (v_prev_week_end - INTERVAL '6 day')::DATE;

  RETURN (
    WITH current_month AS MATERIALIZED (
      SELECT *
      FROM public.v_rider_monthly_performance
      WHERE month_year = p_month_year
    ),
    prev_month AS MATERIALIZED (
      SELECT *
      FROM public.v_rider_monthly_performance
      WHERE month_year = v_prev_month
    ),
    current_ranked AS (
      SELECT
        cm.employee_id,
        cm.employee_name,
        cm.city,
        cm.month_year,
        cm.total_orders,
        cm.active_days,
        cm.avg_orders_per_day,
        cm.consistency_days,
        cm.consistency_ratio,
        cm.best_day_orders,
        cm.last_active_date,
        cm.monthly_target_orders,
        cm.daily_target_orders,
        cm.target_achievement_pct,
        ROW_NUMBER() OVER (
          ORDER BY cm.total_orders DESC, cm.avg_orders_per_day DESC, cm.employee_name
        ) AS rank_position,
        COALESCE(pm.total_orders, 0) AS prev_total_orders,
        COALESCE(pm.active_days, 0) AS prev_active_days,
        COALESCE(pm.avg_orders_per_day, 0) AS prev_avg_orders_per_day,
        CASE
          WHEN COALESCE(pm.total_orders, 0) > 0 THEN
            ROUND(((cm.total_orders - pm.total_orders)::NUMERIC / pm.total_orders::NUMERIC) * 100, 2)
          WHEN cm.total_orders > 0 THEN 100
          ELSE 0
        END AS growth_pct,
        CASE
          WHEN COALESCE(pm.total_orders, 0) > 0 AND ((cm.total_orders - pm.total_orders)::NUMERIC / pm.total_orders::NUMERIC) >= 0.05 THEN 'up'
          WHEN COALESCE(pm.total_orders, 0) > 0 AND ((cm.total_orders - pm.total_orders)::NUMERIC / pm.total_orders::NUMERIC) <= -0.05 THEN 'down'
          ELSE 'stable'
        END AS trend_code
      FROM current_month AS cm
      LEFT JOIN prev_month AS pm
        ON pm.employee_id = cm.employee_id
    ),
    leaderboard_date AS MATERIALIZED (
      SELECT MAX(date) AS date
      FROM public.v_rider_daily_performance
      WHERE date BETWEEN v_start AND v_effective_end
        AND total_orders > 0
    ),
    current_day_ranked AS (
      SELECT
        d.employee_id,
        d.employee_name,
        d.total_orders,
        ROW_NUMBER() OVER (ORDER BY d.total_orders DESC, d.employee_name) AS top_rank,
        ROW_NUMBER() OVER (ORDER BY d.total_orders ASC, d.employee_name) AS low_rank
      FROM public.v_rider_daily_performance AS d
      JOIN leaderboard_date AS ld
        ON ld.date = d.date
    ),
    app_meta AS (
      SELECT
        a.id,
        a.name,
        COALESCE(a.brand_color, '#2563eb') AS brand_color,
        COALESCE(a.text_color, '#ffffff') AS text_color
      FROM public.apps AS a
      WHERE a.is_active IS TRUE
    ),
    orders_by_app AS (
      SELECT
        p.app_id,
        MAX(p.app_name) AS app_name,
        MAX(p.brand_color) AS brand_color,
        COALESCE(MAX(am.text_color), '#ffffff') AS text_color,
        SUM(p.total_orders)::INTEGER AS total_orders,
        COUNT(DISTINCT p.employee_id)::INTEGER AS rider_count
      FROM public.v_rider_daily_platform_orders AS p
      LEFT JOIN app_meta AS am
        ON am.id = p.app_id
      WHERE p.date BETWEEN v_start AND v_effective_end
      GROUP BY p.app_id
    ),
    prev_orders_by_app AS (
      SELECT
        p.app_id,
        SUM(p.total_orders)::INTEGER AS total_orders
      FROM public.v_rider_daily_platform_orders AS p
      WHERE p.date BETWEEN (v_start - INTERVAL '1 month')::DATE AND (v_start - INTERVAL '1 day')::DATE
      GROUP BY p.app_id
    ),
    app_targets AS (
      SELECT app_id, COALESCE(target_orders, 0)::INTEGER AS target_orders
      FROM public.app_targets
      WHERE month_year = p_month_year
    ),
    app_comparison AS (
      SELECT
        oba.app_id,
        oba.app_name,
        oba.brand_color,
        oba.text_color,
        oba.total_orders,
        oba.rider_count,
        COALESCE(at.target_orders, 0) AS target_orders,
        COALESCE(po.total_orders, 0) AS previous_orders,
        CASE
          WHEN COALESCE(po.total_orders, 0) > 0 THEN
            ROUND(((oba.total_orders - po.total_orders)::NUMERIC / po.total_orders::NUMERIC) * 100, 2)
          WHEN oba.total_orders > 0 THEN 100
          ELSE 0
        END AS growth_pct,
        CASE
          WHEN COALESCE(at.target_orders, 0) > 0 THEN
            ROUND((oba.total_orders::NUMERIC / at.target_orders::NUMERIC) * 100, 2)
          ELSE 0
        END AS target_achievement_pct
      FROM orders_by_app AS oba
      LEFT JOIN prev_orders_by_app AS po
        ON po.app_id = oba.app_id
      LEFT JOIN app_targets AS at
        ON at.app_id = oba.app_id
    ),
    orders_by_city AS (
      SELECT
        COALESCE(city, 'unknown') AS city,
        SUM(total_orders)::INTEGER AS orders
      FROM current_month
      GROUP BY city
    ),
    team_avg AS (
      SELECT
        ROUND(AVG(total_orders)::NUMERIC, 2) AS avg_total_orders
      FROM current_month
    ),
    performance_distribution AS (
      SELECT
        COUNT(*) FILTER (
          WHERE cr.total_orders > 0
            AND cr.total_orders >= COALESCE(ta.avg_total_orders, 0) * 1.2
        )::INTEGER AS excellent,
        COUNT(*) FILTER (
          WHERE cr.total_orders > 0
            AND cr.total_orders >= COALESCE(ta.avg_total_orders, 0) * 1.0
            AND cr.total_orders < COALESCE(ta.avg_total_orders, 0) * 1.2
        )::INTEGER AS good,
        COUNT(*) FILTER (
          WHERE cr.total_orders > 0
            AND cr.total_orders >= COALESCE(ta.avg_total_orders, 0) * 0.8
            AND cr.total_orders < COALESCE(ta.avg_total_orders, 0) * 1.0
        )::INTEGER AS average,
        COUNT(*) FILTER (
          WHERE cr.total_orders > 0
            AND cr.total_orders < COALESCE(ta.avg_total_orders, 0) * 0.8
        )::INTEGER AS weak
      FROM current_ranked AS cr
      CROSS JOIN team_avg AS ta
    ),
    month_comparison AS (
      SELECT
        COALESCE((SELECT SUM(total_orders)::INTEGER FROM current_month), 0) AS current_orders,
        COALESCE((SELECT SUM(total_orders)::INTEGER FROM prev_month), 0) AS previous_orders,
        COALESCE((SELECT SUM(active_days)::INTEGER FROM current_month), 0) AS current_active_days,
        COALESCE((SELECT SUM(active_days)::INTEGER FROM prev_month), 0) AS previous_active_days
    ),
    week_comparison AS (
      SELECT
        COALESCE((
          SELECT SUM(total_orders)::INTEGER
          FROM public.v_rider_daily_performance
          WHERE date BETWEEN v_week_start AND v_effective_end
        ), 0) AS current_orders,
        COALESCE((
          SELECT SUM(total_orders)::INTEGER
          FROM public.v_rider_daily_performance
          WHERE date BETWEEN v_prev_week_start AND v_prev_week_end
        ), 0) AS previous_orders
    ),
    daily_trend AS (
      SELECT
        date::TEXT AS date,
        SUM(total_orders)::INTEGER AS orders
      FROM public.v_rider_daily_performance
      WHERE date BETWEEN v_start AND v_effective_end
      GROUP BY date
      ORDER BY date
    ),
    monthly_trend AS (
      SELECT
        ms.month_year,
        COALESCE(SUM(mp.total_orders), 0)::INTEGER AS total_orders,
        COUNT(*) FILTER (WHERE COALESCE(mp.total_orders, 0) > 0)::INTEGER AS active_riders,
        ROUND(
          COALESCE(SUM(mp.total_orders), 0)::NUMERIC
          / NULLIF(COUNT(*) FILTER (WHERE COALESCE(mp.total_orders, 0) > 0), 0),
          2
        ) AS avg_orders_per_rider
      FROM (
        SELECT to_char((v_start - (gs * INTERVAL '1 month'))::DATE, 'YYYY-MM') AS month_year
        FROM generate_series(5, 0, -1) AS gs
      ) AS ms
      LEFT JOIN public.v_rider_monthly_performance AS mp
        ON mp.month_year = ms.month_year
      GROUP BY ms.month_year
      ORDER BY ms.month_year
    ),
    alerts_source AS (
      SELECT
        cr.employee_id,
        cr.employee_name,
        cr.total_orders,
        cr.active_days,
        cr.growth_pct,
        cr.last_active_date,
        cr.target_achievement_pct,
        cr.consistency_ratio,
        'declining'::TEXT AS alert_type,
        'high'::TEXT AS severity,
        1 AS severity_rank
      FROM current_ranked AS cr
      WHERE cr.prev_total_orders >= 50
        AND cr.growth_pct <= -20

      UNION ALL

      SELECT
        cr.employee_id,
        cr.employee_name,
        cr.total_orders,
        cr.active_days,
        cr.growth_pct,
        cr.last_active_date,
        cr.target_achievement_pct,
        cr.consistency_ratio,
        'inactive_recently'::TEXT AS alert_type,
        'high'::TEXT AS severity,
        1 AS severity_rank
      FROM current_ranked AS cr
      WHERE cr.total_orders > 0
        AND cr.last_active_date IS NOT NULL
        AND cr.last_active_date <= (v_effective_end - INTERVAL '3 day')::DATE

      UNION ALL

      SELECT
        cr.employee_id,
        cr.employee_name,
        cr.total_orders,
        cr.active_days,
        cr.growth_pct,
        cr.last_active_date,
        cr.target_achievement_pct,
        cr.consistency_ratio,
        'below_target'::TEXT AS alert_type,
        'medium'::TEXT AS severity,
        2 AS severity_rank
      FROM current_ranked AS cr
      WHERE cr.monthly_target_orders > 0
        AND cr.target_achievement_pct < 70

      UNION ALL

      SELECT
        cr.employee_id,
        cr.employee_name,
        cr.total_orders,
        cr.active_days,
        cr.growth_pct,
        cr.last_active_date,
        cr.target_achievement_pct,
        cr.consistency_ratio,
        'low_consistency'::TEXT AS alert_type,
        'medium'::TEXT AS severity,
        2 AS severity_rank
      FROM current_ranked AS cr
      WHERE cr.active_days >= 8
        AND cr.consistency_ratio < 0.5
    )
    SELECT jsonb_build_object(
      'summary', jsonb_build_object(
        'totalRiders', (SELECT COUNT(*) FROM current_month),
        'activeRiders', (SELECT COUNT(*) FILTER (WHERE total_orders > 0) FROM current_month),
        'totalOrders', (SELECT COALESCE(SUM(total_orders), 0)::INTEGER FROM current_month),
        'avgOrdersPerRider', (SELECT COALESCE(ROUND(AVG(total_orders)::NUMERIC, 2), 0) FROM current_month WHERE total_orders > 0),
        'monthYear', p_month_year,
        'today', p_today,
        'effectiveEndDate', v_effective_end
      ),
      'targets', (
        SELECT jsonb_build_object(
          'totalTargetOrders', COALESCE(SUM(target_orders), 0)::INTEGER,
          'targetAchievementPct',
            CASE
              WHEN COALESCE(SUM(target_orders), 0) > 0 THEN
                ROUND((
                  COALESCE((SELECT SUM(total_orders)::INTEGER FROM current_month), 0)::NUMERIC
                  / COALESCE(SUM(target_orders), 0)::NUMERIC
                ) * 100, 2)
              ELSE 0
            END
        )
        FROM public.app_targets
        WHERE month_year = p_month_year
      ),
      'performanceDistribution', (SELECT row_to_json(pd) FROM performance_distribution pd),
      'monthComparison', (SELECT row_to_json(mc) FROM month_comparison mc),
      'weekComparison', (SELECT row_to_json(wc) FROM week_comparison wc),
      'riderLeaderboard', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'employeeId', cr.employee_id,
            'employeeName', cr.employee_name,
            'city', cr.city,
            'totalOrders', cr.total_orders,
            'activeDays', cr.active_days,
            'avgOrdersPerDay', cr.avg_orders_per_day,
            'consistencyDays', cr.consistency_days,
            'consistencyRatio', cr.consistency_ratio,
            'bestDayOrders', cr.best_day_orders,
            'lastActiveDate', cr.last_active_date,
            'monthlyTargetOrders', cr.monthly_target_orders,
            'dailyTargetOrders', cr.daily_target_orders,
            'targetAchievementPct', cr.target_achievement_pct,
            'rankPosition', cr.rank_position,
            'prevTotalOrders', cr.prev_total_orders,
            'prevActiveDays', cr.prev_active_days,
            'prevAvgOrdersPerDay', cr.prev_avg_orders_per_day,
            'growthPct', cr.growth_pct,
            'trendCode', cr.trend_code
          )
          ORDER BY cr.rank_position
        )
        FROM current_ranked AS cr
      ), '[]'::jsonb),
      'topRiderToday', (
        SELECT row_to_json(cdr)
        FROM current_day_ranked AS cdr
        WHERE cdr.top_rank = 1
        LIMIT 1
      ),
      'lowestRiderToday', (
        SELECT row_to_json(cdr)
        FROM current_day_ranked AS cdr
        WHERE cdr.low_rank = 1
          AND cdr.total_orders > 0
        LIMIT 1
      ),
      'appComparison', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'appId', ac.app_id,
            'appName', ac.app_name,
            'brandColor', ac.brand_color,
            'textColor', ac.text_color,
            'totalOrders', ac.total_orders,
            'riderCount', ac.rider_count,
            'targetOrders', ac.target_orders,
            'previousOrders', ac.previous_orders,
            'growthPct', ac.growth_pct,
            'targetAchievementPct', ac.target_achievement_pct
          )
          ORDER BY ac.total_orders DESC
        )
        FROM app_comparison AS ac
      ), '[]'::jsonb),
      'ordersByCity', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object('city', obc.city, 'orders', obc.orders)
          ORDER BY obc.orders DESC
        )
        FROM orders_by_city AS obc
      ), '[]'::jsonb),
      'dailyTrend', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object('date', dt.date, 'orders', dt.orders)
          ORDER BY dt.date
        )
        FROM daily_trend AS dt
      ), '[]'::jsonb),
      'monthlyTrend', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'monthYear', mt.month_year,
            'totalOrders', mt.total_orders,
            'activeRiders', mt.active_riders,
            'avgOrdersPerRider', mt.avg_orders_per_rider
          )
          ORDER BY mt.month_year
        )
        FROM monthly_trend AS mt
      ), '[]'::jsonb),
      'alerts', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'employeeId', employee_id,
            'employeeName', employee_name,
            'alertType', alert_type,
            'severity', severity,
            'totalOrders', total_orders,
            'activeDays', active_days,
            'growthPct', growth_pct,
            'lastActiveDate', last_active_date,
            'targetAchievementPct', target_achievement_pct,
            'consistencyRatio', consistency_ratio
          )
          ORDER BY severity_rank ASC, total_orders DESC, employee_name
        )
        FROM (
          SELECT *
          FROM alerts_source
          ORDER BY severity_rank ASC, total_orders DESC, employee_name
          LIMIT 12
        ) AS ranked_alerts
      ), '[]'::jsonb)
    )
  );
END;
$function$


-- Function: public.preview_salary_for_month(p_month_year text)
CREATE OR REPLACE FUNCTION public.preview_salary_for_month(p_month_year text)
 RETURNS TABLE(employee_id uuid, total_orders integer, total_shift_days integer, base_salary numeric, external_deduction numeric, advance_deduction numeric, net_salary numeric, platform_breakdown jsonb)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE; v_end DATE;
  v_emp RECORD; v_app RECORD;
  v_app_orders INTEGER; v_app_shift_days INTEGER; v_app_earnings NUMERIC;
  v_total_orders INTEGER; v_total_shift_days INTEGER; v_base_salary NUMERIC;
  v_external_deduction NUMERIC; v_advance_deduction NUMERIC;
  v_net NUMERIC; v_platform_breakdown JSONB;
  v_calculation_method TEXT;
  v_tier RECORD;
  v_hybrid_rule RECORD;
  v_day RECORD; v_hours_worked NUMERIC;
  v_monthly_amount NUMERIC;
  -- Constants
  c_cancelled TEXT := _const_order_cancelled();
  c_active TEXT := _const_employee_active();
  c_approved TEXT := _const_approval_approved();
  c_pending TEXT := _const_installment_pending();
  c_deferred TEXT := _const_installment_deferred();
  c_orders TEXT := _const_work_orders();
  c_shift TEXT := _const_work_shift();
  c_hybrid TEXT := _const_work_hybrid();
  c_days_per_month NUMERIC := _const_days_per_month();
BEGIN
  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::date;

  FOR v_emp IN SELECT e.id FROM employees e WHERE e.status = c_active LOOP
    v_total_orders := 0; v_total_shift_days := 0; v_base_salary := 0;
    v_platform_breakdown := '[]'::jsonb;

    FOR v_app IN
      SELECT a.id AS app_id, a.name AS app_name, a.work_type,
             s.id AS scheme_id, s.scheme_type, s.monthly_amount
      FROM apps a
      LEFT JOIN salary_schemes s ON s.id = a.scheme_id
      WHERE a.is_active IS TRUE AND a.scheme_id IS NOT NULL
    LOOP
      v_app_orders := 0; v_app_shift_days := 0; v_app_earnings := 0;
      v_calculation_method := c_orders;

      IF v_app.work_type = c_orders OR v_app.work_type IS NULL THEN
        -- === ORDERS-BASED: salary from daily_orders ===
        SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
        FROM daily_orders d
        WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id
          AND d.date BETWEEN v_start AND v_end
          AND (d.status IS NULL OR d.status <> c_cancelled);

        v_total_orders := v_total_orders + v_app_orders;
        v_app_earnings := calc_tier_salary(v_app_orders, v_app.scheme_id);

      ELSIF v_app.work_type = c_shift THEN
        -- === SHIFT-BASED: always full monthly_amount ===
        v_calculation_method := _const_calc_method_shift_fixed();

        IF EXISTS(
          SELECT 1 FROM employee_apps ea
          WHERE ea.employee_id = v_emp.id AND ea.app_id = v_app.app_id
        ) THEN
          SELECT COUNT(*)::INTEGER INTO v_app_shift_days
          FROM daily_shifts ds
          WHERE ds.employee_id = v_emp.id AND ds.app_id = v_app.app_id
            AND ds.date BETWEEN v_start AND v_end AND ds.hours_worked > 0;

          v_total_shift_days := v_total_shift_days + v_app_shift_days;

          v_monthly_amount := COALESCE(v_app.monthly_amount, 0);
          IF v_monthly_amount > 0 AND v_app_shift_days > 0 THEN
            v_app_earnings := ROUND((v_monthly_amount / c_days_per_month) * v_app_shift_days);
          ELSE
            v_app_earnings := 0;
          END IF;
        END IF;

      ELSIF v_app.work_type = c_hybrid THEN
        -- === HYBRID ===
        v_calculation_method := _const_calc_method_mixed();
        SELECT * INTO v_hybrid_rule FROM app_hybrid_rules WHERE app_id = v_app.app_id;

        IF v_hybrid_rule IS NULL THEN
          v_calculation_method := _const_calc_method_orders_fallback();
          SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
          FROM daily_orders d
          WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id
            AND d.date BETWEEN v_start AND v_end
            AND (d.status IS NULL OR d.status <> c_cancelled);
          v_total_orders := v_total_orders + v_app_orders;
          v_app_earnings := calc_tier_salary(v_app_orders, v_app.scheme_id);
        ELSE
          FOR v_day IN SELECT generate_series(v_start, v_end, '1 day'::interval)::date AS day_date LOOP
            SELECT hours_worked INTO v_hours_worked
            FROM daily_shifts
            WHERE employee_id = v_emp.id AND app_id = v_app.app_id AND date = v_day.day_date;

            IF v_hours_worked IS NOT NULL AND v_hours_worked > 0 THEN
              v_app_earnings := v_app_earnings + v_hybrid_rule.shift_rate;
              v_app_shift_days := v_app_shift_days + 1;
            ELSIF v_hybrid_rule.fallback_to_orders THEN
              SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_app_orders
              FROM daily_orders d
              WHERE d.employee_id = v_emp.id AND d.app_id = v_app.app_id AND d.date = v_day.day_date
                AND (d.status IS NULL OR d.status <> c_cancelled);
              v_total_orders := v_total_orders + v_app_orders;
              IF v_app_orders > 0 THEN
                v_app_earnings := v_app_earnings + calc_tier_salary(v_app_orders, v_app.scheme_id);
              END IF;
            END IF;
          END LOOP;
          v_total_shift_days := v_total_shift_days + v_app_shift_days;
        END IF;
      END IF;

      v_base_salary := v_base_salary + v_app_earnings;

      IF v_app_orders > 0 OR v_app_shift_days > 0 OR v_app_earnings > 0 THEN
        v_platform_breakdown := v_platform_breakdown || jsonb_build_object(
          'app_id', v_app.app_id, 'app_name', v_app.app_name,
          'work_type', COALESCE(v_app.work_type, c_orders),
          'calculation_method', v_calculation_method,
          'orders_count', v_app_orders, 'shift_days', v_app_shift_days,
          'earnings', ROUND(v_app_earnings)
        );
      END IF;
    END LOOP;

    SELECT COALESCE(SUM(ed.amount), 0) INTO v_external_deduction
    FROM external_deductions ed
    WHERE ed.employee_id = v_emp.id AND ed.apply_month = p_month_year
      AND ed.approval_status = c_approved;

    SELECT COALESCE(SUM(ai.amount), 0) INTO v_advance_deduction
    FROM advances ad JOIN advance_installments ai ON ai.advance_id = ad.id
    WHERE ad.employee_id = v_emp.id AND ai.month_year = p_month_year
      AND ai.status IN (c_pending, c_deferred);

    v_net := GREATEST(v_base_salary - v_external_deduction - v_advance_deduction, 0);

    employee_id := v_emp.id; total_orders := v_total_orders;
    total_shift_days := v_total_shift_days; base_salary := v_base_salary;
    external_deduction := v_external_deduction; advance_deduction := v_advance_deduction;
    net_salary := v_net; platform_breakdown := v_platform_breakdown;
    RETURN NEXT;
  END LOOP;
END;
$function$


-- Function: public.preview_salary_for_month_v2(p_month_year text)
CREATE OR REPLACE FUNCTION public.preview_salary_for_month_v2(p_month_year text)
 RETURNS TABLE(employee_id uuid, total_orders integer, base_salary numeric, net_salary numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE;
  v_end DATE;
  v_emp RECORD;
  v_app RECORD;
  v_orders INTEGER;
  v_earnings NUMERIC;
  v_total_orders INTEGER;
  v_base_salary NUMERIC;
  v_deduction NUMERIC;
  v_net NUMERIC;
  c_cancelled TEXT := _const_order_cancelled();
  c_active TEXT := _const_employee_active();
  c_approved TEXT := _const_approval_approved();
  c_pending TEXT := _const_installment_pending();
  c_deferred TEXT := _const_installment_deferred();
BEGIN
  -- Authorization check: only admin/HR may preview salary data for others.
  IF NOT public.is_admin_or_hr(auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: admin or HR role required'
      USING ERRCODE = '42501';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::date;

  FOR v_emp IN
    SELECT e.id FROM employees e
    WHERE e.status = c_active
  LOOP
    v_total_orders := 0;
    v_base_salary := 0;

    FOR v_app IN
      SELECT a.id, a.scheme_id
      FROM apps a
      WHERE a.is_active IS TRUE AND a.scheme_id IS NOT NULL
    LOOP
      SELECT COALESCE(SUM(d.orders_count), 0)::INTEGER INTO v_orders
      FROM daily_orders d
      WHERE d.employee_id = v_emp.id
        AND d.app_id = v_app.id
        AND d.date BETWEEN v_start AND v_end
        AND (d.status IS NULL OR d.status <> c_cancelled);

      v_total_orders := v_total_orders + v_orders;
      v_earnings := calc_tier_salary(v_orders, v_app.scheme_id);
      v_base_salary := v_base_salary + v_earnings;
    END LOOP;

    SELECT COALESCE(SUM(ed.amount), 0) INTO v_deduction
    FROM external_deductions ed
    WHERE ed.employee_id = v_emp.id
      AND ed.apply_month = p_month_year
      AND ed.approval_status = c_approved;

    SELECT COALESCE(SUM(ai.amount), 0) INTO v_deduction
    FROM advances ad
    JOIN advance_installments ai ON ai.advance_id = ad.id
    WHERE ad.employee_id = v_emp.id
      AND ai.month_year = p_month_year
      AND ai.status IN (c_pending, c_deferred);

    v_net := GREATEST(v_base_salary - v_deduction, 0);

    employee_id := v_emp.id;
    total_orders := v_total_orders;
    base_salary := v_base_salary;
    net_salary := v_net;
    RETURN NEXT;
  END LOOP;
END;
$function$


-- Function: public.replace_daily_orders_month_rpc(p_month_year text, p_rows jsonb, p_source_type text, p_file_name text, p_target_app_id uuid)
CREATE OR REPLACE FUNCTION public.replace_daily_orders_month_rpc(p_month_year text, p_rows jsonb DEFAULT '[]'::jsonb, p_source_type text DEFAULT 'manual'::text, p_file_name text DEFAULT NULL::text, p_target_app_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(batch_id uuid, saved_rows integer, failed_rows integer)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE;
  v_end DATE;
  v_batch_id UUID;
  v_total_rows INTEGER := COALESCE(jsonb_array_length(COALESCE(p_rows, '[]'::jsonb)), 0);
BEGIN
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'operations'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  IF p_source_type NOT IN ('manual', 'excel', 'api') THEN
    RAISE EXCEPTION 'Invalid source_type';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::DATE;

  INSERT INTO public.order_import_batches (
    month_year,
    source_type,
    file_name,
    target_app_id,
    status,
    total_rows,
    started_by,
    meta
  )
  VALUES (
    p_month_year,
    p_source_type,
    NULLIF(BTRIM(p_file_name), ''),
    p_target_app_id,
    _const_installment_pending(),
    v_total_rows,
    auth.uid(),
    jsonb_build_object(
      'replace_mode', 'month',
      'input_rows', v_total_rows
    )
  )
  RETURNING id INTO v_batch_id;

  CREATE TEMP TABLE tmp_orders_import (
    employee_id UUID NOT NULL,
    app_id UUID NOT NULL,
    date DATE NOT NULL,
    orders_count INTEGER NOT NULL
  ) ON COMMIT DROP;

  IF v_total_rows > 0 THEN
    INSERT INTO tmp_orders_import (employee_id, app_id, date, orders_count)
    SELECT
      x.employee_id::UUID,
      x.app_id::UUID,
      x.date::DATE,
      x.orders_count::INTEGER
    FROM jsonb_to_recordset(COALESCE(p_rows, '[]'::jsonb)) AS x(
      employee_id TEXT,
      app_id TEXT,
      date TEXT,
      orders_count INTEGER
    );

    IF EXISTS (
      SELECT 1
      FROM tmp_orders_import
      WHERE date < v_start
         OR date > v_end
         OR orders_count <= 0
    ) THEN
      RAISE EXCEPTION 'Input rows must belong to the target month and have positive orders_count';
    END IF;
  END IF;

  DELETE
  FROM public.daily_orders
  WHERE date BETWEEN v_start AND v_end;

  IF v_total_rows > 0 THEN
    INSERT INTO public.daily_orders (
      employee_id,
      app_id,
      date,
      orders_count,
      status,
      source,
      created_by,
      import_batch_id
    )
    SELECT
      employee_id,
      app_id,
      date,
      orders_count,
      'confirmed',
      CASE
        WHEN p_source_type = 'excel' THEN 'excel_import'
        ELSE p_source_type
      END,
      auth.uid(),
      v_batch_id
    FROM tmp_orders_import
    ON CONFLICT (employee_id, date, app_id)
    DO UPDATE SET
      orders_count = EXCLUDED.orders_count,
      status = 'confirmed',
      source = EXCLUDED.source,
      import_batch_id = EXCLUDED.import_batch_id,
      updated_at = now();
  END IF;

  UPDATE public.order_import_batches
  SET
    status = 'completed',
    imported_rows = v_total_rows,
    skipped_rows = 0,
    error_count = 0,
    error_summary = '[]'::jsonb,
    completed_at = now(),
    updated_at = now()
  WHERE id = v_batch_id;

  batch_id := v_batch_id;
  saved_rows := v_total_rows;
  failed_rows := 0;
  RETURN NEXT;

EXCEPTION WHEN OTHERS THEN
  IF v_batch_id IS NOT NULL THEN
    UPDATE public.order_import_batches
    SET
      status = 'failed',
      imported_rows = 0,
      skipped_rows = 0,
      error_count = 1,
      error_summary = jsonb_build_array(SQLERRM),
      completed_at = now(),
      updated_at = now()
    WHERE id = v_batch_id;
  END IF;
  RAISE;
END;
$function$


-- Function: public.restore_spare_part_stock()
CREATE OR REPLACE FUNCTION public.restore_spare_part_stock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.spare_parts sp
  SET stock_quantity = sp.stock_quantity + OLD.quantity_used,
      updated_at = now()
  WHERE sp.id = OLD.part_id;
  RETURN OLD;
END;
$function$


-- Function: public.rider_profile_performance_rpc(p_employee_id uuid, p_month_year text, p_today date)
CREATE OR REPLACE FUNCTION public.rider_profile_performance_rpc(p_employee_id uuid, p_month_year text, p_today date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_start DATE;
  v_end DATE;
  v_effective_end DATE;
  v_prev_month TEXT;
  v_week_start DATE;
  v_prev_week_end DATE;
  v_prev_week_start DATE;
BEGIN
  IF NOT (
    public.is_active_user(auth.uid())
    AND (
      public.has_role(auth.uid(), 'admin'::app_role)
      OR public.has_role(auth.uid(), 'hr'::app_role)
      OR public.has_role(auth.uid(), 'finance'::app_role)
      OR public.has_role(auth.uid(), 'operations'::app_role)
    )
  ) THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF p_month_year !~ '^\d{4}-\d{2}$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  v_start := to_date(p_month_year || '-01', 'YYYY-MM-DD');
  v_end := (v_start + INTERVAL '1 month - 1 day')::DATE;
  v_effective_end := LEAST(COALESCE(p_today, CURRENT_DATE), v_end);
  v_prev_month := to_char((v_start - INTERVAL '1 month')::DATE, 'YYYY-MM');
  v_week_start := (v_effective_end - INTERVAL '6 day')::DATE;
  v_prev_week_end := (v_week_start - INTERVAL '1 day')::DATE;
  v_prev_week_start := (v_prev_week_end - INTERVAL '6 day')::DATE;

  RETURN (
    WITH employee_base AS (
      SELECT
        e.id,
        e.name,
        e.phone,
        e.city,
        e.join_date
      FROM public.employees AS e
      WHERE e.id = p_employee_id
    ),
    employee_platforms AS (
      SELECT
        a.id AS app_id,
        a.name AS app_name,
        COALESCE(a.brand_color, '#2563eb') AS brand_color,
        ea.status
      FROM public.employee_apps AS ea
      JOIN public.apps AS a
        ON a.id = ea.app_id
      WHERE ea.employee_id = p_employee_id
      ORDER BY a.name
    ),
    current_month AS MATERIALIZED (
      SELECT *
      FROM public.v_rider_monthly_performance
      WHERE employee_id = p_employee_id
        AND month_year = p_month_year
      LIMIT 1
    ),
    prev_month AS MATERIALIZED (
      SELECT *
      FROM public.v_rider_monthly_performance
      WHERE employee_id = p_employee_id
        AND month_year = v_prev_month
      LIMIT 1
    ),
    current_rank AS (
      SELECT
        ranked.employee_id,
        ranked.rank_position,
        ranked.total_riders
      FROM (
        SELECT
          employee_id,
          ROW_NUMBER() OVER (
            ORDER BY total_orders DESC, avg_orders_per_day DESC, employee_name
          ) AS rank_position,
          COUNT(*) OVER () AS total_riders
        FROM public.v_rider_monthly_performance
        WHERE month_year = p_month_year
      ) AS ranked
      WHERE ranked.employee_id = p_employee_id
    ),
    employee_target AS (
      SELECT
        monthly_target_orders,
        daily_target_orders
      FROM public.employee_targets
      WHERE employee_id = p_employee_id
        AND month_year = p_month_year
      LIMIT 1
    ),
    monthly_series AS (
      SELECT to_char((v_start - (gs * INTERVAL '1 month'))::DATE, 'YYYY-MM') AS month_year
      FROM generate_series(2, 0, -1) AS gs
    ),
    last_three_months AS (
      SELECT
        ms.month_year,
        COALESCE(mp.total_orders, 0)::INTEGER AS total_orders,
        COALESCE(mp.avg_orders_per_day, 0) AS avg_orders_per_day,
        COALESCE(mp.active_days, 0)::INTEGER AS active_days,
        COALESCE(mp.consistency_ratio, 0) AS consistency_ratio,
        COALESCE(mp.target_achievement_pct, 0) AS target_achievement_pct
      FROM monthly_series AS ms
      LEFT JOIN public.v_rider_monthly_performance AS mp
        ON mp.employee_id = p_employee_id
       AND mp.month_year = ms.month_year
      ORDER BY ms.month_year
    ),
    recent_daily_orders AS (
      SELECT
        d.date::TEXT AS date,
        d.total_orders
      FROM public.v_rider_daily_performance AS d
      WHERE d.employee_id = p_employee_id
        AND d.date BETWEEN GREATEST(v_start, (v_effective_end - INTERVAL '20 day')::DATE) AND v_effective_end
      ORDER BY d.date
    ),
    platform_breakdown AS (
      SELECT
        p.app_id,
        MAX(p.app_name) AS app_name,
        MAX(p.brand_color) AS brand_color,
        SUM(p.total_orders)::INTEGER AS total_orders
      FROM public.v_rider_daily_platform_orders AS p
      WHERE p.employee_id = p_employee_id
        AND p.date BETWEEN v_start AND v_effective_end
      GROUP BY p.app_id
      ORDER BY total_orders DESC, app_name
    ),
    week_comparison AS (
      SELECT
        COALESCE((
          SELECT SUM(total_orders)::INTEGER
          FROM public.v_rider_daily_performance
          WHERE employee_id = p_employee_id
            AND date BETWEEN v_week_start AND v_effective_end
        ), 0) AS current_orders,
        COALESCE((
          SELECT SUM(total_orders)::INTEGER
          FROM public.v_rider_daily_performance
          WHERE employee_id = p_employee_id
            AND date BETWEEN v_prev_week_start AND v_prev_week_end
        ), 0) AS previous_orders
    ),
    salary_snapshot AS (
      SELECT
        base_salary,
        allowances,
        advance_deduction,
        external_deduction,
        manual_deduction,
        attendance_deduction,
        net_salary,
        is_approved,
        payment_method
      FROM public.salary_records
      WHERE employee_id = p_employee_id
        AND month_year = p_month_year
      LIMIT 1
    ),
    derived_metrics AS (
      SELECT
        COALESCE((SELECT total_orders FROM current_month), 0)::INTEGER AS current_orders,
        COALESCE((SELECT total_orders FROM prev_month), 0)::INTEGER AS previous_orders,
        COALESCE((SELECT active_days FROM current_month), 0)::INTEGER AS current_active_days,
        COALESCE((SELECT active_days FROM prev_month), 0)::INTEGER AS previous_active_days,
        COALESCE((SELECT avg_orders_per_day FROM current_month), 0) AS current_avg_orders_per_day,
        COALESCE((SELECT avg_orders_per_day FROM prev_month), 0) AS previous_avg_orders_per_day,
        COALESCE((SELECT consistency_ratio FROM current_month), 0) AS current_consistency_ratio,
        COALESCE((SELECT target_achievement_pct FROM current_month), 0) AS current_target_achievement_pct,
        COALESCE((SELECT monthly_target_orders FROM current_month), (SELECT monthly_target_orders FROM employee_target), 0)::INTEGER AS current_monthly_target_orders,
        COALESCE((SELECT daily_target_orders FROM current_month), (SELECT daily_target_orders FROM employee_target), 0)::INTEGER AS current_daily_target_orders,
        COALESCE((SELECT last_active_date FROM current_month), NULL) AS last_active_date
    ),
    alerts_source AS (
      SELECT
        'declining'::TEXT AS alert_type,
        'high'::TEXT AS severity,
        1 AS severity_rank
      FROM derived_metrics
      WHERE previous_orders >= 30
        AND (
          CASE
            WHEN previous_orders > 0 THEN ((current_orders - previous_orders)::NUMERIC / previous_orders::NUMERIC) * 100
            WHEN current_orders > 0 THEN 100
            ELSE 0
          END
        ) <= -20

      UNION ALL

      SELECT
        'inactive_recently'::TEXT AS alert_type,
        'high'::TEXT AS severity,
        1 AS severity_rank
      FROM derived_metrics
      WHERE current_orders > 0
        AND last_active_date IS NOT NULL
        AND last_active_date <= (v_effective_end - INTERVAL '3 day')::DATE

      UNION ALL

      SELECT
        'below_target'::TEXT AS alert_type,
        'medium'::TEXT AS severity,
        2 AS severity_rank
      FROM derived_metrics
      WHERE current_monthly_target_orders > 0
        AND current_target_achievement_pct < 70

      UNION ALL

      SELECT
        'low_consistency'::TEXT AS alert_type,
        'medium'::TEXT AS severity,
        2 AS severity_rank
      FROM derived_metrics
      WHERE current_active_days >= 8
        AND current_consistency_ratio < 0.5
    ),
    judgment AS (
      SELECT
        CASE
          WHEN dm.current_orders = 0 THEN 'inactive'
          WHEN dm.previous_orders > 0
            AND (((dm.current_orders - dm.previous_orders)::NUMERIC / dm.previous_orders::NUMERIC) * 100) >= 10
            AND dm.current_consistency_ratio >= 0.65 THEN 'excellent_stable'
          WHEN dm.previous_orders > 0
            AND (((dm.current_orders - dm.previous_orders)::NUMERIC / dm.previous_orders::NUMERIC) * 100) <= -10 THEN 'declining'
          WHEN dm.current_monthly_target_orders > 0
            AND dm.current_target_achievement_pct < 60 THEN 'below_target'
          WHEN dm.current_consistency_ratio >= 0.7 THEN 'stable'
          ELSE 'average'
        END AS judgment_code,
        CASE
          WHEN dm.previous_orders > 0
            AND (((dm.current_orders - dm.previous_orders)::NUMERIC / dm.previous_orders::NUMERIC) * 100) >= 5 THEN 'up'
          WHEN dm.previous_orders > 0
            AND (((dm.current_orders - dm.previous_orders)::NUMERIC / dm.previous_orders::NUMERIC) * 100) <= -5 THEN 'down'
          ELSE 'stable'
        END AS trend_code
      FROM derived_metrics AS dm
    )
    SELECT jsonb_build_object(
      'monthYear', p_month_year,
      'effectiveEndDate', v_effective_end::TEXT,
      'employee', (
        SELECT jsonb_build_object(
          'employeeId', eb.id,
          'employeeName', eb.name,
          'phone', eb.phone,
          'city', eb.city,
          'joinDate', eb.join_date
        )
        FROM employee_base AS eb
      ),
      'summary', (
        SELECT jsonb_build_object(
          'totalOrders', dm.current_orders,
          'avgOrdersPerDay', dm.current_avg_orders_per_day,
          'activeDays', dm.current_active_days,
          'consistencyRatio', dm.current_consistency_ratio,
          'monthlyTargetOrders', dm.current_monthly_target_orders,
          'dailyTargetOrders', dm.current_daily_target_orders,
          'targetAchievementPct', dm.current_target_achievement_pct,
          'rank', COALESCE((SELECT rank_position FROM current_rank), 0),
          'rankOutOf', COALESCE((SELECT total_riders FROM current_rank), 0),
          'lastActiveDate', dm.last_active_date
        )
        FROM derived_metrics AS dm
      ),
      'comparison', jsonb_build_object(
        'month', (
          SELECT jsonb_build_object(
            'currentOrders', dm.current_orders,
            'previousOrders', dm.previous_orders,
            'growthPct',
              CASE
                WHEN dm.previous_orders > 0 THEN ROUND(((dm.current_orders - dm.previous_orders)::NUMERIC / dm.previous_orders::NUMERIC) * 100, 2)
                WHEN dm.current_orders > 0 THEN 100
                ELSE 0
              END,
            'currentAvgOrdersPerDay', dm.current_avg_orders_per_day,
            'previousAvgOrdersPerDay', dm.previous_avg_orders_per_day,
            'avgGrowthPct',
              CASE
                WHEN dm.previous_avg_orders_per_day > 0 THEN ROUND(((dm.current_avg_orders_per_day - dm.previous_avg_orders_per_day) / dm.previous_avg_orders_per_day) * 100, 2)
                WHEN dm.current_avg_orders_per_day > 0 THEN 100
                ELSE 0
              END,
            'currentActiveDays', dm.current_active_days,
            'previousActiveDays', dm.previous_active_days,
            'activeDaysDelta', dm.current_active_days - dm.previous_active_days
          )
          FROM derived_metrics AS dm
        ),
        'week', (
          SELECT jsonb_build_object(
            'currentOrders', current_orders,
            'previousOrders', previous_orders,
            'growthPct',
              CASE
                WHEN previous_orders > 0 THEN ROUND(((current_orders - previous_orders)::NUMERIC / previous_orders::NUMERIC) * 100, 2)
                WHEN current_orders > 0 THEN 100
                ELSE 0
              END
          )
          FROM week_comparison
        )
      ),
      'platforms', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'appId', ep.app_id,
            'appName', ep.app_name,
            'brandColor', ep.brand_color,
            'status', ep.status
          )
          ORDER BY ep.app_name
        )
        FROM employee_platforms AS ep
      ), '[]'::jsonb),
      'platformBreakdown', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'appId', pb.app_id,
            'appName', pb.app_name,
            'brandColor', pb.brand_color,
            _const_work_orders(), pb.total_orders
          )
          ORDER BY pb.total_orders DESC, pb.app_name
        )
        FROM platform_breakdown AS pb
      ), '[]'::jsonb),
      'recentDailyOrders', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'date', rdo.date,
            _const_work_orders(), rdo.total_orders
          )
          ORDER BY rdo.date
        )
        FROM recent_daily_orders AS rdo
      ), '[]'::jsonb),
      'lastThreeMonths', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'monthYear', month_year,
            'totalOrders', total_orders,
            'avgOrdersPerDay', avg_orders_per_day,
            'activeDays', active_days,
            'consistencyRatio', consistency_ratio,
            'targetAchievementPct', target_achievement_pct
          )
          ORDER BY month_year
        )
        FROM last_three_months
      ), '[]'::jsonb),
      'trend', (
        SELECT jsonb_build_object(
          'trendCode', j.trend_code,
          'judgmentCode', j.judgment_code
        )
        FROM judgment AS j
      ),
      'alerts', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'alertType', alert_type,
            'severity', severity
          )
          ORDER BY severity_rank, alert_type
        )
        FROM alerts_source
      ), '[]'::jsonb),
      'salary', (
        SELECT jsonb_build_object(
          'baseSalary', COALESCE(ss.base_salary, 0),
          'allowances', COALESCE(ss.allowances, 0),
          'attendanceDeduction', COALESCE(ss.attendance_deduction, 0),
          'advanceDeduction', COALESCE(ss.advance_deduction, 0),
          'externalDeduction', COALESCE(ss.external_deduction, 0),
          'manualDeduction', COALESCE(ss.manual_deduction, 0),
          'netSalary', COALESCE(ss.net_salary, 0),
          'isApproved', COALESCE(ss.is_approved, false),
          'paymentMethod', ss.payment_method
        )
        FROM salary_snapshot AS ss
      )
    )
  );
END;
$function$


-- Function: public.set_audit_columns()
CREATE OR REPLACE FUNCTION public.set_audit_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.created_by IS NULL THEN
      NEW.created_by := auth.uid();
    END IF;
    IF NEW.updated_by IS NULL THEN
      NEW.updated_by := auth.uid();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$function$


-- Function: public.sync_salaries_as_expenses(p_month_year text)
CREATE OR REPLACE FUNCTION public.sync_salaries_as_expenses(p_month_year text)
 RETURNS finance_transactions
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_total NUMERIC;
  v_count INTEGER;
  v_row public.finance_transactions;
BEGIN
  IF p_month_year !~ '^\d{4}-(0[1-9]|1[0-2])$' THEN
    RAISE EXCEPTION 'Invalid month_year format. Expected YYYY-MM';
  END IF;

  SELECT COALESCE(SUM(net_salary), 0), COUNT(*)
    INTO v_total, v_count
  FROM public.salary_records
  WHERE month_year = p_month_year
    AND is_approved IS TRUE;

  IF v_total <= 0 THEN
    -- No approved salaries: remove any stale auto salary expense for the month.
    DELETE FROM public.finance_transactions
    WHERE month_year = p_month_year
      AND is_auto IS TRUE
      AND reference_type = 'salaries';
    RETURN NULL;
  END IF;

  INSERT INTO public.finance_transactions (
    type, category, description, amount, month_year, date,
    is_auto, reference_type, notes
  ) VALUES (
    'expense', 'رواتب', 'إجمالي رواتب شهر ' || p_month_year, v_total,
    p_month_year, p_month_year || '-28',
    TRUE, 'salaries', v_count || ' موظف — تم المزامنة تلقائياً'
  )
  ON CONFLICT (month_year, reference_type) WHERE (is_auto IS TRUE)
  DO UPDATE SET
    amount = EXCLUDED.amount,
    description = EXCLUDED.description,
    notes = EXCLUDED.notes,
    date = EXCLUDED.date,
    type = EXCLUDED.type,
    category = EXCLUDED.category
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$function$


-- Function: public.text_to_employee_status(text)
CREATE OR REPLACE FUNCTION public.text_to_employee_status(text)
 RETURNS employee_status
 LANGUAGE sql
 IMMUTABLE STRICT
 SET search_path TO 'public'
AS $function$
  SELECT $1::public.employee_status;
$function$


-- Function: public.update_daily_shifts_updated_at()
CREATE OR REPLACE FUNCTION public.update_daily_shifts_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$


-- Function: public.update_maintenance_total_cost()
CREATE OR REPLACE FUNCTION public.update_maintenance_total_cost()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  log_id uuid;
BEGIN
  log_id := COALESCE(NEW.maintenance_log_id, OLD.maintenance_log_id);
  UPDATE public.maintenance_logs ml
  SET total_cost = (
      SELECT COALESCE(SUM(mp.quantity_used * mp.cost_at_time), 0)::numeric(10, 2)
      FROM public.maintenance_parts mp
      WHERE mp.maintenance_log_id = log_id
    ),
    updated_at = now()
  WHERE ml.id = log_id;
  RETURN COALESCE(NEW, OLD);
END;
$function$


-- Function: public.update_salary_drafts_updated_at()
CREATE OR REPLACE FUNCTION public.update_salary_drafts_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$


-- Function: public.update_updated_at_column()
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$


-- ================================================================
-- VIEWS
-- ================================================================
CREATE OR REPLACE VIEW public."employee_wallet_balances" AS
 SELECT e.id AS employee_id,
    e.name AS employee_name,
    e.status AS employee_status,
    COALESCE(sum(
        CASE
            WHEN t.transaction_type = 'collection'::text THEN t.amount
            WHEN t.transaction_type = 'deposit'::text THEN - t.amount
            ELSE 0::numeric
        END), 0::numeric) AS balance
   FROM employees e
     LEFT JOIN employee_wallet_transactions t ON e.id = t.employee_id
  GROUP BY e.id, e.name, e.status;
;

CREATE OR REPLACE VIEW public."v_rider_daily_performance" AS
 SELECT employee_id,
    employee_name,
    city,
    date,
    sum(total_orders)::integer AS total_orders,
    count(*) FILTER (WHERE total_orders > 0)::integer AS active_platforms,
    COALESCE(jsonb_agg(jsonb_build_object('app_id', app_id, 'app_name', app_name, 'brand_color', brand_color, _const_work_orders(), total_orders) ORDER BY p.total_orders DESC, app_name), '[]'::jsonb) AS platform_breakdown
   FROM v_rider_daily_platform_orders p
  GROUP BY employee_id, employee_name, city, date;
;

CREATE OR REPLACE VIEW public."v_rider_daily_platform_orders" AS
 SELECT d.employee_id,
    COALESCE(e.name, ''::text) AS employee_name,
    e.city,
    d.date,
    d.app_id,
    COALESCE(a.name, '—'::text) AS app_name,
    COALESCE(a.brand_color, '#2563eb'::text) AS brand_color,
    sum(d.orders_count)::integer AS total_orders
   FROM daily_orders d
     JOIN employees e ON e.id = d.employee_id
     JOIN apps a ON a.id = d.app_id
  WHERE d.orders_count > 0 AND (d.status IS NULL OR d.status <> _const_order_cancelled())
  GROUP BY d.employee_id, e.name, e.city, d.date, d.app_id, a.name, a.brand_color;
;

CREATE OR REPLACE VIEW public."v_rider_monthly_performance" AS
 WITH monthly_base AS (
         SELECT d.employee_id,
            d.employee_name,
            d.city,
            to_char(d.date::timestamp with time zone, 'YYYY-MM'::text) AS month_year,
            sum(d.total_orders)::integer AS total_orders,
            count(*) FILTER (WHERE d.total_orders > 0)::integer AS active_days,
            max(d.total_orders) AS best_day_orders,
            max(d.date) FILTER (WHERE d.total_orders > 0) AS last_active_date
           FROM v_rider_daily_performance d
          GROUP BY d.employee_id, d.employee_name, d.city, (to_char(d.date::timestamp with time zone, 'YYYY-MM'::text))
        ), consistency_base AS (
         SELECT d.employee_id,
            to_char(d.date::timestamp with time zone, 'YYYY-MM'::text) AS month_year,
            count(*) FILTER (WHERE d.total_orders::numeric >= (mb_1.total_orders::numeric / NULLIF(mb_1.active_days, 0)::numeric))::integer AS consistency_days
           FROM v_rider_daily_performance d
             JOIN monthly_base mb_1 ON mb_1.employee_id = d.employee_id AND mb_1.month_year = to_char(d.date::timestamp with time zone, 'YYYY-MM'::text)
          GROUP BY d.employee_id, (to_char(d.date::timestamp with time zone, 'YYYY-MM'::text))
        )
 SELECT mb.employee_id,
    mb.employee_name,
    mb.city,
    mb.month_year,
    mb.total_orders,
    mb.active_days,
    round(mb.total_orders::numeric / NULLIF(mb.active_days, 0)::numeric, 2) AS avg_orders_per_day,
    COALESCE(cb.consistency_days, 0) AS consistency_days,
    round(COALESCE(cb.consistency_days, 0)::numeric / NULLIF(mb.active_days, 0)::numeric, 2) AS consistency_ratio,
    mb.best_day_orders,
    mb.last_active_date,
    COALESCE(t.monthly_target_orders, 0) AS monthly_target_orders,
    COALESCE(t.daily_target_orders, 0) AS daily_target_orders,
        CASE
            WHEN COALESCE(t.monthly_target_orders, 0) > 0 THEN round(mb.total_orders::numeric / t.monthly_target_orders::numeric * 100::numeric, 2)
            ELSE 0::numeric
        END AS target_achievement_pct
   FROM monthly_base mb
     LEFT JOIN consistency_base cb ON cb.employee_id = mb.employee_id AND cb.month_year = mb.month_year
     LEFT JOIN employee_targets t ON t.employee_id = mb.employee_id AND t.month_year = mb.month_year;
;
