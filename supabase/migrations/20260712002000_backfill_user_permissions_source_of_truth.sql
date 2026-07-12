-- Bootstrap missing per-user permission rows after making user_permissions the
-- database source of truth. Existing frontend-managed rows are preserved.

WITH role_permissions(role_name, permission_key, can_view, can_edit, can_delete) AS (
  VALUES
    ('admin', 'employees', true, true, true),
    ('admin', 'attendance', true, true, true),
    ('admin', 'orders', true, true, true),
    ('admin', 'ai_analytics', true, true, true),
    ('admin', 'salaries', true, true, true),
    ('admin', 'advances', true, true, true),
    ('admin', 'vehicles', true, true, true),
    ('admin', 'alerts', true, true, true),
    ('admin', 'settings', true, true, true),
    ('admin', 'apps', true, true, true),
    ('admin', 'violation_resolver', true, true, true),
    ('admin', 'vehicle_assignment', true, true, true),
    ('admin', 'fuel', true, true, true),
    ('admin', 'maintenance', true, true, true),
    ('admin', 'employee_tiers', true, true, true),
    ('admin', 'salary_schemes', true, true, true),
    ('admin', 'finance', true, true, true),
    ('admin', 'wallet', true, true, true),
    ('admin', 'treasury', true, true, true),

    ('hr', 'employees', true, true, false),
    ('hr', 'attendance', true, true, false),
    ('hr', 'orders', true, false, false),
    ('hr', 'ai_analytics', true, false, false),
    ('hr', 'salaries', true, false, false),
    ('hr', 'advances', true, false, false),
    ('hr', 'vehicles', true, false, false),
    ('hr', 'alerts', true, true, false),
    ('hr', 'settings', false, false, false),
    ('hr', 'apps', true, false, false),
    ('hr', 'violation_resolver', false, false, false),
    ('hr', 'vehicle_assignment', true, false, false),
    ('hr', 'fuel', true, false, false),
    ('hr', 'maintenance', false, false, false),
    ('hr', 'employee_tiers', true, true, true),
    ('hr', 'salary_schemes', true, false, false),
    ('hr', 'finance', false, false, false),
    ('hr', 'wallet', false, false, false),
    ('hr', 'treasury', false, false, false),

    ('finance', 'employees', true, false, false),
    ('finance', 'attendance', true, false, false),
    ('finance', 'orders', true, false, false),
    ('finance', 'ai_analytics', true, false, false),
    ('finance', 'salaries', true, true, false),
    ('finance', 'advances', true, true, false),
    ('finance', 'vehicles', false, false, false),
    ('finance', 'alerts', true, false, false),
    ('finance', 'settings', false, false, false),
    ('finance', 'apps', true, false, false),
    ('finance', 'violation_resolver', true, true, true),
    ('finance', 'vehicle_assignment', true, false, false),
    ('finance', 'fuel', true, true, true),
    ('finance', 'maintenance', true, false, false),
    ('finance', 'employee_tiers', true, false, false),
    ('finance', 'salary_schemes', true, true, false),
    ('finance', 'finance', true, true, true),
    ('finance', 'wallet', true, true, false),
    ('finance', 'treasury', true, true, true),

    ('operations', 'employees', true, true, false),
    ('operations', 'attendance', false, false, false),
    ('operations', 'orders', true, true, false),
    ('operations', 'ai_analytics', true, false, false),
    ('operations', 'finance', false, false, false),
    ('operations', 'salaries', false, false, false),
    ('operations', 'advances', false, false, false),
    ('operations', 'vehicles', true, true, false),
    ('operations', 'alerts', true, false, false),
    ('operations', 'settings', false, false, false),
    ('operations', 'apps', true, false, false),
    ('operations', 'violation_resolver', false, false, false),
    ('operations', 'vehicle_assignment', true, false, false),
    ('operations', 'fuel', true, false, false),
    ('operations', 'maintenance', true, true, true),
    ('operations', 'employee_tiers', true, false, false),
    ('operations', 'salary_schemes', false, false, false),
    ('operations', 'wallet', true, false, false),
    ('operations', 'treasury', false, false, false),

    ('viewer', 'employees', false, false, false),
    ('viewer', 'attendance', false, false, false),
    ('viewer', 'orders', false, false, false),
    ('viewer', 'ai_analytics', false, false, false),
    ('viewer', 'finance', false, false, false),
    ('viewer', 'salaries', false, false, false),
    ('viewer', 'advances', false, false, false),
    ('viewer', 'vehicles', false, false, false),
    ('viewer', 'alerts', true, false, false),
    ('viewer', 'settings', false, false, false),
    ('viewer', 'apps', false, false, false),
    ('viewer', 'violation_resolver', false, false, false),
    ('viewer', 'vehicle_assignment', false, false, false),
    ('viewer', 'fuel', false, false, false),
    ('viewer', 'maintenance', true, false, false),
    ('viewer', 'employee_tiers', false, false, false),
    ('viewer', 'salary_schemes', false, false, false),
    ('viewer', 'wallet', false, false, false),
    ('viewer', 'treasury', false, false, false)
),
user_role_templates AS (
  SELECT
    users.id AS user_id,
    COALESCE((user_roles.role)::text, 'viewer') AS role_name
  FROM auth.users
  LEFT JOIN LATERAL (
    SELECT role
    FROM public.user_roles
    WHERE user_roles.user_id = users.id
    ORDER BY role::text
    LIMIT 1
  ) AS user_roles ON true
)
INSERT INTO public.user_permissions (
  user_id,
  permission_key,
  can_view,
  can_edit,
  can_delete
)
SELECT
  user_role_templates.user_id,
  role_permissions.permission_key,
  role_permissions.can_view,
  role_permissions.can_edit,
  role_permissions.can_delete
FROM user_role_templates
JOIN role_permissions
  ON role_permissions.role_name = user_role_templates.role_name
ON CONFLICT (user_id, permission_key) DO NOTHING;
