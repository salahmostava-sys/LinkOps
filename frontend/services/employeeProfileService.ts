import { supabase } from '@services/supabase/client';
import { handleSupabaseError } from '@services/serviceError';

const PROFILE_ADVANCES_LIMIT = 200;
const PROFILE_SALARIES_LIMIT = 60;
const PROFILE_APPS_LIMIT = 100;
const PROFILE_ORDERS_LIMIT = 2000;

export interface EmployeeProfileInstallment {
  id: string;
  month_year: string;
  amount: number;
  status: string;
  deducted_at?: string | null;
}

export interface EmployeeProfileAdvance {
  id: string;
  amount: number;
  monthly_amount: number;
  disbursement_date: string;
  first_deduction_month: string;
  status: string;
  note?: string | null;
  advance_installments?: EmployeeProfileInstallment[];
}

export interface EmployeeProfileSalaryRecord {
  id: string;
  month_year: string;
  base_salary: number;
  allowances: number;
  attendance_deduction: number;
  advance_deduction: number;
  external_deduction: number;
  manual_deduction: number;
  net_salary: number;
  is_approved: boolean;
}

export interface EmployeeProfileApp {
  id: string;
  app_id: string;
  status: string;
  username?: string | null;
  apps?: { name: string } | null;
}

export interface EmployeeProfileDailyOrder {
  id: string;
  date: string;
  orders_count: number;
  app_id: string;
  apps?: { name: string; brand_color?: string | null } | null;
}

export interface EmployeeProfileRelatedData {
  advances: EmployeeProfileAdvance[];
  salaries: EmployeeProfileSalaryRecord[];
  employeeApps: EmployeeProfileApp[];
  dailyOrders: EmployeeProfileDailyOrder[];
}

export const employeeProfileService = {
  getRelatedData: async (employeeId: string): Promise<EmployeeProfileRelatedData> => {
    const [advancesRes, salariesRes, appsRes, ordersRes] = await Promise.all([
      supabase
        .from('advances')
        .select('id, amount, monthly_amount, disbursement_date, first_deduction_month, status, note, advance_installments(id, month_year, amount, status, deducted_at)')
        .eq('employee_id', employeeId)
        .order('disbursement_date', { ascending: false })
        .limit(PROFILE_ADVANCES_LIMIT),
      supabase
        .from('salary_records')
        .select('id, month_year, base_salary, allowances, attendance_deduction, advance_deduction, external_deduction, manual_deduction, net_salary, is_approved')
        .eq('employee_id', employeeId)
        .order('month_year', { ascending: false })
        .limit(PROFILE_SALARIES_LIMIT),
      supabase
        .from('employee_apps')
        .select('id, app_id, status, username, apps(name)')
        .eq('employee_id', employeeId)
        .limit(PROFILE_APPS_LIMIT),
      supabase
        .from('daily_orders')
        .select('id, date, orders_count, app_id, apps(name, brand_color)')
        .eq('employee_id', employeeId)
        .order('date', { ascending: false })
        .limit(PROFILE_ORDERS_LIMIT),
    ]);

    if (advancesRes.error) handleSupabaseError(advancesRes.error, 'employeeProfileService.getRelatedData.advances');
    if (salariesRes.error) handleSupabaseError(salariesRes.error, 'employeeProfileService.getRelatedData.salaries');
    if (appsRes.error) handleSupabaseError(appsRes.error, 'employeeProfileService.getRelatedData.employeeApps');
    if (ordersRes.error) handleSupabaseError(ordersRes.error, 'employeeProfileService.getRelatedData.dailyOrders');

    return {
      advances: (advancesRes.data ?? []),
      salaries: (salariesRes.data ?? []),
      employeeApps: (appsRes.data ?? []),
      dailyOrders: (ordersRes.data ?? []),
    };
  },
};
