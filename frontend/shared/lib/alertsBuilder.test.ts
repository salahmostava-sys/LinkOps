import { describe, expect, it } from 'vitest';
import { buildAlertsFromResponses } from './alertsBuilder';

describe('buildAlertsFromResponses', () => {
  it('includes commercial record name and renewal cost in employee expiry alerts when present', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [
            {
              id: 'emp-1',
              name: 'أحمد',
              commercial_record: 'سجل مكة',
              residency_expiry: '2026-04-10',
              probation_end_date: null,
              health_insurance_expiry: null,
              license_expiry: null,
            },
          ],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: { data: [] },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: {
          data: [{
            name: 'سجل مكة',
            residency_renewal_monthly_cost: 650,
            residency_renewal_cost_period: 'yearly',
          }],
        },
      },
      '2026-04-30',
      new Date('2026-04-07T00:00:00Z'),
    );

    expect(alerts[0]).toMatchObject({
      id: 'res-emp-1',
      type: 'residency',
      residencyRenewalCost: 650,
      residencyRenewalCostPeriod: 'yearly',
    });
    expect(alerts[0]?.entityName).toContain('أحمد • السجل: سجل مكة');
    expect(alerts[0]?.entityName).toContain('650');
  });

  it('merges persisted workflow state into its generated alert without duplicating it', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: 'emp-1',
            name: 'أحمد',
            commercial_record: 'سجل مكة',
            residency_expiry: '2026-04-10',
            probation_end_date: null,
            health_insurance_expiry: null,
            license_expiry: null,
          }],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: {
          data: [{
            id: 'db-alert-1',
            source_key: 'res-emp-1',
            type: 'residency',
            due_date: '2026-04-10',
            is_resolved: false,
            message: 'إقامة أحمد',
            details: null,
            status: 'in_progress',
            assigned_to: 'user-1',
            assigned_profile: { name: 'مسؤول الموارد', email: null },
            estimated_cost: 725,
            resolution_note: 'جارٍ تجهيز الطلب',
          }],
        },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
      },
      '2026-04-30',
      new Date('2026-04-07T00:00:00Z'),
    );

    expect(alerts).toHaveLength(1);
    expect(alerts[0]).toMatchObject({
      id: 'res-emp-1',
      persistedId: 'db-alert-1',
      workflowStatus: 'in_progress',
      assignedTo: 'user-1',
      assignedName: 'مسؤول الموارد',
      estimatedCost: 725,
      resolutionNote: 'جارٍ تجهيز الطلب',
    });
  });
});

