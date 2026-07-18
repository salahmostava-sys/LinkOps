import { formatStandardDateTime, todayISO } from '@shared/lib/formatters';

import { useCallback, useRef, useEffect } from 'react';
import { cycleSortState } from '@shared/lib/sortTableIndicators';
import { employeeService, EMPLOYEE_DELETE_BLOCKED_MESSAGE } from '@services/employeeService';
import { getErrorMessage } from '@services/serviceError';
import { auditService } from '@services/auditService';
import { EMPLOYEE_IMPORT_COLUMNS } from '@shared/constants/excelSchemas';
import { EMPLOYEE_TEMPLATE_AR_HEADERS } from '@shared/lib/employeeArabicTemplateImport';
import { printHtmlTable } from '@shared/lib/printTable';
import { getEmployeeCities } from '@modules/employees/model/employeeUtils';
import { cityLabel } from '@modules/employees/model/employeeCity';
import {
  employeeCitySummary,
  processBulkImportRows,
  type Employee,
  type SortDir,
  type UploadReport,
  type UploadLiveStats,
} from '@modules/employees/types/employee.types';

import { loadXlsx } from '@modules/orders/utils/xlsx';
import { useUndo } from '@shared/context/UndoContext';
import { useTranslation } from 'react-i18next';

const EMPLOYEE_EXPORT_LABEL_KEYS: Record<string, string> = {
  name: 'employeeName', name_en: 'nameEnglish', national_id: 'nationalId', phone: 'phone',
  email: 'email', cities: 'cities', nationality: 'nationality', job_title: 'jobTitle',
  join_date: 'joinDate', birth_date: 'birthDate', probation_end_date: 'probationEndDate',
  residency_expiry: 'residencyExpiry', health_insurance_expiry: 'healthInsuranceExpiry',
  license_expiry: 'licenseExpiry', license_status: 'licenseStatus',
  sponsorship_status: 'sponsorshipStatus', bank_account_number: 'bankAccount', iban: 'IBAN',
  commercial_record: 'commercialRegistration', salary_type: 'salaryType', status: 'employeeStatus',
};

// Reverts a single employee row to its previous field values (used by the undo stack).
const buildRevertPatch = (
  prev: Record<string, unknown>,
  field: string,
  prevValue: string | null,
  extraFields?: Record<string, unknown>,
): Record<string, unknown> => {
  const revertPatch: Record<string, unknown> = { [field]: prevValue };
  if (!extraFields) return revertPatch;
  for (const key of Object.keys(extraFields)) {
    revertPatch[key] = prev[key] ?? null;
  }
  return revertPatch;
};

export function useEmployeeActions(params: {
  data: Employee[];
  setData: React.Dispatch<React.SetStateAction<Employee[]>>;
  filtered: Employee[];
  sortField: string | null;
  setSortField: React.Dispatch<React.SetStateAction<string | null>>;
  sortDir: SortDir;
  setSortDir: React.Dispatch<React.SetStateAction<SortDir>>;
  toast: (opts: { title: string; description?: string; variant?: "default" | "destructive" }) => unknown;
  permissions: { can_view: boolean; can_edit: boolean; can_delete: boolean };
  deleteEmployee: Employee | null;
  setDeleteEmployee: React.Dispatch<React.SetStateAction<Employee | null>>;
  setDeleting: React.Dispatch<React.SetStateAction<boolean>>;
  setActionLoading: React.Dispatch<React.SetStateAction<boolean>>;
  setIsUploading: React.Dispatch<React.SetStateAction<boolean>>;
  setUploadProgress: React.Dispatch<React.SetStateAction<number>>;
  setUploadReport: React.Dispatch<React.SetStateAction<UploadReport | null>>;
  setUploadLiveStats: React.Dispatch<React.SetStateAction<UploadLiveStats>>;
  uploadIntervalRef: React.MutableRefObject<ReturnType<typeof setInterval> | null>;
  refetchEmployees: () => Promise<unknown>;
  syncSystemAfterEmployeeImport: () => Promise<void>;
  statusDateDialog: { emp: Employee; newStatus: string; label: string } | null;
  statusDate: string;
  setStatusDateSaving: React.Dispatch<React.SetStateAction<boolean>>;
  setStatusDateDialog: React.Dispatch<React.SetStateAction<{ emp: Employee; newStatus: string; label: string } | null>>;
  tableRef: React.RefObject<HTMLTableElement | null>;
  colFilters: Record<string, string>;
  setColFilters: React.Dispatch<React.SetStateAction<Record<string, string>>>;
}) {
  const { t } = useTranslation();
  const {
    data, setData, filtered, sortField, setSortField, sortDir, setSortDir,
    toast, permissions, deleteEmployee, setDeleteEmployee, setDeleting,
    setActionLoading, setIsUploading, setUploadProgress, setUploadReport,
    setUploadLiveStats, uploadIntervalRef, refetchEmployees,
    syncSystemAfterEmployeeImport,
    statusDateDialog, statusDate, setStatusDateSaving, setStatusDateDialog,
    tableRef, setColFilters,
  } = params;

  const { registerAction } = useUndo();

  // Keep a stable ref to data so saveField doesn't need data as a dep
  const dataRef = useRef(data);
  useEffect(() => { dataRef.current = data; }, [data]);

  const handleSort = useCallback((field: string) => {
    const next = cycleSortState(sortField, sortDir, field);
    setSortField(next.sortField);
    setSortDir(next.sortDir);
  }, [sortField, sortDir, setSortField, setSortDir]);

  const applyPatch = useCallback((id: string, patch: Record<string, unknown>) => {
    setData(d => d.map(e => (e.id === id ? { ...e, ...patch } : e)));
  }, [setData]);

  const saveField = useCallback(async (id: string, field: string, value: string | null, extraFields?: Record<string, unknown>) => {
    const prev = dataRef.current.find(e => e.id === id);
    const prevValue = prev ? (prev as Record<string, unknown>)[field] as string | null : null;
    const coerced = value === '' ? null : value;
    const updatePatch = { [field]: coerced, ...(extraFields) };
    applyPatch(id, updatePatch);
    try {
      await employeeService.updateEmployee(id, updatePatch);
      // Register undo action after successful save
      if (prev) {
        const revertRow = async () => {
          const revertPatch = buildRevertPatch(prev, field, prevValue, extraFields);
          applyPatch(id, revertPatch);
          await employeeService.updateEmployee(id, revertPatch);
        };
        registerAction({
          description: t('employeeFieldUpdated', { name: prev.name, field }),
          undoCommand: revertRow,
        });
      }
    } catch (err: unknown) {
      const message = getErrorMessage(err, t('saveEditFailed'));
      if (prev) applyPatch(id, prev);
      toast({ title: t('saveError'), description: message, variant: 'destructive' });
    }
  }, [toast, registerAction, applyPatch, t]);


  const handleSaveStatusWithDate = async () => {
    if (!statusDateDialog) return;
    setStatusDateSaving(true);
    const extraFields =
      statusDateDialog.newStatus === 'absconded' || statusDateDialog.newStatus === 'terminated'
        ? { probation_end_date: statusDate }
        : undefined;
    await saveField(
      statusDateDialog.emp.id,
      'sponsorship_status',
      statusDateDialog.newStatus,
      extraFields,
    );
    toast({
      title: t('statusUpdatedTo', { status: statusDateDialog.label }),
      description: t('selectedDate', { date: statusDate }),
    });
    setStatusDateSaving(false);
    setStatusDateDialog(null);
  };

  const handleDelete = useCallback(async () => {
    if (!deleteEmployee) return;
    setDeleting(true);
    try {
      await employeeService.deleteById(deleteEmployee.id);
      setData(d => d.filter(e => e.id !== deleteEmployee.id));
      toast({ title: t('deleted'), description: deleteEmployee.name });
    } catch (err: unknown) {
      const message = getErrorMessage(err, t('employeeDeleteFailed'));
      const blocked = message === EMPLOYEE_DELETE_BLOCKED_MESSAGE;
      toast({
        title: blocked ? t('deleteNotAllowed') : t('errorDeleting'),
        description: message,
        variant: 'destructive',
      });
    }
    setDeleting(false);
    setDeleteEmployee(null);
  }, [deleteEmployee, setData, setDeleteEmployee, setDeleting, toast, t]);

  const setColFilter = useCallback((key: string, value: string) => {
    setColFilters(prev => {
      const next = { ...prev };
      if (!value || value === 'all') delete next[key];
      else next[key] = value;
      return next;
    });
  }, [setColFilters]);

  const buildEmployeeIoRows = () => filtered.map((employee) => ({
    name: employee.name ?? '',
    name_en: employee.name_en ?? '',
    national_id: employee.national_id ?? '',
    phone: employee.phone ?? '',
    email: employee.email ?? '',
    cities: employeeCitySummary(employee, ''),
    nationality: employee.nationality ?? '',
    job_title: employee.job_title ?? '',
    join_date: employee.join_date ?? '',
    birth_date: employee.birth_date ?? '',
    probation_end_date: employee.probation_end_date ?? '',
    residency_expiry: employee.residency_expiry ?? '',
    health_insurance_expiry: employee.health_insurance_expiry ?? '',
    license_expiry: employee.license_expiry ?? '',
    license_status: employee.license_status ?? '',
    sponsorship_status: employee.sponsorship_status ?? '',
    bank_account_number: employee.bank_account_number ?? '',
    iban: employee.iban ?? '',
    commercial_record: employee.commercial_record ?? '',
    salary_type: employee.salary_type || 'shift',
    status: employee.status || 'active',
  }));

  const handleExport = async () => {
    const XLSX = await loadXlsx();
    const rows = buildEmployeeIoRows();
    const headerRow = EMPLOYEE_IMPORT_COLUMNS.map((column) => t(EMPLOYEE_EXPORT_LABEL_KEYS[column.key] ?? column.label));
    const aoaRows = rows.map((row) => EMPLOYEE_IMPORT_COLUMNS.map((column) => row[column.key]));
    const ws = XLSX.utils.aoa_to_sheet([headerRow, ...aoaRows]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, t('employeeDataSheet'));
    XLSX.writeFile(wb, `${t('employeeDataFile')}_${todayISO()}.xlsx`);
  };

  const handleFastExport = async () => {
    const XLSX = await loadXlsx();
    const branch = undefined;
    const search = undefined;
    const status = undefined;

    let out: Array<{
      name: string;
      national_id: string | null;
      phone: string | null;
      city: string | null;
      cities?: string[] | null;
      status: string;
      sponsorship_status: string | null;
      license_status: string | null;
      residency_expiry: string | null;
      join_date: string | null;
      job_title: string | null;
    }>;
    try {
      out = (await employeeService.exportEmployees({ filters: { branch, search, status } })) as typeof out;
    } catch (e: unknown) {
      const message = getErrorMessage(e, t('exportFailed'));
      toast({ title: t('error'), description: message, variant: 'destructive' });
      return;
    }

    const rows = out.map((e, i) => ({
      '#': i + 1,
      [t('employeeName')]: e.name ?? '',
      [t('nationalId')]: e.national_id ?? '',
      [t('phone')]: e.phone ?? '',
      [t('cities')]: getEmployeeCities(e).map((city) => city === 'makkah' || city === 'jeddah' ? t(city) : cityLabel(city, city)).join(', '),
      [t('employeeStatus')]: e.status ?? '',
      [t('sponsorshipStatus')]: e.sponsorship_status ?? '',
      [t('licenseStatus')]: e.license_status ?? '',
      [t('residencyExpiry')]: e.residency_expiry ?? '',
      [t('joinDate')]: e.join_date ?? '',
      [t('jobTitle')]: e.job_title ?? '',
    }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Employees');
    XLSX.writeFile(wb, `employees_fast_${todayISO()}.xlsx`);

    await auditService.logAdminAction({
      action: 'employees.export',
      table_name: 'employees',
      record_id: null,
      meta: { total: out.length, branch: branch ?? null, status: status ?? null, search: search ?? null },
    });
      toast({ title: t('exportCompleted'), description: t('rowsProcessed', { count: out.length }) });
  };

  const handleTemplate = async () => {
    const XLSX = await loadXlsx();
    const rows = buildEmployeeIoRows();
    const aoaRows = rows.map((row) => EMPLOYEE_IMPORT_COLUMNS.map((column) => row[column.key]));
    const ws = XLSX.utils.aoa_to_sheet([Array.from(EMPLOYEE_TEMPLATE_AR_HEADERS), ...aoaRows]);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, t('template'));
    XLSX.writeFile(wb, 'import_template.xlsx');
  };

  const handlePrint = () => {
    const table = tableRef.current;
    if (!table) return;
    printHtmlTable(table, {
      title: t('employeeDataSheet'),
      subtitle: t('printEmployeeTotal', { count: filtered.length, date: formatStandardDateTime() }),
    });
  };

  const runExportDetailed = async () => {
    setActionLoading(true);
    try {
      await handleExport();
      toast({ title: t('exportCompleted'), description: t('rowsProcessed', { count: filtered.length }) });
    } catch (e: unknown) {
      toast({
        title: t('exportFailed'),
        description: getErrorMessage(e, t('invalidFileOrData')),
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const runTemplateDownload = async () => {
    setActionLoading(true);
    try {
      await handleTemplate();
      toast({ title: t('downloadCompleted'), description: t('importTemplateDownloaded') });
    } catch (e: unknown) {
      toast({
        title: t('downloadFailed'),
        description: getErrorMessage(e, t('templateCreationFailed')),
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const runPrintDetailed = async () => {
    setActionLoading(true);
    try {
      handlePrint();
    } finally {
      setActionLoading(false);
    }
  };

  const runImportFile = async (file: File) => {
    if (!permissions.can_edit) {
      toast({
        title: t('notAllowed'),
        description: t('employeeImportDenied'),
        variant: 'destructive',
      });
      return;
    }
    setActionLoading(true);
    setIsUploading(true);
    setUploadProgress(0);
    setUploadReport(null);
    setUploadLiveStats({ processedNames: 0, totalNames: 0, currentName: '' });
    if (uploadIntervalRef.current) {
      clearInterval(uploadIntervalRef.current);
      uploadIntervalRef.current = null;
    }

    try {
      const buf = await file.arrayBuffer();
      const { report, headerWarnings } = await processBulkImportRows(buf, setUploadProgress, setUploadLiveStats);
      setUploadReport(report);
      if (report.totalProcessed === 0) {
        const firstIssue = report.errors[0]?.issue;
        toast({
          title: t('processingFailed'),
          description: firstIssue || t('noValidFileData'),
          variant: 'destructive',
        });
        setIsUploading(false);
        setUploadProgress(0);
        setUploadLiveStats({ processedNames: 0, totalNames: 0, currentName: '' });
        return;
      }
      await refetchEmployees();
      if (report.successfulRows > 0) {
        await syncSystemAfterEmployeeImport();
      }
      await auditService.logAdminAction({
        action: 'employees.import_arabic_template',
        table_name: 'employees',
        record_id: null,
        meta: { processed: report.successfulRows, failed: report.failedRows, headerWarnings },
      });
      const hasFailures = report.failedRows > 0;
      if (report.successfulRows === 0) {
        const topIssues = report.errors.slice(0, 3).map((error) => t('rowIssue', { row: error.rowIndex, issue: error.issue }));
        toast({
          title: t('importFailed'),
          description: topIssues.join(' • ') || t('noRowsImported'),
          variant: 'destructive',
        });
      } else {
        toast({
          title: hasFailures ? t('processingCompletedWithErrors') : t('processingCompletedSuccessfully'),
          description: hasFailures
            ? t('processingSummaryWithFailures', { total: report.totalProcessed, success: report.successfulRows, failed: report.failedRows })
            : t('processingSummarySuccess', { total: report.totalProcessed }),
          variant: hasFailures ? 'destructive' : undefined,
        });
      }
      setUploadProgress(100);
      setTimeout(() => {
        setIsUploading(false);
        setUploadProgress(0);
        setUploadLiveStats({ processedNames: 0, totalNames: 0, currentName: '' });
      }, 900);
    } catch (e: unknown) {
      toast({
        title: t('fileProcessingFailed'),
        description: getErrorMessage(e, t('fileProcessingError')),
        variant: 'destructive',
      });
      if (uploadIntervalRef.current) {
        clearInterval(uploadIntervalRef.current);
        uploadIntervalRef.current = null;
      }
      setIsUploading(false);
      setUploadProgress(0);
      setUploadLiveStats({ processedNames: 0, totalNames: 0, currentName: '' });
    } finally {
      setActionLoading(false);
    }
  };

  const runFastExportWrapped = async () => {
    setActionLoading(true);
    try {
      await handleFastExport();
    } finally {
      setActionLoading(false);
    }
  };

  return {
    handleSort, saveField, handleSaveStatusWithDate, handleDelete,
    setColFilter, handleExport, handleFastExport, handleTemplate,
    handlePrint, runExportDetailed, runTemplateDownload, runPrintDetailed,
    runImportFile, runFastExportWrapped,
  };
}
