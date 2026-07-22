/**
 * Company (client establishment) branding for printed documents.
 *
 * The bilingual header block is built from the company's saved establishment
 * data — Arabic on the right, English on the left — and is emitted directly by
 * the document builders (with inline styles), NOT typed into a sanitized
 * header_html field. This keeps every printed document carrying the CLIENT
 * COMPANY identity (name, unified/700 number, CR, VAT) — never the software's
 * name «وصلة», which is only a last-resort fallback when no company is set.
 */

// Program (software) name — used only as a fallback so a document is never blank.
const PRODUCT_NAME_AR = 'وصلة';
const PRODUCT_NAME_EN = 'Wasla';

export interface CompanyBranding {
  nameAr: string;
  nameEn: string;
  unifiedNumber: string;
  crNumber: string;
  taxNumber: string;
  address: string;
}

interface TradeRegisterLike {
  name?: string | null;
  name_en?: string | null;
  mol_establishment_number?: string | null;
  cr_number?: string | null;
  tax_number?: string | null;
  address?: string | null;
}

export function tradeRegisterToBranding(record: TradeRegisterLike | null | undefined): CompanyBranding {
  const nameAr = record?.name?.trim() || PRODUCT_NAME_AR;
  return {
    nameAr,
    nameEn: record?.name_en?.trim() || record?.name?.trim() || PRODUCT_NAME_EN,
    // The Saudi unified establishment number (700) is stored as mol_establishment_number.
    unifiedNumber: record?.mol_establishment_number?.trim() || '',
    crNumber: record?.cr_number?.trim() || '',
    taxNumber: record?.tax_number?.trim() || '',
    address: record?.address?.trim() || '',
  };
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function metaLine(label: string, value: string): string {
  if (!value) return '';
  return `<div style="font-size:11px;color:#334155;line-height:1.6;">${escapeHtml(label)}: <span style="font-family:'Geist Mono',monospace;">${escapeHtml(value)}</span></div>`;
}

/**
 * Bilingual company header: Arabic identity on the right, English on the left.
 * Emitted with inline styles so it survives in raw print windows.
 */
export function buildCompanyHeaderHtml(branding: CompanyBranding): string {
  const arabic = [
    `<div style="font-size:18px;font-weight:700;color:#0f172a;">${escapeHtml(branding.nameAr)}</div>`,
    metaLine('الرقم الموحّد', branding.unifiedNumber),
    metaLine('السجل التجاري', branding.crNumber),
    metaLine('الرقم الضريبي', branding.taxNumber),
  ].join('');

  const english = [
    `<div style="font-size:18px;font-weight:700;color:#0f172a;">${escapeHtml(branding.nameEn)}</div>`,
    metaLine('Unified No.', branding.unifiedNumber),
    metaLine('CR', branding.crNumber),
    metaLine('VAT', branding.taxNumber),
  ].join('');

  return `
    <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:16px;border-bottom:2px solid #0f172a;padding-bottom:10px;margin-bottom:14px;">
      <div style="flex:1;text-align:right;direction:rtl;">${arabic}</div>
      <div style="flex:1;text-align:left;direction:ltr;">${english}</div>
    </div>`;
}

/** Footer line carrying the company address (empty string when no address is set). */
export function buildCompanyFooterHtml(branding: CompanyBranding): string {
  if (!branding.address) return '';
  return `<div style="text-align:center;font-size:11px;color:#64748b;border-top:1px solid #e2e8f0;padding-top:8px;margin-top:12px;">${escapeHtml(branding.address)}</div>`;
}
