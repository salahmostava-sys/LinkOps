import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@app/providers/AuthContext';
import { treasuryService } from '@services/treasuryService';
import type { TreasuryTransaction, TreasuryAccount, TreasuryCategory } from './types/treasury';

export function useTreasury(from: string, to: string) {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const uid = user?.id;

  const accountsQuery = useQuery({
    queryKey: ['treasury_accounts', uid],
    queryFn: () => treasuryService.getAccounts(),
    enabled: !!uid,
  });

  const categoriesQuery = useQuery({
    queryKey: ['treasury_categories', uid],
    queryFn: () => treasuryService.getCategories(),
    enabled: !!uid,
  });

  const balancesQuery = useQuery({
    queryKey: ['treasury_balances', uid],
    queryFn: () => treasuryService.getAccountBalances(),
    enabled: !!uid,
  });

  const transactionsQuery = useQuery({
    queryKey: ['treasury_transactions', uid, from, to],
    queryFn: () => treasuryService.getTransactions(from, to),
    enabled: !!uid && !!from && !!to,
  });

  const createTransaction = useMutation({
    mutationFn: (input: Partial<TreasuryTransaction>) => treasuryService.createTransaction(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treasury_transactions'] });
      queryClient.invalidateQueries({ queryKey: ['treasury_balances'] });
    },
  });

  const createAccount = useMutation({
    mutationFn: (input: Partial<TreasuryAccount>) => treasuryService.createAccount(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treasury_accounts'] });
      queryClient.invalidateQueries({ queryKey: ['treasury_balances'] });
    },
  });

  const createCategory = useMutation({
    mutationFn: (input: Partial<TreasuryCategory>) => treasuryService.createCategory(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treasury_categories'] });
    },
  });

  return {
    accounts: accountsQuery.data ?? [],
    categories: categoriesQuery.data ?? [],
    balances: balancesQuery.data ?? [],
    transactions: transactionsQuery.data ?? [],
    isLoading: accountsQuery.isLoading || categoriesQuery.isLoading || transactionsQuery.isLoading || balancesQuery.isLoading,
    createTransaction: createTransaction.mutateAsync,
    createAccount: createAccount.mutateAsync,
    createCategory: createCategory.mutateAsync,
    isCreatingTransaction: createTransaction.isPending,
  };
}
