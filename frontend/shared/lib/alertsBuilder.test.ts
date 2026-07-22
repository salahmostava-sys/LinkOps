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
      entityName: 'أحمد',
      commercialRecordName: 'سجل مكة',
      renewalDurationLabel: 'سنة واحدة',
      residencyRenewalCost: 650,
      residencyRenewalCostPeriod: 'yearly',
    });
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
      description: 'monthly renewal overdue by 300 days',
      employeeId: 'emp-expired-300-days',
      employeeName: 'موظف منتهي منذ 300 يوم',
      recordName: 'سجل 300 يوم',
      expiryDate: '2025-09-18',
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
      renewalDurationLabel: expectedDuration,
    });
  });

  it('uses calendar dates so the remaining days do not change with the current time', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: 'emp-calendar',
            name: 'موظف التقويم',
            residency_expiry: '2026-07-16',
            probation_end_date: null,
            status: 'active',
          }],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: { data: [] },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
        rentalVehiclesRes: { data: [] },
      },
      '2026-07-31',
      new Date(2026, 6, 15, 23, 45),
    );

    expect(alerts[0]?.daysLeft).toBe(1);
  });

  it.each([
    { period: 'monthly' as const, cost: 800, expectedCost: 9_600, expectedDuration: '12 شهر' },
    { period: 'yearly' as const, cost: 2_400, expectedCost: 4_800, expectedDuration: 'سنتان' },
  ])('does not overcharge when a renewal lands exactly on today for $period billing', ({
    period,
    cost,
    expectedCost,
    expectedDuration,
  }) => {
    const expiryDate = period === 'monthly' ? '2025-07-15' : '2024-07-15';
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: `emp-${period}`,
            name: 'موظف حدود التجديد',
            commercial_record: 'السجل الحدودي',
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
            name: 'السجل الحدودي',
            residency_renewal_monthly_cost: cost,
            residency_renewal_cost_period: period,
          }],
        },
        rentalVehiclesRes: { data: [] },
      },
      '2026-12-31',
      new Date(2026, 6, 15, 18, 30),
    );

    expect(alerts[0]).toMatchObject({
      residencyRenewalCost: expectedCost,
      renewalDurationLabel: expectedDuration,
    });
  });

  it('preserves the real due date and generated cost when a workflow is snoozed', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: { data: [] },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: {
          data: [{
            id: 'rental-workflow',
            source_key: 'rental-vehicle-1',
            type: 'vehicle_rental',
            due_date: '2026-07-20',
            snoozed_until: '2026-07-25',
            is_resolved: false,
            message: 'إيجار مركبة',
            details: null,
            status: 'snoozed',
            estimated_cost: null,
          }],
        },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
        rentalVehiclesRes: {
          data: [{
            id: 'vehicle-1',
            plate_number: 'ABC 1234',
            status: 'rental',
            rental_start_date: '2026-01-20',
            rental_monthly_amount: 1_750,
          }],
        },
      },
      '2026-07-31',
      new Date(2026, 6, 18),
    );

    expect(alerts).toHaveLength(1);
    expect(alerts[0]).toMatchObject({
      dueDate: '2026-07-20',
      daysLeft: 2,
      snoozedUntil: '2026-07-25',
      estimatedCost: 1_750,
      workflowStatus: 'snoozed',
    });
  });

  it('creates a fresh alert when a resolved document receives a new expiry date', () => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: 'emp-renewed',
            name: 'موظف جدد وثيقته',
            residency_expiry: '2027-07-15',
            probation_end_date: null,
            status: 'active',
          }],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: {
          data: [{
            id: 'old-resolved-alert',
            source_key: 'res-emp-renewed',
            type: 'residency',
            due_date: '2026-07-15',
            is_resolved: true,
            message: 'الدورة السابقة',
            details: null,
            status: 'resolved',
          }],
        },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
        rentalVehiclesRes: { data: [] },
      },
      '2027-08-01',
      new Date(2027, 5, 15),
    );

    expect(alerts).toHaveLength(2);
    expect(alerts.find((alert) => alert.id === 'res-emp-renewed')).toMatchObject({
      dueDate: '2027-07-15',
      resolved: false,
    });
    expect(alerts.find((alert) => alert.id === 'old-resolved-alert')).toMatchObject({
      dueDate: '2026-07-15',
      resolved: true,
    });
  });

  it.each([
    { status: 'inactive', sponsorshipStatus: 'sponsored' },
    { status: 'active', sponsorshipStatus: 'absconded' },
    { status: 'active', sponsorshipStatus: 'terminated' },
  ])('does not create expiry alerts for excluded employees', ({ status, sponsorshipStatus }) => {
    const alerts = buildAlertsFromResponses(
      {
        employeesRes: {
          data: [{
            id: `${status}-${sponsorshipStatus}`,
            name: 'موظف مستبعد',
            residency_expiry: '2026-07-01',
            probation_end_date: null,
            status,
            sponsorship_status: sponsorshipStatus,
          }],
        },
        vehiclesRes: { data: [] },
        platformAccountsRes: { data: [] },
        dbAlertsRes: { data: [] },
        sparePartsRes: { data: [] },
        abscondedRes: { data: [] },
        commercialRecordsRes: { data: [] },
        rentalVehiclesRes: { data: [] },
      },
      '2026-07-31',
      new Date(2026, 6, 15),
    );

    expect(alerts).toEqual([]);
  });
});

