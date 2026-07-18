import type React from 'react';
import { useRef, useState } from 'react';
import { Button } from '@shared/components/ui/button';
import { CalendarDays, Download, FileSpreadsheet, FolderOpen, Loader2, Printer, Upload } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@shared/components/ui/dropdown-menu';
import MonthlyRecord from '@modules/attendance/components/MonthlyRecord';
import { useLanguage } from '@app/providers/LanguageContext';
import { useTranslation } from 'react-i18next';
import { loadXlsx } from '@modules/orders/utils/xlsx';
import { printHtmlTable } from '@shared/lib/printTable';
import attendanceService from '@services/attendanceService';
import { useToast } from '@shared/hooks/use-toast';
import { useAuthQueryGate } from '@shared/hooks/useAuthQueryGate';
import { useTemporalContext } from '@app/providers/TemporalContext';

type AttendanceTemplateEmployee = { id: string; name: string };
type AttendanceTemplateRecord = {
  employee_id: string;
  date: string;
  status: string;
  note?: string | null;
};

function buildAttendanceTemplateRows(
  employees: AttendanceTemplateEmployee[],
  attendanceRows: AttendanceTemplateRecord[],
): Array<Array<string>> {
  const employeeNames = new Map(employees.map((employee) => [employee.id, employee.name]));
  const employeesWithRecords = new Set(attendanceRows.map((record) => record.employee_id));
  const populatedRows = attendanceRows.map((record) => [
    employeeNames.get(record.employee_id) ?? '',
    record.date,
    record.status,
    record.note ?? '',
  ]);
  const blankEmployeeRows = employees
    .filter((employee) => !employeesWithRecords.has(employee.id))
    .map((employee) => [employee.name, '', '', '']);
  return [...populatedRows, ...blankEmployeeRows];
}


const Attendance = () => {
  useAuthQueryGate();
  const { isRTL, lang } = useLanguage();
  const { t } = useTranslation();
  const { selectedMonth: globalMonth } = useTemporalContext();
  const importRef = useRef<HTMLInputElement>(null);
  const monthlyTableRef = useRef<HTMLDivElement>(null);
  const { toast } = useToast();
  const [importing, setImporting] = useState(false);

  // Selected date is now derived from Global Temporal Context (YYYY-MM)
  const [yearStr, monthStr] = globalMonth.split('-');
  const selectedYear = yearStr;
  const selectedMonth = String(Number(monthStr) - 1); // 0-indexed for existing components
  const monthLabel = new Intl.DateTimeFormat(lang === 'ar' ? 'ar-SA-u-nu-latn' : 'en-US', {
    month: 'long',
  }).format(new Date(Number(selectedYear), Number(selectedMonth), 1));
  const attendanceHeaders = [t('employeeName'), t('attendanceDateHeader'), t('attendanceStatusHeader'), t('notes')];

  const loadAttendanceTemplateRows = async (): Promise<Array<Array<string>>> => {
    const year = Number(selectedYear);
    const month = Number(selectedMonth);
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const monthNumber = String(month + 1).padStart(2, '0');
    const startDate = `${year}-${monthNumber}-01`;
    const endDate = `${year}-${monthNumber}-${String(daysInMonth).padStart(2, '0')}`;
    const result = await attendanceService.getMonthlyEmployeesAndAttendance(startDate, endDate);
    return buildAttendanceTemplateRows(
      result.employees,
      result.attendanceRows,
    );
  };


  const handleExportAttendance = async () => {
    try {
      toast({ title: t('downloading') });
      const month = Number(selectedMonth);
      const rows = await loadAttendanceTemplateRows();
      const XLSX = await loadXlsx();
      const ws = XLSX.utils.aoa_to_sheet([attendanceHeaders, ...rows]);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, t('attendance'));
      XLSX.writeFile(wb, `attendance_${selectedYear}-${String(month + 1).padStart(2, '0')}.xlsx`);
      toast({ title: t('exportSuccess') });
    } catch {
      toast({ title: t('exportFailed'), description: t('attendanceExportLoadFailed'), variant: 'destructive' });
    }
  };

  const handleAttendanceTemplate = async () => {
    const XLSX = await loadXlsx();
    const rows = await loadAttendanceTemplateRows();
    const ws = XLSX.utils.aoa_to_sheet([attendanceHeaders, ...rows]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, t('template'));
    XLSX.writeFile(wb, 'template_attendance.xlsx');
  };

  const handleImportAttendance = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setImporting(true);
    try {
      const data = await file.arrayBuffer();
      const XLSX = await loadXlsx();
      const workbook = XLSX.read(data, { type: 'array' });
      const sheet = workbook.Sheets[workbook.SheetNames[0]];
      const json = XLSX.utils.sheet_to_json(sheet, { header: 1 });

      const rows = json.slice(1).filter((row: string[]) => row[0] && row[1]);
      if (rows.length === 0) {
        toast({ title: t('emptyFile'), description: t('noDataAfterHeader'), variant: 'destructive' });
        return;
      }

      // Fetch employee list to resolve names → UUIDs
      const employeesData = await attendanceService.getDailyAttendanceBase();
      const employees = employeesData.employees as Array<{ id: string; name: string }>;
      const nameToId = new Map<string, string>();
      for (const emp of employees) {
        nameToId.set(emp.name.trim(), emp.id);
        // Also index without extra whitespace for fuzzy matching
        nameToId.set(emp.name.trim().replaceAll(/\s+/g, ' '), emp.id);
      }

      let imported = 0;
      let failed = 0;
      const unmatchedNames: string[] = [];

      const results = await Promise.allSettled(
        rows.map(async (row) => {
          const [employeeName, date, status, notes] = row;
          if (!employeeName || !date || !status) {
            throw new Error('missing-fields');
          }
          const normalizedName = employeeName.trim().replaceAll(/\s+/g, ' ');
          const employeeId = nameToId.get(normalizedName) ?? nameToId.get(employeeName.trim());
          if (!employeeId) {
            unmatchedNames.push(normalizedName);
            throw new Error(`employee-not-found: ${normalizedName}`);
          }
          await attendanceService.upsertDailyAttendance({
            employee_id: employeeId,
            date,
            status: status.toLowerCase() as 'present' | 'absent' | 'leave' | 'sick' | 'late',
            check_in: '',
            check_out: '',
            note: notes || '',
          });
        })
      );

      for (const result of results) {
        if (result.status === 'fulfilled') imported++;
        else failed++;
      }

      const uniqueUnmatched = [...new Set(unmatchedNames)];
      const summary = t('attendanceImportSummary', { success: imported, failed });
      let description = summary;
      if (uniqueUnmatched.length > 0) {
        const hiddenCount = uniqueUnmatched.length - 5;
        const more = hiddenCount > 0 ? t('moreNames', { count: hiddenCount }) : '';
        description = t('unmatchedEmployeeNames', {
          summary,
          names: uniqueUnmatched.slice(0, 5).join(', '),
          more,
        });
      }

      toast({
        title: t('importCompleted'),
        description,
        variant: failed > 0 ? 'destructive' : 'default',
      });
    } catch {
      toast({ title: t('importFailed'), description: t('fileReadFailed'), variant: 'destructive' });
    } finally {
      setImporting(false);
      e.target.value = '';
    }
  };

  const handlePrintTable = () => {
    const table = monthlyTableRef.current?.querySelector('table');
    if (!table) {
      toast({ title: t('noTableToPrint') });
      return;
    }
    printHtmlTable(table, { title: t('monthlyAttendanceRecord') });
  };

  return (
    <div className="space-y-3" dir={isRTL ? 'rtl' : 'ltr'}>
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div>
          <nav className="page-breadcrumb">
            <span>{t('home')}</span>
            <span className="page-breadcrumb-sep">/</span>
            <span>{t('attendance')}</span>
          </nav>
          <h1 className="page-title">{t('attendance')}</h1>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <div className="inline-flex items-center rounded-xl bg-muted/40 p-1 px-3 border border-border/50 text-[11px] font-bold text-muted-foreground ms-1">
            <CalendarDays size={13} className="me-1.5 text-primary/70" />
            <span>{t('periodLabel', { month: monthLabel, year: selectedYear })}</span>
          </div>



          <input ref={importRef} type="file" accept=".xlsx,.xls" className="hidden" onChange={handleImportAttendance} disabled={importing} />
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="gap-1.5 h-8">
                <FolderOpen size={14} />
                {t('files')}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={handleExportAttendance}>
                <Download size={14} /> {t('exportMonthlySummary')}
              </DropdownMenuItem>
              <DropdownMenuItem onClick={handleAttendanceTemplate}>
                <FileSpreadsheet size={14} /> {t('downloadTemplate')}
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => importRef.current?.click()} disabled={importing}>
                {importing ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />} {t('importExcel')}
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={handlePrintTable}><Printer size={14} /> {t('printTable')}</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      <div className="space-y-2">
        <div ref={monthlyTableRef}>
          <MonthlyRecord selectedMonth={Number(selectedMonth)} selectedYear={Number(selectedYear)} />
        </div>
      </div>
    </div>
  );
};

export default Attendance;
