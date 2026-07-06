// formatters.ts - Utility functions for formatting dates, currency, and numbers

/**
 * Normalize Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) to ASCII (0123456789).
 * Handles input from date pickers on Arabic-locale devices.
 */
export function normalizeArabicDigits(value: string): string {
  return value.replaceAll(/[٠-٩]/g, (d) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)));
}

/**
 * Format a date to YYYY-MM-DD format.
 * @param date - The date object to format.
 * @returns Formatted date string.
 */
export function formatDate(date: Date | null | undefined): string {
    if (!date || !(date instanceof Date) || Number.isNaN(date.getTime())) {
        return '';
    }
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

/**
 * Format a number as currency (SAR).
 * @param amount - The amount to format.
 * @param currencySymbol - The symbol of the currency (default is 'ر.س').
 * @returns Formatted currency string.
 */
export function formatCurrency(amount: number | null | undefined, currencySymbol: string = 'ر.س'): string {
    if (amount === null || amount === undefined || Number.isNaN(amount)) {
        return `0.00 ${currencySymbol}`;
    }
    // Ensures two decimal places and adds the symbol. We place symbol after or before depending on standard,
    // usually in Arabic "ر.س" comes after the number or before, let's use "amount ر.س".
    return `${amount.toFixed(2)} ${currencySymbol}`;
}

/**
 * Format a date to the standard DD/MM/YYYY hh:mm A format.
 * @param dateStr - The ISO date string or Date object.
 * @returns Formatted standard date string.
 */
export function formatStandardDateTime(dateInput: string | Date | null | undefined): string {
    if (!dateInput) return '';
    const d = new Date(dateInput);
    if (Number.isNaN(d.getTime())) return '';

    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    
    let hours = d.getHours();
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    
    hours = hours % 12;
    hours = hours ? hours : 12; // the hour '0' should be '12'
    const strHours = String(hours).padStart(2, '0');

    return `${day}/${month}/${year} ${strHours}:${minutes} ${ampm}`;
}

/**
 * Get today's date in YYYY-MM-DD format (local timezone).
 * Drop-in replacement for the common `format(new Date(), 'yyyy-MM-dd')` pattern
 * that avoids importing date-fns just for this.
 */
export function todayISO(): string {
    const d = new Date();
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

/**
 * Format a number with commas as thousands separators.
 * @param num - The number to format.
 * @returns Formatted number string.
 */
export function formatNumber(num: number | null | undefined): string {
    if (num === null || num === undefined || Number.isNaN(num)) {
        return '0';
    }
    return new Intl.NumberFormat('en-US').format(num);
}