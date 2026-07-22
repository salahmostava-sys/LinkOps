import { describe, expect, it } from 'vitest';
import type { VehicleReportRow } from '@services/vehicleReportService';
import {
  EMPTY_VEHICLE_COLUMN_FILTERS,
  isVehicleColumnFilters,
  matchesVehicleColumnFilters,
  type VehicleColumnFilters,
} from '@modules/pages/motorcycles.filters';

const vehicle: VehicleReportRow = {
  id: 'vehicle-1',
  plate_number: 'أ ب 9258',
  plate_number_en: 'AB 9258',
  type: 'motorcycle',
  brand: 'Honda',
  model: '2024',
  year: 2024,
  status: 'rental',
  has_fuel_chip: true,
  insurance_expiry: '2026-08-10',
  registration_expiry: '2026-09-10',
  authorization_expiry: '2026-10-10',
  serial_number: '123456',
  chassis_number: 'CHASSIS-1',
  notes: null,
  rental_start_date: '2026-07-01',
  rental_monthly_amount: 1500,
  current_rider: 'أحمد محمد',
  total_maintenance_cost: 500,
  maintenance_count: 1,
  total_km: 1000,
  total_fuel_cost: 200,
  maintenance_logs: [],
  documents: [],
};

const withFilter = <K extends keyof VehicleColumnFilters>(
  key: K,
  value: VehicleColumnFilters[K],
): VehicleColumnFilters => ({ ...EMPTY_VEHICLE_COLUMN_FILTERS, [key]: value });

describe('motorcycle column filters', () => {
  it.each([
    ['plate', withFilter('plate', '9258'), true],
    ['rider', withFilter('rider', 'أحمد'), true],
    ['fuel chip', withFilter('chip', 'absent'), false],
    ['status', withFilter('status', 'maintenance'), false],
    ['date range', withFilter('insuranceExpiry', '2026-08-01..2026-08-31'), true],
    ['maintenance cost', withFilter('minimumMaintenanceCost', '501'), false],
    ['rental', withFilter('rental', 'with_rental'), true],
  ] satisfies Array<[string, VehicleColumnFilters, boolean]>)('%s filter matches the expected result', (_label, filters, expected) => {
    expect(matchesVehicleColumnFilters(vehicle, filters)).toBe(expected);
  });

  it('rejects incomplete persisted filter state', () => {
    expect(isVehicleColumnFilters(EMPTY_VEHICLE_COLUMN_FILTERS)).toBe(true);
    expect(isVehicleColumnFilters({ plate: '9258' })).toBe(false);
  });
});
