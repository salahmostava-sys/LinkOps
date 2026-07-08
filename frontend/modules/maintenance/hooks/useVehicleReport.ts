import { useQuery } from '@tanstack/react-query';
import { useMemo, useState } from 'react';
import { useAuthQueryGate, authQueryUserId } from '@shared/hooks/useAuthQueryGate';
import { getVehicleReport, type VehicleReportFilters, type VehicleReportRow } from '@services/vehicleReportService';

export type SortKey = 'maintenance_cost' | 'maintenance_count' | 'fuel_cost' | 'km' | 'plate';

export function useVehicleReport(filters: VehicleReportFilters) {
  const { enabled, userId } = useAuthQueryGate();
  const uid = authQueryUserId(userId);

  return useQuery({
    queryKey: ['vehicle_report', uid, filters],
    queryFn: () => getVehicleReport(filters),
    enabled,
    staleTime: 3 * 60 * 1000,
  });
}

export function useVehicleReportFilters() {
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [vehicleType, setVehicleType] = useState<'all' | 'motorcycle' | 'car'>('all');
  const [status, setStatus] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [sortKey, setSortKey] = useState<SortKey>('maintenance_cost');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filters: VehicleReportFilters = useMemo(
    () => ({ fromDate: fromDate || undefined, toDate: toDate || undefined, vehicleType, status }),
    [fromDate, toDate, vehicleType, status]
  );

  const toggleExpand = (id: string) => setExpandedId((prev) => (prev === id ? null : id));

  return {
    fromDate, setFromDate,
    toDate, setToDate,
    vehicleType, setVehicleType,
    status, setStatus,
    search, setSearch,
    sortKey, setSortKey,
    expandedId, toggleExpand,
    filters,
  };
}

export function useSortedVehicles(data: VehicleReportRow[] | undefined, search: string, sortKey: SortKey) {
  return useMemo(() => {
    const rows = data ?? [];
    const t = search.trim().toLowerCase();
    const filtered = t
      ? rows.filter(
          (v) =>
            v.plate_number.toLowerCase().includes(t) ||
            (v.brand ?? '').toLowerCase().includes(t) ||
            (v.model ?? '').toLowerCase().includes(t) ||
            (v.current_rider ?? '').toLowerCase().includes(t)
        )
      : rows;

    return [...filtered].sort((a, b) => {
      switch (sortKey) {
        case 'maintenance_cost': return b.total_maintenance_cost - a.total_maintenance_cost;
        case 'maintenance_count': return b.maintenance_count - a.maintenance_count;
        case 'fuel_cost': return b.total_fuel_cost - a.total_fuel_cost;
        case 'km': return b.total_km - a.total_km;
        case 'plate': return a.plate_number.localeCompare(b.plate_number);
        default: return 0;
      }
    });
  }, [data, search, sortKey]);
}

export function useVehicleReportKPIs(data: VehicleReportRow[] | undefined) {
  return useMemo(() => {
    const rows = data ?? [];
    const totalVehicles = rows.length;
    const totalMaintenanceCost = rows.reduce((s, v) => s + v.total_maintenance_cost, 0);
    const totalFuelCost = rows.reduce((s, v) => s + v.total_fuel_cost, 0);
    const totalKm = rows.reduce((s, v) => s + v.total_km, 0);
    const totalOperatingCost = totalMaintenanceCost + totalFuelCost;
    const avgCostPerVehicle = totalVehicles > 0 ? totalOperatingCost / totalVehicles : 0;
    const highestMaintVehicle = rows.reduce<VehicleReportRow | null>(
      (best, v) => (!best || v.total_maintenance_cost > best.total_maintenance_cost ? v : best),
      null
    );

    const today = new Date().toISOString().split('T')[0];
    const soon = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const expiringDocs = rows.filter(
      (v) =>
        (v.insurance_expiry && v.insurance_expiry <= soon) ||
        (v.registration_expiry && v.registration_expiry <= soon) ||
        (v.authorization_expiry && v.authorization_expiry <= soon)
    ).length;
    const expiredDocs = rows.filter(
      (v) =>
        (v.insurance_expiry && v.insurance_expiry < today) ||
        (v.registration_expiry && v.registration_expiry < today) ||
        (v.authorization_expiry && v.authorization_expiry < today)
    ).length;

    const motorcycleCount = rows.filter((v) => v.type === 'motorcycle').length;
    const carCount = rows.filter((v) => v.type === 'car').length;
    const activeCount = rows.filter((v) => v.status === 'active').length;

    return {
      totalVehicles, totalMaintenanceCost, totalFuelCost, totalKm,
      totalOperatingCost, avgCostPerVehicle, highestMaintVehicle,
      expiringDocs, expiredDocs, motorcycleCount, carCount, activeCount,
    };
  }, [data]);
}
