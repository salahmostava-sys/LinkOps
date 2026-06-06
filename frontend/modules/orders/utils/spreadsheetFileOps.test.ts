import { beforeEach, describe, expect, it, vi } from 'vitest';
import { exportSpreadsheetExcel } from './spreadsheetFileOps';

const { toastSuccessMock, toastErrorMock, aoaToSheetMock, bookNewMock, bookAppendSheetMock, writeFileMock } = vi.hoisted(() => ({
  toastSuccessMock: vi.fn(),
  toastErrorMock: vi.fn(),
  aoaToSheetMock: vi.fn(),
  bookNewMock: vi.fn(),
  bookAppendSheetMock: vi.fn(),
  writeFileMock: vi.fn(),
}));

vi.mock('@shared/components/ui/sonner', () => ({
  toast: {
    success: toastSuccessMock,
    error: toastErrorMock,
  },
}));

vi.mock('@shared/lib/toastMessages', () => ({
  TOAST_SUCCESS_ACTION: 'Success Action',
  TOAST_SUCCESS_OPERATION: 'Success Op',
}));

vi.mock('@modules/orders/utils/xlsx', () => ({
  loadXlsx: vi.fn().mockResolvedValue({
    utils: {
      aoa_to_sheet: aoaToSheetMock,
      book_new: bookNewMock,
      book_append_sheet: bookAppendSheetMock,
    },
    writeFile: writeFileMock,
    read: vi.fn(),
  }),
}));

describe('spreadsheetFileOps', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('exportSpreadsheetExcel', () => {
    it('generates and downloads an excel file', async () => {
      const filteredEmployees = [{ id: 'emp1', name: 'John', platform_accounts: [] }];
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
      expect(writeFileMock).toHaveBeenCalledWith(undefined, 'طلبات_3_2026.xlsx'); // undefined because bookNewMock doesn't return anything
      expect(toastSuccessMock).toHaveBeenCalledWith('Success Action');
    });
  });
});
