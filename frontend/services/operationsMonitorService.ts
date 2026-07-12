import { format, subDays } from 'date-fns';

import { supabase } from '@services/supabase/client';
import { handleSupabaseError } from '@services/serviceError';
import { filterOperationallyVisibleEmployees } from '@shared/lib/employeeVisibility';

type AttendanceStatus = 'present' | 'absent' | 'leave' | 'sick' | 'late';

type EmployeeRow = {
  id: string;
  name: string;
  city: string | null;
  status: string | null;
  sponsorship_status: string | null;
  probation_end_date: string | null;
  job_title: string | null;
};

type AttendanceRow = {
  employee_id: string;
  status: AttendanceStatus;
};

type EmployeeAppRow = {
  employee_id: string;
};

type DailyOrderRow = {
  employee_id: string;
  orders_count: number;
  date: string;
};

type VehicleRow = {
  id: string;
  plate_number: string;
  status: string;
  type: string;
  has_fuel_chip: boolean;
};

type VehicleAssignmentRow = {
  employee_id: string;
  vehicle_id: string;
  end_date: string | null;
  returned_at: string | null;
};

export type OperationsIssueType =
  | 'absent'
  | 'no_attendance'
  | 'without_app'
  | 'without_vehicle'
  | 'inactive_orders';

export type OperationsRiderIssue = {
  employeeId: string;
  name: string;
  city: string;
  issueType: OperationsIssueType;
  issueLabel: string;
  recentOrders: number;
};

export type OperationsVehicleIssue = {
  vehicleId: string;
  plateNumber: string;
  status: string;
  type: string;
  hasFuelChip: boolean;
};

export type DailyOperationsSnapshot = {
  date: string;
  inactiveWindowDays: number;
  totals: {
    activeRiders: number;
    presentToday: number;
    absentToday: number;
    leaveOrSickToday: number;
    noAttendance: number;
    ridersWithoutApps: number;
    ridersWithoutVehicle: number;
    inactiveRiders: number;
    underusedVehicles: number;
  };
  riderIssues: OperationsRiderIssue[];
  underusedVehicles: OperationsVehicleIssue[];
};

const ACTIVE_ATTENDANCE_STATUSES = new Set<AttendanceStatus>(['present', 'late']);
const FOLLOWUP_ATTENDANCE_STATUSES = new Set<AttendanceStatus>(['absent', 'leave', 'sick']);
const ACTIVE_VEHICLE_STATUSES = new Set(['active', 'rental']);

function normalizeCity(city: string | null): string {
  return city?.trim() || 'غير محدد';
}

function buildRiderIssue(
  employee: EmployeeRow,
  issueType: OperationsIssueType,
  issueLabel: string,
  recentOrders: number
): OperationsRiderIssue {
  return {
    employeeId: employee.id,
    name: employee.name,
    city: normalizeCity(employee.city),
    issueType,
    issueLabel,
    recentOrders,
  };
}

function isCurrentAssignment(row: VehicleAssignmentRow, date: string): boolean {
  if (row.returned_at) return false;
  return !row.end_date || row.end_date >= date;
}

export const operationsMonitorService = {
  async getDailySnapshot(date = format(new Date(), 'yyyy-MM-dd'), inactiveWindowDays = 7): Promise<DailyOperationsSnapshot> {
    const inactiveFromDate = format(subDays(new Date(`${date}T00:00:00`), inactiveWindowDays - 1), 'yyyy-MM-dd');

    const [employeesRes, attendanceRes, appLinksRes, ordersRes, vehiclesRes, assignmentsRes] = await Promise.all([
      supabase
        .from('employees')
        .select('id, name, city, status, sponsorship_status, probation_end_date, job_title')
        .eq('status', 'active')
        .order('name'),
      supabase
        .from('attendance')
        .select('employee_id, status')
        .eq('date', date),
      supabase
        .from('employee_apps')
        .select('employee_id')
        .eq('status', 'active'),
      supabase
        .from('daily_orders')
        .select('employee_id, orders_count, date')
        .gte('date', inactiveFromDate)
        .lte('date', date),
      supabase
        .from('vehicles')
        .select('id, plate_number, status, type, has_fuel_chip')
        .order('plate_number'),
      supabase
        .from('vehicle_assignments')
        .select('employee_id, vehicle_id, end_date, returned_at')
        .is('returned_at', null),
    ]);

    if (employeesRes.error) handleSupabaseError(employeesRes.error, 'operationsMonitorService.getDailySnapshot.employees');
    if (attendanceRes.error) handleSupabaseError(attendanceRes.error, 'operationsMonitorService.getDailySnapshot.attendance');
    if (appLinksRes.error) handleSupabaseError(appLinksRes.error, 'operationsMonitorService.getDailySnapshot.employeeApps');
    if (ordersRes.error) handleSupabaseError(ordersRes.error, 'operationsMonitorService.getDailySnapshot.dailyOrders');
    if (vehiclesRes.error) handleSupabaseError(vehiclesRes.error, 'operationsMonitorService.getDailySnapshot.vehicles');
    if (assignmentsRes.error) handleSupabaseError(assignmentsRes.error, 'operationsMonitorService.getDailySnapshot.vehicleAssignments');

    const employees = filterOperationallyVisibleEmployees((employeesRes.data ?? []) as EmployeeRow[], new Date(`${date}T00:00:00`));
    const attendanceRows = (attendanceRes.data ?? []) as AttendanceRow[];
    const appLinks = (appLinksRes.data ?? []) as EmployeeAppRow[];
    const orders = (ordersRes.data ?? []) as DailyOrderRow[];
    const vehicles = (vehiclesRes.data ?? []) as VehicleRow[];
    const currentAssignments = ((assignmentsRes.data ?? []) as VehicleAssignmentRow[]).filter((row) => isCurrentAssignment(row, date));

    const attendanceByEmployee = new Map(attendanceRows.map((row) => [row.employee_id, row.status]));
    const appEmployeeIds = new Set(appLinks.map((row) => row.employee_id));
    const assignedEmployeeIds = new Set(currentAssignments.map((row) => row.employee_id));
    const assignedVehicleIds = new Set(currentAssignments.map((row) => row.vehicle_id));
    const recentOrdersByEmployee = new Map<string, number>();

    orders.forEach((row) => {
      recentOrdersByEmployee.set(row.employee_id, (recentOrdersByEmployee.get(row.employee_id) ?? 0) + Number(row.orders_count ?? 0));
    });

    const riderIssues: OperationsRiderIssue[] = [];
    let presentToday = 0;
    let absentToday = 0;
    let leaveOrSickToday = 0;
    let noAttendance = 0;
    let ridersWithoutApps = 0;
    let ridersWithoutVehicle = 0;
    let inactiveRiders = 0;

    employees.forEach((employee) => {
      const attendanceStatus = attendanceByEmployee.get(employee.id);
      const recentOrders = recentOrdersByEmployee.get(employee.id) ?? 0;

      if (!attendanceStatus) {
        noAttendance += 1;
        riderIssues.push(buildRiderIssue(employee, 'no_attendance', 'لم يتم تسجيل حضور اليوم', recentOrders));
      } else if (ACTIVE_ATTENDANCE_STATUSES.has(attendanceStatus)) {
        presentToday += 1;
      } else if (attendanceStatus === 'absent') {
        absentToday += 1;
        riderIssues.push(buildRiderIssue(employee, 'absent', 'غياب اليوم', recentOrders));
      } else if (FOLLOWUP_ATTENDANCE_STATUSES.has(attendanceStatus)) {
        leaveOrSickToday += 1;
      }

      if (!appEmployeeIds.has(employee.id)) {
        ridersWithoutApps += 1;
        riderIssues.push(buildRiderIssue(employee, 'without_app', 'بدون تطبيق نشط', recentOrders));
      }

      if (!assignedEmployeeIds.has(employee.id)) {
        ridersWithoutVehicle += 1;
        riderIssues.push(buildRiderIssue(employee, 'without_vehicle', 'بدون مركبة مسلمة', recentOrders));
      }

      if (recentOrders === 0) {
        inactiveRiders += 1;
        riderIssues.push(buildRiderIssue(employee, 'inactive_orders', `بدون طلبات آخر ${inactiveWindowDays} أيام`, recentOrders));
      }
    });

    const underusedVehicles = vehicles
      .filter((vehicle) => ACTIVE_VEHICLE_STATUSES.has(vehicle.status) && !assignedVehicleIds.has(vehicle.id))
      .map((vehicle) => ({
        vehicleId: vehicle.id,
        plateNumber: vehicle.plate_number,
        status: vehicle.status,
        type: vehicle.type,
        hasFuelChip: vehicle.has_fuel_chip,
      }));

    return {
      date,
      inactiveWindowDays,
      totals: {
        activeRiders: employees.length,
        presentToday,
        absentToday,
        leaveOrSickToday,
        noAttendance,
        ridersWithoutApps,
        ridersWithoutVehicle,
        inactiveRiders,
        underusedVehicles: underusedVehicles.length,
      },
      riderIssues: riderIssues.slice(0, 40),
      underusedVehicles: underusedVehicles.slice(0, 40),
    };
  },
};
