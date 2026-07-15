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
        rentalVehiclesRes: { data: [] },
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
        rentalVehiclesRes: { data: [] },
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

  it('creates a monthly rental reminder with the vehicle rental cost', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: { data: [] },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: { data: [] },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
        rentalVehiclesRes: {
          data: [{
            id: 'vehicle-1',
            plate_number: 'ABC 1234',
            status: 'rental',
            rental_start_date: '2026-01-31',
            rental_monthly_amount: 1750,
          }],
        },
      },
      '2026-02-28',
      new Date(2026, 1, 24),
    );

    expect(alerts).toContainEqual(expect.objectContaining({
      id: 'rental-vehicle-1',
      type: 'vehicle_rental',
      dueDate: '2026-02-28',
      daysLeft: 4,
      estimatedCost: 1750,
    }));
  });

  it.each([
    {
      description: 'monthly renewal',
      employeeId: 'emp-expired',
      employeeName: 'موظف منتهي',
      recordName: 'سجل المقاولات',
      expiryDate: '2025-08-18',
      baseCost: 800,
      period: 'monthly' as const,
      expectedCost: 9600,
      expectedDuration: '12 شهر',
    },
    {
      description: 'annual individual-establishment renewal',
      employeeId: 'emp-yearly',
      employeeName: 'موظف مؤسسة فردية',
      recordName: 'مؤسسة فردية',
      expiryDate: '2024-04-10',
      baseCost: 2400,
      period: 'yearly' as const,
      expectedCost: 7200,
      expectedDuration: '3 سنوات',
    },
  ])('charges enough $description periods to make the residency valid', ({
    employeeId,
    employeeName,
    recordName,
    expiryDate,
    baseCost,
    period,
    expectedCost,
    expectedDuration,
  }) => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: employeeId,
            name: employeeName,
            commercial_record: recordName,
            residency_expiry: expiryDate,
            probation_end_date: null,
            status: 'active',
          }],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: { data: [] },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: {
          data: [{
            name: recordName,
            residency_renewal_monthly_cost: baseCost,
            residency_renewal_cost_period: period,
          }],
        },
        rentalVehiclesRes: { data: [] },
      },
      '2026-12-31',
      new Date(2026, 6, 15),
    );

    expect(alerts[0]).toMatchObject({
      type: 'residency',
      residencyRenewalCost: expectedCost,
      residencyRenewalCostPeriod: period,
    });
    expect(alerts[0]?.entityName).toContain(expectedCost.toLocaleString('en-US'));
    expect(alerts[0]?.entityName).toContain(expectedDuration);
  });
});

