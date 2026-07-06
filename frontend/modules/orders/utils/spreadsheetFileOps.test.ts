import { beforeEach, describe, expect, it, vi } from 'vitest';
import { exportSpreadsheetExcel, runSpreadsheetImport, downloadSpreadsheetTemplate, printSpreadsheetTable, saveSpreadsheetMonth } from './spreadsheetFileOps';
import { orderService } from '@services/orderService';
import { buildOrdersIoHeaders } from '@shared/constants/excelSchemas';
import { mergeImportedOrdersFromMatrixWithMapping } from './spreadsheetImportModel';
import { matchEmployeeNames } from '@shared/lib/nameMatching';

const { toastSuccessMock, toastErrorMock, toastWarningMock, aoaToSheetMock, bookNewMock, bookAppendSheetMock, writeFileMock, readMock, sheetToJsonMock } = vi.hoisted(() => ({
  toastSuccessMock: vi.fn(),
  toastErrorMock: vi.fn(),
  toastWarningMock: vi.fn(),
  aoaToSheetMock: vi.fn(),
  bookNewMock: vi.fn(),
  bookAppendSheetMock: vi.fn(),
  writeFileMock: vi.fn(),
  readMock: vi.fn(),
  sheetToJsonMock: vi.fn(),
}));

vi.mock('@shared/components/ui/sonner', () => ({
  toast: {
    success: toastSuccessMock,
    error: toastErrorMock,
    warning: toastWarningMock,
  },
}));

vi.mock('@shared/lib/toastMessages', () => ({
  TOAST_SUCCESS_ACTION: 'Success Action',
  TOAST_SUCCESS_OPERATION: 'Success Op',
}));

vi.mock('@services/orderService', () => ({
  orderService: {
    bulkUpsert: vi.fn(),
  },
}));

vi.mock('./spreadsheetImportModel', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./spreadsheetImportModel')>();
  return {
    ...actual,
    mergeImportedOrdersFromMatrixWithMapping: vi.fn(),
  };
});

vi.mock('@shared/lib/nameMatching', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@shared/lib/nameMatching')>();
  return {
    ...actual,
    matchEmployeeNames: vi.fn(),
  };
});

vi.mock('@modules/orders/utils/xlsx', () => ({
  loadXlsx: vi.fn().mockResolvedValue({
    utils: {
      aoa_to_sheet: aoaToSheetMock,
      book_new: bookNewMock,
      book_append_sheet: bookAppendSheetMock,
      sheet_to_json: sheetToJsonMock,
    },
    writeFile: writeFileMock,
    read: readMock,
  }),
}));

describe('spreadsheetFileOps', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('exportSpreadsheetExcel', () => {
    it('generates and downloads an excel file', async () => {
      const filteredEmployees = [{ id: 'emp1', name: 'John', platform_accounts: [], identity_id: '', is_active: true, avatar_url: '', created_at: '', updated_at: '' }];
      const empDayTotal = vi.fn().mockReturnValue(5);
      const empMonthTotal = vi.fn().mockReturnValue(15);
      const dayArr = [1, 2, 3];

      await exportSpreadsheetExcel({
        year: 2026,
        month: 3,
        dayArr,
        filteredEmployees,
        empDayTotal,
        empMonthTotal,
      });

      expect(aoaToSheetMock).toHaveBeenCalled();
      expect(bookNewMock).toHaveBeenCalled();
      expect(bookAppendSheetMock).toHaveBeenCalled();
      expect(writeFileMock).toHaveBeenCalledWith(undefined, 'طلبات_3_2026.xlsx');
      expect(toastSuccessMock).toHaveBeenCalledWith('Success Action');
    });
  });

  describe('downloadSpreadsheetTemplate', () => {
    it('downloads the template', async () => {
      await downloadSpreadsheetTemplate([1, 2, 3]);
      expect(aoaToSheetMock).toHaveBeenCalledWith([buildOrdersIoHeaders([1, 2, 3])]);
      expect(writeFileMock).toHaveBeenCalledWith(undefined, 'template_orders.xlsx');
    });
  });

  describe('printSpreadsheetTable', () => {
    it('handles print window', () => {
      const mockWindow = {
        document: {
          documentElement: { setAttribute: vi.fn() },
          head: { appendChild: vi.fn() },
          body: { replaceChildren: vi.fn(), appendChild: vi.fn() },
          createElement: vi.fn().mockReturnValue({ setAttribute: vi.fn() }),
        },
        onload: null as any,
        print: vi.fn(),
        onafterprint: null as any,
        close: vi.fn(),
      };
      vi.spyOn(globalThis, 'open').mockReturnValue(mockWindow as any);
      
      const tableEl = document.createElement('table');
      printSpreadsheetTable({ tableEl, year: 2026, month: 3, filteredEmployeeCount: 5 });

      expect(globalThis.open).toHaveBeenCalled();
      
      // trigger onload
      if (mockWindow.onload) mockWindow.onload(new Event('load'));
      expect(mockWindow.print).toHaveBeenCalled();
      
      if (mockWindow.onafterprint) mockWindow.onafterprint(new Event('afterprint'));
      expect(mockWindow.close).toHaveBeenCalled();
    });
  });

  describe('saveSpreadsheetMonth', () => {
    it('returns false if month is locked', async () => {
      const result = await saveSpreadsheetMonth({
        isMonthLocked: true,
        year: 2026, month: 3, days: 31,
        data: {}, setSaving: vi.fn(), employees: [], apps: []
      });
      expect(result).toBe(false);
      expect(toastErrorMock).toHaveBeenCalled();
    });

    it('returns false if no data to save', async () => {
      const setSaving = vi.fn();
      const result = await saveSpreadsheetMonth({
        isMonthLocked: false,
        year: 2026, month: 3, days: 31,
        data: {}, setSaving, employees: [], apps: []
      });
      expect(result).toBe(false);
      expect(setSaving).toHaveBeenCalledWith(false);
      expect(toastErrorMock).toHaveBeenCalled();
    });

    it('saves valid data', async () => {
      vi.mocked(orderService.bulkUpsert).mockResolvedValue({ saved: 1, failed: [] });
      const setSaving = vi.fn();
      const data = { 'emp1::app1::1': 5 };
      const employees = [{ id: 'emp1', name: 'John', platform_accounts: [], identity_id: '', is_active: true, avatar_url: '', created_at: '', updated_at: '' }];
      const apps = [{ id: 'app1', name: 'App1', created_at: '', updated_at: '' }];
      
      const result = await saveSpreadsheetMonth({
        isMonthLocked: false,
        year: 2026, month: 3, days: 31,
        data, setSaving, employees, apps
      });
      
      expect(result).toBe(true);
      expect(orderService.bulkUpsert).toHaveBeenCalled();
      expect(toastSuccessMock).toHaveBeenCalledWith('Success Op', expect.any(Object));
    });

    it('warns about invalid data', async () => {
      vi.mocked(orderService.bulkUpsert).mockResolvedValue({ saved: 0, failed: [] });
      const data = { 'emp1::app1::32': 5, 'emp1::app1::1': -5 };
      
      await saveSpreadsheetMonth({
        isMonthLocked: false,
        year: 2026, month: 3, days: 31,
        data, setSaving: vi.fn(), employees: [], apps: []
      });
      
      expect(toastWarningMock).toHaveBeenCalled();
    });
  });

  describe('runSpreadsheetImport', () => {
    it('errors on invalid file extension', async () => {
      const file = new File([''], 'test.csv');
      const result = await runSpreadsheetImport({
        file, dayArr: [], employees: [], apps: [], appEmployeeIds: {}, data: {}, onApplyData: vi.fn()
      });
      expect(result).toBe(null);
      expect(toastErrorMock).toHaveBeenCalled();
    });

    it('errors on empty sheet', async () => {
      const file = new File([''], 'test.xlsx');
      file.arrayBuffer = vi.fn().mockResolvedValue(new ArrayBuffer(0));
      readMock.mockReturnValue({ SheetNames: [] });
      
      const result = await runSpreadsheetImport({
        file, dayArr: [], employees: [], apps: [], appEmployeeIds: {}, data: {}, onApplyData: vi.fn()
      });
      expect(result).toBe(null);
    });

    it('successfully imports valid spreadsheet', async () => {
      const file = new File([''], 'test.xlsx');
      file.arrayBuffer = vi.fn().mockResolvedValue(new ArrayBuffer(0));
      readMock.mockReturnValue({ SheetNames: ['Sheet1'], Sheets: { Sheet1: {} } });
      const headers = buildOrdersIoHeaders([1, 2]);
      sheetToJsonMock.mockReturnValue([headers, ['John', 5, 10]]);
      
      vi.mocked(matchEmployeeNames).mockReturnValue({
        matched: new Map([['John', { id: 'emp1', name: 'John', platform_accounts: [], identity_id: '', is_active: true, avatar_url: '', created_at: '', updated_at: '' }]]),
        unmatched: []
      });
      
      vi.mocked(mergeImportedOrdersFromMatrixWithMapping).mockReturnValue({
        newData: { 'emp1::app1::1': 5 },
        imported: 1,
        skipped: 0,
        errors: []
      });
      
      const onApplyData = vi.fn();
      
      const result = await runSpreadsheetImport({
        file, dayArr: [1, 2], employees: [], apps: [], appEmployeeIds: {}, data: {}, onApplyData
      });
      
      expect(result).toBeTruthy();
      expect(result?.imported).toBe(1);
      expect(onApplyData).toHaveBeenCalledWith({ 'emp1::app1::1': 5 });
      expect(toastSuccessMock).toHaveBeenCalled();
    });
  });
});
