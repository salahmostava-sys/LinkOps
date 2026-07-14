import { useQuery } from '@tanstack/react-query';
import { format, addDays } from 'date-fns';
import { useSystemSettings } from '@app/providers/SystemSettingsContext';
import { authQueryUserId, useAuthQueryGate } from '@shared/hooks/useAuthQueryGate';
import { alertsService } from '@services/alertsService';
import {
  buildAlertsFromResponses,
  type EmployeeAlertRow,
  type VehicleExpiryRow,
  type PlatformAccountAlertRow,
  type PersistedAlertRow,
  type LowStockSparePartAlertRow,
  type AbscondedEmployeeAlertRow,
  type CommercialRecordRenewalCostRow,
} from '@shared/lib/alertsBuilder';
import { defaultQueryRetry } from '@shared/lib/query';

const FETCH_ALERTS_TIMEOUT_MS = 45_000;
const ALERTS_REFRESH_INTERVAL_MS = 5 * 60_000;
const ISO_DATE_FORMAT = 'yyyy-MM-dd';

export const useAlertSummary = () => {
  const { settings } = useSystemSettings();
  const { enabled, userId } = useAuthQueryGate();
  const uid = authQueryUserId(userId);
  const iqamaAlertDays = settings?.iqama_alert_days ?? 90;

  return useQuery({
    queryKey: ['alerts', uid, 'summary', iqamaAlertDays] as const,
    enabled,
    staleTime: ALERTS_REFRESH_INTERVAL_MS,
    refetchInterval: ALERTS_REFRESH_INTERVAL_MS,
    refetchOnWindowFocus: false,
    refetchOnReconnect: true,
    retry: defaultQueryRetry,
    queryFn: () => {
      const today = new Date();
      return alertsService.fetchSummary(
        format(addDays(today, iqamaAlertDays), ISO_DATE_FORMAT),
        format(addDays(today, 7), ISO_DATE_FORMAT),
      );
    },
  });
};

export const useAlerts = (options: { enabled?: boolean } = {}) => {
  const { settings } = useSystemSettings();
  const { enabled: authEnabled, userId } = useAuthQueryGate();
  const uid = authQueryUserId(userId);
  const iqamaAlertDays = settings?.iqama_alert_days ?? 90;
  const queryEnabled = authEnabled && (options.enabled ?? true);

  const query = useQuery({
    queryKey: ['alerts', uid, 'page-data', iqamaAlertDays],
    enabled: queryEnabled,
    queryFn: async () => {
      const today = new Date();
      /** كل التنبيهات الزمنية ضمن N يومًا من اليوم (يُضبط من إعدادات المشروع: أيام تنبيه الإقامة/المنصات) */
      const expiryHorizon = format(addDays(today, iqamaAlertDays), ISO_DATE_FORMAT);
      const [employeesRes, vehiclesRes, platformAccountsRes, dbAlertsRes, sparePartsRes, abscondedRes, commercialRecordsRes] =
        await alertsService.fetchAlertsDataWithTimeout(expiryHorizon, FETCH_ALERTS_TIMEOUT_MS);
      // Supabase responses are { data, error } — buildAlertsFromResponses reads only .data
      return buildAlertsFromResponses(
        {
          employeesRes: employeesRes as { data: EmployeeAlertRow[] | null },
          vehiclesRes: vehiclesRes as { data: VehicleExpiryRow[] | null },
          platformAccountsRes: platformAccountsRes as { data: PlatformAccountAlertRow[] | null },
          dbAlertsRes: dbAlertsRes as { data: PersistedAlertRow[] | null },
          sparePartsRes: sparePartsRes as { data: LowStockSparePartAlertRow[] | null },
          abscondedRes: abscondedRes as { data: AbscondedEmployeeAlertRow[] | null },
          commercialRecordsRes: commercialRecordsRes as { data: CommercialRecordRenewalCostRow[] | null },
        },
        expiryHorizon, today,
      );
    },
    retry: defaultQueryRetry,
    staleTime: 60_000,
    refetchOnWindowFocus: false,
    refetchOnReconnect: true,
    refetchInterval: ALERTS_REFRESH_INTERVAL_MS,
  });

  return { ...query, uid, iqamaAlertDays };
};
