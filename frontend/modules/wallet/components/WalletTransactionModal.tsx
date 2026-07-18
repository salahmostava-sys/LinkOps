import { BaseInput } from '@shared/components/ui/base-input';
import React, { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { format } from 'date-fns';
import { Loader2 } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@shared/components/ui/dialog';
import { Button } from '@shared/components/ui/button';
import { Label } from '@shared/components/ui/label';
import { Textarea } from '@shared/components/ui/textarea';
import { toast } from '@shared/components/ui/sonner';
import walletService from '@services/walletService';
import { useTranslation } from 'react-i18next';
import { useLanguage } from '@app/providers/LanguageContext';

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  employee: { id: string; name: string };
  type: 'collection' | 'deposit';
  onSuccess: () => void;
}

const WalletTransactionModal = ({ open, onOpenChange, employee, type, onSuccess }: Props) => {
  const { t } = useTranslation();
  const { isRTL } = useLanguage();
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [notes, setNotes] = useState('');

  const isCollection = type === 'collection';
  const title = isCollection
    ? t('walletRecordCashTitle', { name: employee.name })
    : t('walletTopUpTitle', { name: employee.name });
  const btnLabel = isCollection ? t('walletRecordCashAction') : t('walletConfirmTopUp');

  const mutation = useMutation({
    mutationFn: async () => {
      const numAmount = Number.parseFloat(amount);
      if (Number.isNaN(numAmount) || numAmount <= 0) throw new Error(t('walletInvalidAmount'));
      
      await walletService.addTransaction({
        employee_id: employee.id,
        transaction_type: type,
        amount: numAmount,
        transaction_date: date,
        notes: notes || null,
      });
    },
    onSuccess: () => {
      toast.success(t('walletTransactionSaved'));
      setAmount('');
      setNotes('');
      setDate(format(new Date(), 'yyyy-MM-dd'));
      onSuccess();
    },
    onError: (err: unknown) => {
      toast.error(err instanceof Error ? err.message : t('walletSaveError'));
    }
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[400px]" dir={isRTL ? 'rtl' : 'ltr'}>
        <DialogHeader>
          <DialogTitle className="text-start">{title}</DialogTitle>
        </DialogHeader>
        
        <div className="grid gap-4 py-4">
          <BaseInput label={t('walletAmountLabel')} id="amount"
              type="number"
              min="1"
              step="any"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder={t('walletAmountPlaceholder')}
              autoFocus />

          <BaseInput label={t('walletDateLabel')} id="date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)} />

          <div className="space-y-2">
            <Label htmlFor="notes">{t('walletNotesOptional')}</Label>
            <Textarea
              id="notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={t('walletNotesPlaceholder')}
              rows={3}
            />
          </div>
        </div>

        <DialogFooter className="gap-2 sm:justify-start">
          <Button 
            className="w-full sm:w-auto"
            onClick={() => mutation.mutate()}
            disabled={mutation.isPending || !amount}
          >
            {mutation.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : null}
            {btnLabel}
          </Button>
          <Button 
            variant="outline" 
            className="w-full sm:w-auto"
            onClick={() => onOpenChange(false)}
            disabled={mutation.isPending}
          >
            {t('cancel')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default WalletTransactionModal;
