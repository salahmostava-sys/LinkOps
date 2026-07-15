import { describe, expect, it } from 'vitest';

import { getNextMonthlyRentalDueDate } from './vehicleRental';

describe('getNextMonthlyRentalDueDate', () => {
  it.each([
    ['before this month due date', new Date(2026, 1, 2), new Date(2026, 1, 5)],
    ['after this month due date', new Date(2026, 1, 6), new Date(2026, 2, 5)],
  ])('uses the correct monthly due date %s', (_scenario, referenceDate, expectedDueDate) => {
    expect(getNextMonthlyRentalDueDate('2026-01-05', referenceDate)).toEqual(expectedDueDate);
  });

  it('clamps rental days to the last day of shorter months', () => {
    const dueDate = getNextMonthlyRentalDueDate('2026-01-31', new Date(2026, 1, 10));

    expect(dueDate).toEqual(new Date(2026, 1, 28));
  });

  it('does not return a due date before a future rental starts', () => {
    const dueDate = getNextMonthlyRentalDueDate('2026-08-20', new Date(2026, 6, 15));

    expect(dueDate).toEqual(new Date(2026, 7, 20));
  });
});
