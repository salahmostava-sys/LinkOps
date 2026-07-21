export const SAUDI_BANKS: Record<string, string> = {
  '10': 'البنك الأهلي السعودي (SNB)',
  '15': 'مصرف الراجحي',
  '20': 'بنك الرياض',
  '30': 'البنك العربي الوطني',
  '40': 'البنك الأهلي السعودي (سامبا)',
  '45': 'البنك السعودي الأول (ساب)',
  '50': 'البنك السعودي الأول (الأول)',
  '55': 'البنك السعودي الفرنسي',
  '60': 'بنك الجزيرة',
  '65': 'البنك السعودي للاستثمار',
  '71': 'بنك الكويت الوطني',
  '75': 'بنك الخليج الدولي',
  '76': 'جي بي مورجان تشيس',
  '79': 'بنك أبوظبي الأول',
  '80': 'مصرف الإنماء',
  '82': 'بنك قطر الوطني',
  '85': 'بنك ستاندرد تشارترد',
  '90': 'بنك الخليج',
  '95': 'بنك الإمارات دبي الوطني',
  '98': 'بنك D360',
  '99': 'STC Pay',
  '05': 'يور باي (Urpay)',
};

/**
 * Extracts the bank name from a Saudi IBAN.
 * @param iban - The IBAN string to check.
 * @returns The name of the bank in Arabic, or null if invalid or unknown.
 */
export function getSaudiBankName(iban: string | null | undefined): string | null {
  if (!iban) return null;
  // Remove spaces and convert to uppercase for standard processing
  const cleanIban = iban.replace(/\s+/g, '').toUpperCase();
  
  if (!cleanIban.startsWith('SA')) return null;
  if (cleanIban.length < 6) return null;

  // Extract the bank code (characters 5 and 6)
  const bankCode = cleanIban.substring(4, 6);
  return SAUDI_BANKS[bankCode] || null;
}
