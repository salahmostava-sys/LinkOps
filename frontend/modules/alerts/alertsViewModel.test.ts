import { describe, expect, it } from 'vitest';
import type { Alert } from '@shared/lib/alertsBuilder';
import {
  calculateAlertStats,
  compareAlerts,
  filterAlerts,
  getCommercialRecords,
  hasActiveAlertFilters,
  isAlertAttentionFilter,
  isAlertSeverityFilter,
  isAlertTypeFilter,
  isAlertWorkflowFilter,
  type AlertFilters,
} from '@modules/alerts/alertsViewModel';

const defaultFilters: AlertFilters = {
  type: 'all',
  severity: 'all',
  workflow: 'all',
  attention: 'all',
  commercialRecord: 'all',
  search: '',
};

const createAlert = (overrides: Partial<Alert> = {}): Alert => ({
  id: 'alert-1',
  type: 'residency',
  entityName: 'أحمد محمد',
  dueDate: '2026-07-10',
  daysLeft: -5,
  severity: 'urgent',
  resolved: false,
  assignedTo: null,
  commercialRecordName: 'السجل الرئيسي',
  residencyRenewalCost: 2_400,
  ...overrides,
});

describe('alerts view model', () => {
  it('combines type, workflow, commercial record, and search filters', () => {
    const matchingAlert = createAlert({ workflowStatus: 'in_progress' });
    const otherRecord = createAlert({ id: 'alert-2', commercialRecordName: 'السجل الزراعي' });
    const filters: AlertFilters = {
      ...defaultFilters,
      type: 'expired_residency_cost',
      workflow: 'in_progress',
      commercialRecord: 'السجل الرئيسي',
      search: 'أحمد',
    };

    expect(filterAlerts([otherRecord, matchingAlert], filters)).toEqual([matchingAlert]);
  });

  it('sorts urgent alerts first, then by due date distance', () => {
    const warning = createAlert({ id: 'warning', severity: 'warning', daysLeft: -20 });
    const urgentLater = createAlert({ id: 'urgent-later', daysLeft: 3 });
    const urgentOverdue = createAlert({ id: 'urgent-overdue', daysLeft: -2 });

    expect([warning, urgentLater, urgentOverdue].sort(compareAlerts).map((alert) => alert.id))
      .toEqual(['urgent-overdue', 'urgent-later', 'warning']);
  });

  it('calculates expired residency cost and excludes future missing costs from the expired card', () => {
    const alerts = [
      createAlert({ id: 'priced-expired', residencyRenewalCost: 7_200 }),
      createAlert({ id: 'missing-expired', residencyRenewalCost: null }),
      createAlert({ id: 'missing-future', daysLeft: 10, residencyRenewalCost: null, severity: 'info' }),
      createAlert({ id: 'vehicle', type: 'insurance', daysLeft: 4, residencyRenewalCost: null }),
    ];

    expect(calculateAlertStats(alerts)).toEqual({
      activeCount: 4,
      overdueCount: 2,
      dueWithinWeekCount: 1,
      unassignedCount: 4,
      expiredResidencyCost: 7_200,
      expiredResidencyMissingCostCount: 1,
    });
  });

  it('returns unique sorted commercial records', () => {
    const alerts = [
      createAlert({ commercialRecordName: 'السجل الزراعي' }),
      createAlert({ id: 'alert-2', commercialRecordName: 'السجل الرئيسي' }),
      createAlert({ id: 'alert-3', commercialRecordName: 'السجل الزراعي' }),
    ];

    expect(getCommercialRecords(alerts)).toEqual(['السجل الرئيسي', 'السجل الزراعي']);
  });

  it('validates persisted filter values and detects active filters', () => {
    expect(isAlertTypeFilter('vehicle_rental')).toBe(true);
    expect(isAlertSeverityFilter('critical')).toBe(false);
    expect(isAlertWorkflowFilter('resolved')).toBe(false);
    expect(isAlertAttentionFilter('due_7_days')).toBe(true);
    expect(hasActiveAlertFilters(defaultFilters)).toBe(false);
    expect(hasActiveAlertFilters({ ...defaultFilters, search: 'أحمد' })).toBe(true);
  });
});
