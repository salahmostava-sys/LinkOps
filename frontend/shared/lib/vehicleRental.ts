import { getDaysInMonth, isBefore, isValid, parseISO, startOfDay } from 'date-fns';

function rentalDueDateForMonth(year: number, month: number, rentalDay: number): Date {
  const monthStart = new Date(year, month, 1);
  return new Date(year, month, Math.min(rentalDay, getDaysInMonth(monthStart)));
}

export function getNextMonthlyRentalDueDate(
  rentalStartDate: string,
  referenceDate: Date = new Date(),
): Date | null {
  const rentalStart = parseISO(rentalStartDate);
  if (!isValid(rentalStart) || !isValid(referenceDate)) return null;

  const startDate = startOfDay(rentalStart);
  const referenceDay = startOfDay(referenceDate);
  const effectiveDate = isBefore(referenceDay, startDate) ? startDate : referenceDay;
  const rentalDay = startDate.getDate();

  const currentMonthDueDate = rentalDueDateForMonth(
    effectiveDate.getFullYear(),
    effectiveDate.getMonth(),
    rentalDay,
  );
  if (!isBefore(currentMonthDueDate, effectiveDate)) return currentMonthDueDate;

  return rentalDueDateForMonth(
    effectiveDate.getFullYear(),
    effectiveDate.getMonth() + 1,
    rentalDay,
  );
}
