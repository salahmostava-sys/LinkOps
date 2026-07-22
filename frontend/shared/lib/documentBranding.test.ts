import { describe, expect, it } from 'vitest';
import {
  buildCompanyFooterHtml,
  buildCompanyHeaderHtml,
  tradeRegisterToBranding,
} from './documentBranding';

describe('tradeRegisterToBranding', () => {
  it('maps trade_registers fields (unified number = mol_establishment_number)', () => {
    const b = tradeRegisterToBranding({
      name: 'شركة النخبة',
      name_en: 'Elite Co',
      mol_establishment_number: '700123456',
      cr_number: '1010101010',
      tax_number: '300052414',
      address: 'الرياض، حي الملز',
    });
    expect(b.nameAr).toBe('شركة النخبة');
    expect(b.nameEn).toBe('Elite Co');
    expect(b.unifiedNumber).toBe('700123456');
    expect(b.crNumber).toBe('1010101010');
    expect(b.taxNumber).toBe('300052414');
    expect(b.address).toBe('الرياض، حي الملز');
  });

  it('falls back to the product name only when the company name is missing', () => {
    const b = tradeRegisterToBranding(null);
    expect(b.nameAr).toBe('وصلة');
    expect(b.nameEn).toBe('Wasla');
    expect(b.unifiedNumber).toBe('');
    expect(b.address).toBe('');
  });
});

describe('buildCompanyHeaderHtml', () => {
  const b = tradeRegisterToBranding({
    name: 'شركة النخبة',
    name_en: 'Elite Co',
    mol_establishment_number: '700123456',
    cr_number: '1010101010',
    tax_number: '300052414',
    address: '',
  });

  it('renders both Arabic and English identity with all provided fields', () => {
    const html = buildCompanyHeaderHtml(b);
    expect(html).toContain('شركة النخبة');
    expect(html).toContain('Elite Co');
    expect(html).toContain('الرقم الموحّد');
    expect(html).toContain('Unified No.');
    expect(html).toContain('700123456');
    expect(html).toContain('السجل التجاري');
    expect(html).toContain('الرقم الضريبي');
    expect(html).toContain('VAT');
  });

  it('omits lines for empty fields', () => {
    const minimal = tradeRegisterToBranding({ name: 'شركة', name_en: null, cr_number: null, tax_number: null, mol_establishment_number: null, address: null });
    const html = buildCompanyHeaderHtml(minimal);
    expect(html).not.toContain('السجل التجاري');
    expect(html).not.toContain('الرقم الضريبي');
  });
});

describe('buildCompanyFooterHtml', () => {
  it('renders the address when present', () => {
    const b = tradeRegisterToBranding({ name: 'شركة', address: 'جدة، حي الشاطئ' });
    expect(buildCompanyFooterHtml(b)).toContain('جدة، حي الشاطئ');
  });

  it('returns empty string when there is no address', () => {
    const b = tradeRegisterToBranding({ name: 'شركة' });
    expect(buildCompanyFooterHtml(b)).toBe('');
  });
});
