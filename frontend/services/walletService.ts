import { supabase } from '@services/supabase/client';

export interface WalletBalance {
  employee_id: string;
  employee_name: string;
  employee_status: string;
  balance: number;
}

export interface WalletTransaction {
  id: string;
  employee_id: string;
  transaction_type: 'collection' | 'deposit';
  amount: number;
  transaction_date: string;
  notes: string | null;
  created_at: string;
}

const walletService = {
  /**
   * Fetch wallet balances for all active and absconded employees
   */
  async getWalletBalances(): Promise<WalletBalance[]> {
    const { data, error } = await supabase
      .from('employee_wallet_balances')
      .select('*')
      .in('employee_status', ['active', 'absconded']);

    if (error) throw error;
    return data as WalletBalance[];
  },

  /**
   * Add a new wallet transaction (collection or deposit)
   */
  async addTransaction(payload: Omit<WalletTransaction, 'id' | 'created_at'>): Promise<WalletTransaction> {
    const { data, error } = await supabase
      .from('employee_wallet_transactions')
      .insert([payload])
      .select()
      .single();

    if (error) throw error;
    return data as WalletTransaction;
  },

  /**
   * Fetch the history of transactions for a specific employee
   */
  async getEmployeeHistory(employeeId: string): Promise<WalletTransaction[]> {
    const { data, error } = await supabase
      .from('employee_wallet_transactions')
      .select('*')
      .eq('employee_id', employeeId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data as WalletTransaction[];
  },
  /**
   * Delete a specific wallet transaction
   */
  async deleteTransaction(id: string): Promise<void> {
    const { error } = await supabase
      .from('employee_wallet_transactions')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  /**
   * Clear all transactions for an employee
   */
  async clearWallet(employeeId: string): Promise<void> {
    const { error } = await supabase
      .from('employee_wallet_transactions')
      .delete()
      .eq('employee_id', employeeId);

    if (error) throw error;
  }
};

export default walletService;
