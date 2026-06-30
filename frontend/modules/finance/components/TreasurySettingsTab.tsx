import React, { useState } from 'react';
import { Button } from '@shared/components/ui/button';
import { Input } from '@shared/components/ui/input';
import { useTreasury } from '../hooks/useTreasury';
import type { TreasuryAccountType, TreasuryCategoryType } from '../types/treasury';
import { Landmark, Wallet, Banknote, Tag, Plus } from 'lucide-react';

export function TreasurySettingsTab() {
  const { accounts, categories, createAccount, createCategory } = useTreasury('', '');
  
  const [newAccName, setNewAccName] = useState('');
  const [newAccType, setNewAccType] = useState<TreasuryAccountType>('bank');
  
  const [newCatName, setNewCatName] = useState('');
  const [newCatType, setNewCatType] = useState<TreasuryCategoryType>('expense');

  const handleAddAccount = async () => {
    if (!newAccName.trim()) return;
    await createAccount({ name: newAccName, type: newAccType, initial_balance: 0 });
    setNewAccName('');
  };

  const handleAddCategory = async () => {
    if (!newCatName.trim()) return;
    await createCategory({ name: newCatName, type: newCatType });
    setNewCatName('');
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4">
      
      {/* Accounts Settings */}
      <div className="bg-card shadow-sm border border-border rounded-xl p-5">
        <h3 className="font-bold mb-4 flex items-center gap-2 text-foreground">
          <Landmark size={18} className="text-primary" />
          إدارة الحسابات والعهد
        </h3>
        
        <div className="flex gap-2 mb-4">
          <Input 
            value={newAccName} 
            onChange={e => setNewAccName(e.target.value)} 
            placeholder="اسم الحساب (مثال: بنك الراجحي)" 
            className="flex-1"
          />
          <select 
            value={newAccType} 
            onChange={e => setNewAccType(e.target.value as TreasuryAccountType)}
            className="bg-background border border-input rounded-md px-3 text-sm"
          >
            <option value="bank">بنك</option>
            <option value="cash">كاش</option>
            <option value="custody">عهدة</option>
          </select>
          <Button onClick={handleAddAccount} disabled={!newAccName.trim()} className="shrink-0 gap-1">
            <Plus size={16} /> إضافة
          </Button>
        </div>

        <div className="space-y-2">
          {accounts.map(acc => (
            <div key={acc.id} className="flex items-center justify-between p-3 rounded-lg bg-muted/40 border border-border/50">
              <div className="flex items-center gap-2">
                {acc.type === 'bank' && <Landmark size={14} className="text-blue-500" />}
                {acc.type === 'custody' && <Wallet size={14} className="text-purple-500" />}
                {acc.type === 'cash' && <Banknote size={14} className="text-emerald-500" />}
                <span className="font-medium text-sm">{acc.name}</span>
              </div>
              <span className="text-xs text-muted-foreground bg-muted px-2 py-0.5 rounded-full">
                {acc.type === 'bank' ? 'بنك' : acc.type === 'custody' ? 'عهدة' : 'كاش'}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Categories Settings */}
      <div className="bg-card shadow-sm border border-border rounded-xl p-5">
        <h3 className="font-bold mb-4 flex items-center gap-2 text-foreground">
          <Tag size={18} className="text-primary" />
          إدارة بنود المصاريف والإيرادات
        </h3>
        
        <div className="flex gap-2 mb-4">
          <Input 
            value={newCatName} 
            onChange={e => setNewCatName(e.target.value)} 
            placeholder="اسم البند (مثال: صيانة سيارات)" 
            className="flex-1"
          />
          <select 
            value={newCatType} 
            onChange={e => setNewCatType(e.target.value as TreasuryCategoryType)}
            className="bg-background border border-input rounded-md px-3 text-sm"
          >
            <option value="expense">مصروف</option>
            <option value="income">إيراد</option>
          </select>
          <Button onClick={handleAddCategory} disabled={!newCatName.trim()} className="shrink-0 gap-1">
            <Plus size={16} /> إضافة
          </Button>
        </div>

        <div className="space-y-2">
          {categories.map(cat => (
            <div key={cat.id} className="flex items-center justify-between p-3 rounded-lg bg-muted/40 border border-border/50">
              <span className="font-medium text-sm">{cat.name}</span>
              <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${cat.type === 'income' ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'}`}>
                {cat.type === 'income' ? 'إيراد' : 'مصروف'}
              </span>
            </div>
          ))}
        </div>
      </div>
      
    </div>
  );
}
