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