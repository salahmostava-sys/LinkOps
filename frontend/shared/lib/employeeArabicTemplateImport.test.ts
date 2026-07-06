import { describe, it, expect, vi, beforeEach } from 'vitest';
import { parseEmployeeArabicWorkbook, upsertEmployeeArabicRows, EMPLOYEE_TEMPLATE_AR_HEADERS } from './employeeArabicTemplateImport';
import { employeeService } from '@services/employeeService';

vi.mock('@services/employeeService', () => ({
  employeeService: {
    findByNationalId: vi.fn(),
    createEmployee: vi.fn(),
    updateEmployee: vi.fn(),
  },
}));

const { readMock, sheetToJsonMock } = vi.hoisted(() => ({
  readMock: vi.fn(),
  sheetToJsonMock: vi.fn(),
}));

vi.mock('@modules/orders/utils/xlsx', () => ({
  loadXlsx: vi.fn().mockResolvedValue({
    read: readMock,
    utils: {
      sheet_to_json: sheetToJsonMock,
    },
  }),
}));

describe('employeeArabicTemplateImport', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('parseEmployeeArabicWorkbook', () => {
    it('returns error if no sheets', async () => {
      readMock.mockReturnValue({ SheetNames: [] });
      const result = await parseEmployeeArabicWorkbook(new ArrayBuffer(0));
      expect(result.headerErrors[0]).toBe('????? ?? ????? ??? ????? ???');
    });

    it('returns error if missing expected headers', async () => {
      readMock.mockReturnValue({ SheetNames: ['Sheet1'], Sheets: { Sheet1: {} } });
      sheetToJsonMock.mockReturnValue([['Name'], ['Row 1']]); // Wrong headers
      const result = await parseEmployeeArabicWorkbook(new ArrayBuffer(0));
      expect(result.headerErrors[0]).toMatch(/\?\?\? \?\?\?\?\?\?\? \?\?\? \?\?\?\?: \?\?\?\?\?\?\? 21\? \?\?\?\?\?\?\?\? 1/);
    });

    it('parses valid rows correctly', async () => {
      readMock.mockReturnValue({ SheetNames: ['Sheet1'], Sheets: { Sheet1: {} } });
      const validRow = Array(21).fill('');
      validRow[0] = 'John Doe';
      validRow[19] = 'orders';
      validRow[20] = 'active';

      sheetToJsonMock.mockReturnValue([
        EMPLOYEE_TEMPLATE_AR_HEADERS,
        validRow
      ]);

      const result = await parseEmployeeArabicWorkbook(new ArrayBuffer(0));
      expect(result.headerErrors).toHaveLength(0);
      expect(result.rows).toHaveLength(1);
      expect(result.rows[0].name).toBe('John Doe');
      expect(result.rows[0].salary_type).toBe('orders');
      expect(result.rows[0].status).toBe('active');
    });
  });

  describe('upsertEmployeeArabicRows', () => {
    it('does nothing if no rows provided', async () => {
      const result = await upsertEmployeeArabicRows([]);
      expect(result.processed).toBe(0);
      expect(result.failures).toHaveLength(0);
      expect(employeeService.findByNationalId).not.toHaveBeenCalled();
    });

    it('creates new employees', async () => {
      vi.mocked(employeeService.findByNationalId).mockResolvedValue(null);
      vi.mocked(employeeService.createEmployee).mockResolvedValue();

      const result = await upsertEmployeeArabicRows([
        { name: 'John Doe', phone: '0500000000', national_id: '123' },
      ]);

      expect(result.processed).toBe(1);
      expect(result.failures).toHaveLength(0);
      expect(employeeService.createEmployee).toHaveBeenCalledWith(expect.objectContaining({ name: 'John Doe' }));
    });

    it('updates existing employees based on national_id', async () => {
      vi.mocked(employeeService.findByNationalId).mockResolvedValue({ id: 'emp1' } as any);
      vi.mocked(employeeService.updateEmployee).mockResolvedValue();

      const result = await upsertEmployeeArabicRows([
        { name: 'John Doe', national_id: '123' },
      ]);

      expect(result.processed).toBe(1);
      expect(result.failures).toHaveLength(0);
      expect(employeeService.updateEmployee).toHaveBeenCalledWith('emp1', expect.objectContaining({ name: 'John Doe' }));
    });
    
    it('collects errors on failure', async () => {
      vi.mocked(employeeService.findByNationalId).mockResolvedValue(null);
      vi.mocked(employeeService.createEmployee).mockRejectedValue(new Error('DB Error'));

      const result = await upsertEmployeeArabicRows([
        { name: 'John Doe', phone: '0500000000', national_id: '123' },
      ]);

      expect(result.processed).toBe(0);
      expect(result.failures).toHaveLength(1);
      expect(result.failures[0].error).toMatch(/DB Error/);
    });
  });
});
