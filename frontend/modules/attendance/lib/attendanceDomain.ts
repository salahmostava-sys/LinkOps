import type { Employee, CellData } from '../components/MonthlyRecord';

export type EmployeeGridRow = Employee & {
  recordByDay: Record<number, CellData>;
  summary: {
    p: number;
    a: number;
    l: number;
    s: number;
    lt: number;
    th: number;
  };
};

export function buildAttendanceGridData(
  employees: Employee[],
  attendanceRows: CellData[]
): EmployeeGridRow[] {
  return employees.map((emp) => {
    const empRows = attendanceRows.filter((r) => r.employee_id === emp.id);
    const recordByDay: Record<number, CellData> = {};
    let p = 0, a = 0, l = 0, s = 0, lt = 0;
    
    empRows.forEach(r => {
      const day = parseInt(r.date.split('-')[2], 10);
      recordByDay[day] = r;
      if (r.status === 'present') p++;
      if (r.status === 'absent') a++;
      if (r.status === 'leave') l++;
      if (r.status === 'sick') s++;
      if (r.status === 'late') lt++;
    });
    
    return { 
      ...emp, 
      recordByDay, 
      summary: { p, a, l, s, lt, th: (p + lt) * 8 } 
    };
  });
}
