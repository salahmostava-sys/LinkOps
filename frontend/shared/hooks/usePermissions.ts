import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@app/providers/AuthContext';
import {
  permissionsService,
  type PagePermission,
  type PermissionMap,
} from '@services/permissionsService';

type AppRole = 'admin' | 'hr' | 'finance' | 'operations' | 'viewer';

const DENY_ALL: PagePermission = {
  can_view: false,
  can_edit: false,
  can_delete: false,
};

/**
 * DEFAULT_PERMISSIONS — UI-only permission fallbacks.
 *
 * هذه الصلاحيات تُستخدم فقط لتحديد ظهور/اختفاء الأزرار والعناصر في الواجهة.
 * الصلاحيات الحقيقية تُفرض على مستوى:
 * 1. قاعدة البيانات عبر RLS Policies (supabase/migrations/*_rls_*.sql)
 * 2. Edge Functions عبر role-checking في الدوال الخلفية
 *
 * إذا تعارضت هذه القيم مع RLS/Edge، فالـ backend هو الحَكَم النهائي.
 *
 * @see supabase/migrations/ — RLS policy definitions
 * @see supabase/functions/ — Edge Function role checks
 */
const DEFAULT_PERMISSIONS: Record<AppRole, Record<string, PagePermission>> = {
  admin: {
    employees: { can_view: true, can_edit: true, can_delete: true },
    attendance: { can_view: true, can_edit: true, can_delete: true },
    orders: { can_view: true, can_edit: true, can_delete: true },
    ai_analytics: { can_view: true, can_edit: true, can_delete: true },
    salaries: { can_view: true, can_edit: true, can_delete: true },
    advances: { can_view: true, can_edit: true, can_delete: true },
    vehicles: { can_view: true, can_edit: true, can_delete: true },
    alerts: { can_view: true, can_edit: true, can_delete: true },
    settings: { can_view: true, can_edit: true, can_delete: true },
    apps: { can_view: true, can_edit: true, can_delete: true },
    violation_resolver: { can_view: true, can_edit: true, can_delete: true },
    vehicle_assignment: { can_view: true, can_edit: true, can_delete: true },
    fuel: { can_view: true, can_edit: true, can_delete: true },
    maintenance: { can_view: true, can_edit: true, can_delete: true },
    employee_tiers: { can_view: true, can_edit: true, can_delete: true },
    salary_schemes: { can_view: true, can_edit: true, can_delete: true },
    finance: { can_view: true, can_edit: true, can_delete: true },
    wallet: { can_view: true, can_edit: true, can_delete: true },
    treasury: { can_view: true, can_edit: true, can_delete: true },
  },
  hr: {
    employees: { can_view: true, can_edit: true, can_delete: false },
    attendance: { can_view: true, can_edit: true, can_delete: false },
    orders: { can_view: true, can_edit: false, can_delete: false },
    ai_analytics: { can_view: true, can_edit: false, can_delete: false },
    salaries: { can_view: true, can_edit: false, can_delete: false },
    advances: { can_view: true, can_edit: false, can_delete: false },
    vehicles: { can_view: true, can_edit: false, can_delete: false },
    alerts: { can_view: true, can_edit: true, can_delete: false },
    settings: { can_view: false, can_edit: false, can_delete: false },
    apps: { can_view: true, can_edit: false, can_delete: false },
    violation_resolver: { can_view: false, can_edit: false, can_delete: false },
    vehicle_assignment: { can_view: true, can_edit: false, can_delete: false },
    fuel: { can_view: true, can_edit: false, can_delete: false },
    maintenance: { can_view: false, can_edit: false, can_delete: false },
    employee_tiers: { can_view: true, can_edit: true, can_delete: true },
    salary_schemes: { can_view: true, can_edit: false, can_delete: false },
    finance: { can_view: false, can_edit: false, can_delete: false },
    wallet: { can_view: false, can_edit: false, can_delete: false },
    treasury: { can_view: false, can_edit: false, can_delete: false },
  },
  finance: {
    employees: { can_view: true, can_edit: false, can_delete: false },
    attendance: { can_view: true, can_edit: false, can_delete: false },
    orders: { can_view: true, can_edit: false, can_delete: false },
    ai_analytics: { can_view: true, can_edit: false, can_delete: false },
    salaries: { can_view: true, can_edit: true, can_delete: false },
    advances: { can_view: true, can_edit: true, can_delete: false },
    vehicles: { can_view: false, can_edit: false, can_delete: false },
    alerts: { can_view: true, can_edit: false, can_delete: false },
    settings: { can_view: false, can_edit: false, can_delete: false },
    apps: { can_view: true, can_edit: false, can_delete: false },
    violation_resolver: { can_view: true, can_edit: true, can_delete: true },
    vehicle_assignment: { can_view: true, can_edit: false, can_delete: false },
    fuel: { can_view: true, can_edit: true, can_delete: true },
    maintenance: { can_view: true, can_edit: false, can_delete: false },
    employee_tiers: { can_view: true, can_edit: false, can_delete: false },
    salary_schemes: { can_view: true, can_edit: true, can_delete: false },
    finance: { can_view: true, can_edit: true, can_delete: true },
    wallet: { can_view: true, can_edit: true, can_delete: false },
    treasury: { can_view: true, can_edit: true, can_delete: true },
  },
  operations: {
    employees: { can_view: true, can_edit: true, can_delete: false },
    attendance: { can_view: false, can_edit: false, can_delete: false },
    orders: { can_view: true, can_edit: true, can_delete: false },
    ai_analytics: { can_view: true, can_edit: false, can_delete: false },
    finance: { can_view: false, can_edit: false, can_delete: false },
    salaries: { can_view: false, can_edit: false, can_delete: false },
    advances: { can_view: false, can_edit: false, can_delete: false },
    vehicles: { can_view: true, can_edit: true, can_delete: false },
    alerts: { can_view: true, can_edit: false, can_delete: false },
    settings: { can_view: false, can_edit: false, can_delete: false },
    apps: { can_view: true, can_edit: false, can_delete: false },
    violation_resolver: { can_view: false, can_edit: false, can_delete: false },
    vehicle_assignment: { can_view: true, can_edit: false, can_delete: false },
    fuel: { can_view: true, can_edit: false, can_delete: false },
    maintenance: { can_view: true, can_edit: true, can_delete: true },
    employee_tiers: { can_view: true, can_edit: false, can_delete: false },
    salary_schemes: { can_view: false, can_edit: false, can_delete: false },
    wallet: { can_view: true, can_edit: false, can_delete: false },
    treasury: { can_view: false, can_edit: false, can_delete: false },
  },
  viewer: {
    employees: { can_view: false, can_edit: false, can_delete: false },
    attendance: { can_view: false, can_edit: false, can_delete: false },
    orders: { can_view: false, can_edit: false, can_delete: false },
    ai_analytics: { can_view: false, can_edit: false, can_delete: false },
    finance: { can_view: false, can_edit: false, can_delete: false },
    salaries: { can_view: false, can_edit: false, can_delete: false },
    advances: { can_view: false, can_edit: false, can_delete: false },
    vehicles: { can_view: false, can_edit: false, can_delete: false },
    alerts: { can_view: true, can_edit: false, can_delete: false },
    settings: { can_view: false, can_edit: false, can_delete: false },
    apps: { can_view: false, can_edit: false, can_delete: false },
    violation_resolver: { can_view: false, can_edit: false, can_delete: false },
    vehicle_assignment: { can_view: false, can_edit: false, can_delete: false },
    fuel: { can_view: false, can_edit: false, can_delete: false },
    maintenance: { can_view: true, can_edit: false, can_delete: false },
    employee_tiers: { can_view: false, can_edit: false, can_delete: false },
    salary_schemes: { can_view: false, can_edit: false, can_delete: false },
    wallet: { can_view: false, can_edit: false, can_delete: false },
    treasury: { can_view: false, can_edit: false, can_delete: false },
  },
};

export const usePermissionMap = () => {
  const { user } = useAuth();
  const query = useQuery({
    queryKey: ['permissions', user?.id ?? '__none__'] as const,
    enabled: Boolean(user?.id),
    staleTime: 5 * 60_000,
    queryFn: async (): Promise<PermissionMap> => {
      if (!user?.id) return {};
      return permissionsService.getUserPermissions(user.id);
    },
  });

  const loading = Boolean(user) && query.isLoading;
  const permissionsByPage = user && !loading && !query.isError ? (query.data ?? {}) : {};

  return { permissionsByPage, loading };
};

export const usePermissions = (pageKey: string) => {
  const { permissionsByPage, loading } = usePermissionMap();
  const permissions = permissionsByPage[pageKey] ?? DENY_ALL;

  return { permissions, loading };
};

export { DEFAULT_PERMISSIONS };
export type { PagePermission } from '@services/permissionsService';
export type { AppRole };
