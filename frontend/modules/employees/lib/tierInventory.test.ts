import { describe, expect, it } from 'vitest';
import { countUnassignedOrUnusedTierNumbers } from './tierInventory';

describe('countUnassignedOrUnusedTierNumbers', () => {
  it('counts real SIM numbers that have no rider or are not delivered', () => {
    expect(countUnassignedOrUnusedTierNumbers([
      { sim_number: '0500000001', employee_id: 'employee-1', delivery_status: 'delivered' },
      { sim_number: '0500000002', employee_id: '', delivery_status: 'delivered' },
      { sim_number: '0500000003', employee_id: 'employee-2', delivery_status: 'not_delivered' },
      { sim_number: '   ', employee_id: '', delivery_status: 'not_delivered' },
    ])).toBe(2);
  });
});
