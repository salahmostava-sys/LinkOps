import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@shared/components/ui/dialog';
import { Button } from '@shared/components/ui/button';
import { Label } from '@shared/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@shared/components/ui/select';
import { FileSpreadsheet, Printer } from 'lucide-react';
import type { App } from '@modules/orders/types';

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  apps: App[];
  daysInMonth: number;
  onExportExcel: (appId: string, startDay: number, endDay: number) => void;
  onPrintPdf: (appId: string, startDay: number, endDay: number) => void;
}

export function DailyAppReportDialog({ open, onOpenChange, apps, daysInMonth, onExportExcel, onPrintPdf }: Props) {
  const [selectedApp, setSelectedApp] = useState<string>('');
  const [startDay, setStartDay] = useState<string>('1');
  const [endDay, setEndDay] = useState<string>(String(daysInMonth));

  const daysOptions = Array.from({ length: daysInMonth }, (_, i) => i + 1);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]" dir="rtl">
        <DialogHeader>
          <DialogTitle>تقرير منصة مخصص</DialogTitle>
          <DialogDescription>
            حدد المنصة والفترة الزمنية (من بداية الشهر المفتوح) لاستخراج التقرير.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label>المنصة / التطبيق</Label>
            <Select value={selectedApp} onValueChange={setSelectedApp}>
              <SelectTrigger>
                <SelectValue placeholder="اختر التطبيق..." />
              </SelectTrigger>
              <SelectContent dir="rtl">
                {apps.map(app => (
                  <SelectItem key={app.id} value={app.id}>{app.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label>من يوم</Label>
              <Select value={startDay} onValueChange={setStartDay}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent dir="rtl" className="max-h-48">
                  {daysOptions.map(d => (
                    <SelectItem key={d} value={String(d)}>{d}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label>إلى يوم</Label>
              <Select value={endDay} onValueChange={setEndDay}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent dir="rtl" className="max-h-48">
                  {daysOptions.map(d => (
                    <SelectItem key={d} value={String(d)}>{d}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </div>

        <div className="flex justify-between gap-3 mt-4">
          <Button 
            className="flex-1 bg-green-600 hover:bg-green-700 text-white gap-2" 
            disabled={!selectedApp}
            onClick={() => {
              onExportExcel(selectedApp, Number(startDay), Number(endDay));
              onOpenChange(false);
            }}
          >
            <FileSpreadsheet size={16} /> تنزيل Excel
          </Button>
          <Button 
            className="flex-1 gap-2" 
            variant="secondary"
            disabled={!selectedApp}
            onClick={() => {
              onPrintPdf(selectedApp, Number(startDay), Number(endDay));
              onOpenChange(false);
            }}
          >
            <Printer size={16} /> طباعة / PDF
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
