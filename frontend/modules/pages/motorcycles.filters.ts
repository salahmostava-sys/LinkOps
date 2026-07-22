import { isStringRecord } from '@shared/hooks/usePersistentState';
import type { VehicleReportRow } from '@services/vehicleReportService';
import { ALL_STATUSES, type VehicleStatus } from '@modules/pages/motorcycles.shared';

export type VehicleColumnFilters = {
  plate: string;
  chip: 'all' | 'present' | 'absent';
  rider: string;
  status: 'all' | VehicleStatus;
  brandModel: string;
  year: string;
  serialNumber: string;
  chassisNumber: string;
  insuranceExpiry: string;
  registrationExpiry: string;
  authorizationExpiry: string;
  minimumMaintenanceCost: string;
  rental: 'all' | 'with_rental' | 'without_rental';
};

export const EMPTY_VEHICLE_COLUMN_FILTERS: VehicleColumnFilters = {
  plate: '',
  chip: 'all',
  rider: '',
  status: 'all',
  brandModel: '',
  year: '',
  serialNumber: '',
  chassisNumber: '',
  insuranceExpiry: '',
  registrationExpiry: '',
  authorizationExpiry: '',
  minimumMaintenanceCost: '',
  rental: 'all',
};

export const VEHICLE_SEARCH_STORAGE_KEY = 'table:vehicles:search:v1';
export const VEHICLE_STATUS_STORAGE_KEY = 'table:vehicles:status:v1';
export const VEHICLE_TYPE_STORAGE_KEY = 'table:vehicles:type:v1';
export const VEHICLE_COLUMNS_STORAGE_KEY = 'table:vehicles:column-filters:v1';

const VEHICLE_COLUMN_FILTER_KEYS = Object.keys(EMPTY_VEHICLE_COLUMN_FILTERS);

export const isVehicleStatusFilter = (value: unknown): value is string =>
  value === 'all' || (typeof value === 'string' && ALL_STATUSES.includes(value as VehicleStatus));

export const isVehicleTypeFilter = (value: unknown): value is string =>
  value === 'all' || value === 'motorcycle' || value === 'car';

export const isVehicleColumnFilters = (value: unknown): value is VehicleColumnFilters => {
  if (!isStringRecord(value)) return false;
  if (!VEHICLE_COLUMN_FILTER_KEYS.every((key) => key in value)) return false;
  if (!['all', 'present', 'absent'].includes(value.chip)) return false;
  if (!isVehicleStatusFilter(value.status)) return false;
  return ['all', 'with_rental', 'without_rental'].includes(value.rental);
};

export const isActiveVehicleColumnFilter = (value: string) => value !== '' && value !== 'all';

type FilterableVehicleValue = string | number | null | undefined;

const includesFilter = (value: FilterableVehicleValue, filter: string) =>
  !filter || String(value ?? '').toLocaleLowerCase().includes(filter.trim().toLocaleLowerCase());

const matchesVehicleTextFilters = (
  vehicle: VehicleReportRow,
  filters: VehicleColumnFilters,
) => ([
  [`${vehicle.plate_number} ${vehicle.plate_number_en ?? ''}`, filters.plate],
  [vehicle.current_rider ?? 'بدون مندوب', filters.rider],
  [`${vehicle.brand ?? ''} ${vehicle.model ?? ''}`, filters.brandModel],
  [vehicle.year, filters.year],
  [vehicle.serial_number, filters.serialNumber],
  [vehicle.chassis_number, filters.chassisNumber],
] satisfies Array<[FilterableVehicleValue, string]>).every(([value, filter]) => includesFilter(value, filter));

const matchesVehicleDateFilters = (
  vehicle: VehicleReportRow,
  filters: VehicleColumnFilters,
) => [
  [vehicle.insurance_expiry, filters.insuranceExpiry],
  [vehicle.registration_expiry, filters.registrationExpiry],
  [vehicle.authorization_expiry, filters.authorizationExpiry],
].every(([value, filter]) => {
  if (!filter) return true;
  const date = String(value ?? '').slice(0, 10);
  if (!date) return false;
  if (!filter.includes('..')) return date === filter;
  const [from, to] = filter.split('..');
  return (!from || date >= from) && (!to || date <= to);
});

const matchesMinimumMaintenanceCost = (
  vehicle: VehicleReportRow,
  minimumCostFilter: string,
) => !minimumCostFilter || (vehicle.total_maintenance_cost ?? 0) >= Number(minimumCostFilter);

const matchesRentalFilter = (
  vehicle: VehicleReportRow,
  rentalFilter: VehicleColumnFilters['rental'],
) => {
  if (rentalFilter === 'all') return true;
  const hasRentalData = vehicle.status === 'rental'
    && Boolean(vehicle.rental_start_date || vehicle.rental_monthly_amount);
  return (rentalFilter === 'with_rental') === hasRentalData;
};

export const matchesVehicleColumnFilters = (
  vehicle: VehicleReportRow,
  filters: VehicleColumnFilters,
) => {
  const chipMatches = filters.chip === 'all'
    || (filters.chip === 'present') === vehicle.has_fuel_chip;
  const statusMatches = filters.status === 'all' || filters.status === vehicle.status;
  return matchesVehicleTextFilters(vehicle, filters)
    && chipMatches
    && statusMatches
    && matchesVehicleDateFilters(vehicle, filters)
    && matchesMinimumMaintenanceCost(vehicle, filters.minimumMaintenanceCost)
    && matchesRentalFilter(vehicle, filters.rental);
};
