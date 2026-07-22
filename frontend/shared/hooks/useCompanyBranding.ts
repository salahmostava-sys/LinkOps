import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { settingsHubService } from '@services/settingsHubService';
import { useAuthQueryGate } from '@shared/hooks/useAuthQueryGate';
import { tradeRegisterToBranding, type CompanyBranding } from '@shared/lib/documentBranding';

/**
 * Loads the client company's branding (name, unified/700 number, CR, VAT,
 * address) for printed-document headers/footers. Shares the React Query cache
 * with the Organization Info settings tab (same key).
 */
export function useCompanyBranding(): { branding: CompanyBranding; loading: boolean } {
  const { enabled } = useAuthQueryGate();
  const { data, isLoading } = useQuery({
    queryKey: ['settings', 'trade-register'],
    queryFn: () => settingsHubService.getTradeRegister(),
    enabled,
    staleTime: 60_000,
  });
  // Memoize so the branding object identity is stable across renders (safe to
  // put in effect dependency arrays).
  const branding = useMemo(() => tradeRegisterToBranding(data), [data]);
  return { branding, loading: isLoading };
}
