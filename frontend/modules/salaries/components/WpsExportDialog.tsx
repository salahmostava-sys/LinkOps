import { Loader2, AlertTriangle, Ban, CheckCircle2, FileSpreadsheet, FileText } from 'lucide-react';
import { Button } from '@shared/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@shared/components/ui/dialog';
import { bankRows, mudadRows, type WpsBuildResult } from '@modules/salaries/lib/wpsExport';
import type { WpsFormat } from '@modules/salaries/hooks/useWpsExport';

interface WpsExportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  loading: boolean;
  downloading: boolean;
  preview: WpsBuildResult | null;
  onDownload: (format: WpsFormat) => void;
}

const EXCLUDE_REASON_LABELS: Record<string, string> = {
  payment_method_cash: 'طريقة الدفع نقدي',
  invalid_iban: 'بدون آيبان صالح',
};

function countByReason(items: { reason: string }[]): { reason: string; count: number }[] {
  const map = new Map<string, number>();
  for (const it of items) map.set(it.reason, (map.get(it.reason) ?? 0) + 1);
  return [...map.entries()].map(([reason, count]) => ({ reason, count }));
}

export function WpsExportDialog({
  open,
  onOpenChange,
  loading,
  downloading,
  preview,
  onDownload,
}: Readonly<WpsExportDialogProps>) {
  const mudadCount = preview ? mudadRows(preview).length : 0;
  const bankCount = preview ? bankRows(preview).length : 0;
  const bankExcluded = preview?.bankExcluded ?? [];
  const warnings = preview?.warnings ?? [];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg" dir="rtl">
        <DialogHeader>
          <DialogTitle>تصدير حماية الأجور (WPS)</DialogTitle>
          <DialogDescription>
            مُدد يشمل الجميع (بنك ونقدي)؛ الملف البنكي للموظفين اللي عندهم آيبان فقط.
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="flex items-center justify-center gap-2 py-10 text-muted-foreground">
            <Loader2 size={18} className="animate-spin" /> جارٍ تجهيز المعاينة…
          </div>
        ) : (
          <div className="space-y-3">
            {/* Two eligibility counts */}
            <div className="grid grid-cols-2 gap-2">
              <div className="rounded-lg border border-success/30 bg-success/5 px-3 py-2 text-sm">
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 size={15} className="text-success" />
                  <span className="font-bold text-success">{mudadCount}</span>
                </div>
                <span className="text-xs text-muted-foreground">مؤهل لمُدد (بنك + نقدي)</span>
              </div>
              <div className="rounded-lg border border-primary/30 bg-primary/5 px-3 py-2 text-sm">
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 size={15} className="text-primary" />
                  <span className="font-bold text-primary">{bankCount}</span>
                </div>
                <span className="text-xs text-muted-foreground">مؤهل للملف البنكي (بآيبان)</span>
              </div>
            </div>

            {bankExcluded.length > 0 && (
              <div className="rounded-lg border border-border/60 bg-muted/30 px-3 py-2 text-sm">
                <div className="flex items-center gap-2 font-medium">
                  <Ban size={15} className="text-muted-foreground" />
                  خارج الملف البنكي ({bankExcluded.length})
                </div>
                <ul className="mt-1 ps-6 text-xs text-muted-foreground list-disc">
                  {countByReason(bankExcluded).map((r) => (
                    <li key={r.reason}>
                      {EXCLUDE_REASON_LABELS[r.reason] ?? r.reason}: {r.count}
                    </li>
                  ))}
                </ul>
                <p className="mt-1 text-[11px] text-muted-foreground">
                  دول موجودين في ملف مُدد، وبيدخلوا الملف البنكي بعد إضافة الآيبان من ملف الموظف.
                </p>
              </div>
            )}

            {warnings.length > 0 && (
              <div className="flex items-start gap-2 rounded-lg border border-warning/40 bg-warning/5 px-3 py-2 text-xs text-warning">
                <AlertTriangle size={15} className="mt-0.5 flex-shrink-0" />
                <span>
                  {warnings.length} موظف صافي راتبهم أقل من 50% من الإجمالي — قد ترفضهم مُدد حسب نظام العمل.
                </span>
              </div>
            )}

            {mudadCount === 0 && (
              <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-3 py-3 text-xs text-destructive">
                لا يوجد موظفون في القائمة الحالية لتصديرهم.
              </div>
            )}
          </div>
        )}

        <DialogFooter className="gap-2 sm:justify-start">
          <Button
            type="button"
            onClick={() => onDownload('mudad')}
            disabled={mudadCount === 0 || downloading || loading}
            className="gap-2"
          >
            <FileText size={15} /> مُدد (CSV)
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => onDownload('bank')}
            disabled={bankCount === 0 || downloading || loading}
            className="gap-2"
          >
            <FileSpreadsheet size={15} /> ملف بنكي (Excel)
          </Button>
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={downloading}>
            إغلاق
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
