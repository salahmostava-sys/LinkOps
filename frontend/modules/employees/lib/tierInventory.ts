import { STATUS_DELIVERED, type TierRow } from '@modules/employees/types/tier.types';

type TierInventoryRow = Pick<TierRow, 'sim_number' | 'employee_id' | 'delivery_status'>;

export function countUnassignedOrUnusedTierNumbers(rows: TierInventoryRow[]): number {
  return rows.filter((row) =>
    Boolean(row.sim_number?.trim()) && (!row.employee_id || row.delivery_status !== STATUS_DELIVERED)
  ).length;
}
