# Baseline DML inventory

- Migrations scanned: 237
- DML operations found: 83
- Required manual review: 30

Supabase schema squash omits these operations. Required-review entries must be restored in a separate idempotent seed migration before the baseline can be approved.

| Migration | Operation | Target | Priority |
|---|---|---|---|
| `20260226083236_a06ac86d-f40a-4105-8231-3099763861e3.sql` | INSERT INTO | `public.apps` | review |
| `20260305073335_6a77e95f-f6cd-4721-bd47-d67009b898d8.sql` | INSERT INTO | `storage.buckets` | required-review |
| `20260308074955_1cb7258b-936c-4f15-a48f-8bbda5531813.sql` | INSERT INTO | `storage.buckets` | required-review |
| `20260308075948_985c6682-cdd2-4600-b9e6-5cd61215cebd.sql` | INSERT INTO | `public.system_settings` | required-review |
| `20260309003904_4ac0abf0-9134-4156-9456-1e4dd05dc643.sql` | UPDATE | `storage.buckets` | required-review |
| `20260320000004_activate_salah_user.sql` | UPDATE | `auth.users` | review |
| `20260320000004_activate_salah_user.sql` | INSERT INTO | `public.profiles` | review |
| `20260320000004_activate_salah_user.sql` | INSERT INTO | `public.user_roles` | review |
| `20260324180000_add_iqama_alert_days_to_system_settings.sql` | UPDATE | `public.system_settings` | required-review |
| `20260324193000_erd_foundation_roles_salary_structure.sql` | INSERT INTO | `public.roles` | required-review |
| `20260324213000_seed_roles_permissions_matrix.sql` | UPDATE | `public.roles` | required-review |
| `20260324213000_seed_roles_permissions_matrix.sql` | UPDATE | `public.roles` | required-review |
| `20260324213000_seed_roles_permissions_matrix.sql` | UPDATE | `public.roles` | required-review |
| `20260324213000_seed_roles_permissions_matrix.sql` | UPDATE | `public.roles` | required-review |
| `20260324213000_seed_roles_permissions_matrix.sql` | UPDATE | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | INSERT INTO | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | UPDATE | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | UPDATE | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | UPDATE | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | UPDATE | `public.roles` | required-review |
| `20260324220000_roles_upsert_and_permissions_bootstrap.sql` | UPDATE | `public.roles` | required-review |
| `20260324230000_seed_default_pricing_rules_for_active_apps.sql` | INSERT INTO | `public.pricing_rules` | review |
| `20260324235500_user_roles_role_id_bridge.sql` | UPDATE | `public.user_roles` | review |
| `20260325140000_rename_project_muhimmat_altawseel.sql` | UPDATE | `public.system_settings` | required-review |
| `20260325154500_unify_company_id_on_employees.sql` | UPDATE | `public.employees` | review |
| `20260325160000_drop_legacy_trade_register_id_on_employees.sql` | UPDATE | `public.employees` | review |
| `20260325163000_tenant_rls_platform_accounts_and_employee_links.sql` | UPDATE | `public.platform_accounts` | review |
| `20260325163000_tenant_rls_platform_accounts_and_employee_links.sql` | UPDATE | `public.account_assignments` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.attendance` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.daily_orders` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.advances` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.external_deductions` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.salary_records` | review |
| `20260325174500_add_company_id_to_operational_tables.sql` | UPDATE | `public.advance_installments` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.user_roles` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.user_permissions` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.employee_scheme` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.employee_apps` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.employee_tiers` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.vehicle_assignments` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.vehicle_mileage` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.vehicle_mileage_daily` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.vehicles` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.maintenance_logs` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.departments` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.positions` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.salary_schemes` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.salary_scheme_tiers` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.scheme_month_snapshots` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.app_targets` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.apps` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.pl_records` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.alerts` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.alerts` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.locked_months` | review |
| `20260325181500_company_id_rollout_remaining_tables.sql` | UPDATE | `public.audit_log` | review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | INSERT INTO | `public.roles` | required-review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | UPDATE | `public.roles` | required-review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | UPDATE | `public.roles` | required-review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | UPDATE | `public.roles` | required-review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | UPDATE | `public.roles` | required-review |
| `20260326013000_supabase_single_backend_phase1_core_rls_audit_rpc.sql` | UPDATE | `public.roles` | required-review |
| `20260327120001_avatars_allow_svg_mime.sql` | UPDATE | `storage.buckets` | required-review |
| `20260330120000_salary_slip_templates.sql` | INSERT INTO | `public.salary_slip_templates` | review |
| `20260404010000_cleanup_employee_code_and_employee_cities.sql` | UPDATE | `public.employees` | review |
| `20260404010000_cleanup_employee_code_and_employee_cities.sql` | UPDATE | `public.employees` | review |
| `20260404010000_cleanup_employee_code_and_employee_cities.sql` | UPDATE | `public.employees` | review |
| `20260404010000_cleanup_employee_code_and_employee_cities.sql` | UPDATE | `public.employees` | review |
| `20260407110000_employee_commercial_records_and_iqama_docs.sql` | INSERT INTO | `public.commercial_records` | review |
| `20260407110000_employee_commercial_records_and_iqama_docs.sql` | UPDATE | `storage.buckets` | required-review |
| `20260416000003_unique_default_slip_template.sql` | UPDATE | `salary_slip_templates` | review |
| `20260504000002_fix_logo_upload.sql` | UPDATE | `storage.buckets` | required-review |
| `20260605000000_fix_rpc_security_definer.sql` | DELETE FROM | `public.user_roles` | review |
| `20260703000000_advances_attachment.sql` | INSERT INTO | `storage.buckets` | required-review |
| `20260703000001_treasury.sql` | INSERT INTO | `public.treasury_categories` | review |
| `20260703000001_treasury.sql` | INSERT INTO | `public.treasury_accounts` | review |
| `20260706120000_fix_apps_text_colors.sql` | UPDATE | `public.apps` | review |
| `20260706120000_fix_apps_text_colors.sql` | UPDATE | `public.apps` | review |
| `20260707010000_spare_parts_invoice_reference.sql` | INSERT INTO | `storage.buckets` | required-review |
| `20260708000000_vehicle_documents.sql` | INSERT INTO | `storage.buckets` | required-review |
| `20260712002000_backfill_user_permissions_source_of_truth.sql` | INSERT INTO | `public.user_permissions` | review |
| `20260714020000_alert_workflow_center.sql` | UPDATE | `public.alerts` | review |
| `20260722153804_archive_pre_fleet_maintenance_cleanup.sql` | INSERT INTO | `app_archive.maintenance_logs_pre_fleet_20260328` | review |
