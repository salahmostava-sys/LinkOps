import { useEffect, useRef, useState } from 'react';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@shared/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@shared/components/ui/alert-dialog';
import { Button } from '@shared/components/ui/button';
import { Input } from '@shared/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@shared/components/ui/select';
import { Download, Eye, FileText, Loader2, Trash2, Upload } from 'lucide-react';
import { format, parseISO } from 'date-fns';
import { useToast } from '@shared/hooks/use-toast';
import { vehicleService } from '@services/vehicleService';
import type { Vehicle } from '@modules/pages/motorcycles.shared';
import { statusLabels, typeLabels } from '@modules/pages/motorcycles.shared';
import type { VehicleDocument, VehicleDocumentType } from '@services/vehicleService';
import { storageService } from '@services/storageService';
import { getErrorMessage } from '@services/serviceError';
import { logError } from '@shared/lib/logger';

const DOC_TYPE_LABELS: Record<VehicleDocumentType, string> = {
  license: 'رخصة السير',
  insurance: 'تأمين',
  registration: 'استمارة/تسجيل',
  authorization: 'تفويض',
  other: 'مستند آخر',
};

const DOC_TYPE_OPTIONS: VehicleDocumentType[] = ['license', 'insurance', 'registration', 'authorization', 'other'];

type VehicleDetailsModalProps = {
  vehicle: Vehicle;
  canEdit: boolean;
  canDelete: boolean;
  onClose: () => void;
};

const infoRow = (label: string, value: string) => (
  <div key={label} className="flex items-center justify-between gap-2 border-b border-border/30 py-1.5 text-sm last:border-0">
    <span className="text-muted-foreground">{label}</span>
    <span className="font-medium text-foreground">{value || '—'}</span>
  </div>
);

export function VehicleDetailsModal({ vehicle, canEdit, canDelete, onClose }: Readonly<VehicleDetailsModalProps>) {
  const { toast } = useToast();
  const fileRef = useRef<HTMLInputElement>(null);
  const [documents, setDocuments] = useState<VehicleDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [docType, setDocType] = useState<VehicleDocumentType>('license');
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<VehicleDocument | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [busyDocId, setBusyDocId] = useState<string | null>(null);

  const loadDocuments = async () => {
    setLoading(true);
    try {
      const docs = await vehicleService.getDocuments(vehicle.id);
      setDocuments(docs);
    } catch (err) {
      logError('[VehicleDetailsModal] load documents failed', err);
      toast({ title: 'تعذّر تحميل المستندات', description: getErrorMessage(err), variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDocuments().catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vehicle.id]);

  const handleUpload = async () => {
    if (!file) {
      toast({ title: 'اختر ملفاً أولاً', variant: 'destructive' });
      return;
    }
    setUploading(true);
    try {
      const ext = file.name.split('.').pop();
      const path = `${vehicle.id}/${docType}-${Date.now()}.${ext}`;
      await storageService.uploadFile('vehicle-documents', path, file);
      await vehicleService.addDocument({
        vehicle_id: vehicle.id,
        doc_type: docType,
        file_path: path,
        file_name: file.name,
      });
      toast({ title: '✅ تم رفع المستند' });
      setFile(null);
      if (fileRef.current) fileRef.current.value = '';
      await loadDocuments();
    } catch (err) {
      logError('[VehicleDetailsModal] upload failed', err);
      toast({ title: 'فشل رفع المستند', description: getErrorMessage(err), variant: 'destructive' });
    } finally {
      setUploading(false);
    }
  };

  const handleView = async (doc: VehicleDocument) => {
    setBusyDocId(doc.id);
    try {
      const url = await storageService.createSignedUrl('vehicle-documents', doc.file_path);
      window.open(url, '_blank', 'noopener,noreferrer');
    } catch (err) {
      toast({ title: 'تعذّر فتح المستند', description: getErrorMessage(err), variant: 'destructive' });
    } finally {
      setBusyDocId(null);
    }
  };

  const handleDownload = async (doc: VehicleDocument) => {
    setBusyDocId(doc.id);
    try {
      const url = await storageService.createSignedDownloadUrl('vehicle-documents', doc.file_path);
      const link = document.createElement('a');
      link.href = url;
      link.download = doc.file_name;
      link.click();
    } catch (err) {
      toast({ title: 'تعذّر تنزيل المستند', description: getErrorMessage(err), variant: 'destructive' });
    } finally {
      setBusyDocId(null);
    }
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await vehicleService.deleteDocument(deleteTarget.id);
      toast({ title: 'تم حذف المستند' });
      setDeleteTarget(null);
      await loadDocuments();
    } catch (err) {
      toast({ title: 'فشل حذف المستند', description: getErrorMessage(err), variant: 'destructive' });
    } finally {
      setDeleting(false);
    }
  };

  const renderDocsContent = () => {
    if (loading) {
      return (
        <div className="flex items-center justify-center gap-2 py-6 text-sm text-muted-foreground">
          <Loader2 size={16} className="animate-spin" /> جاري التحميل...
        </div>
      );
    }
    if (documents.length === 0) {
      return (
        <p className="py-6 text-center text-sm text-muted-foreground">لا توجد مستندات مرفوعة لهذه المركبة</p>
      );
    }
    return (
      <ul className="divide-y divide-border/40">
        {documents.map((doc) => (
          <li key={doc.id} className="flex items-center justify-between gap-2 px-3 py-2.5">
            <div className="min-w-0">
              <p className="truncate text-sm font-medium">{doc.file_name}</p>
              <p className="text-xs text-muted-foreground">
                {DOC_TYPE_LABELS[doc.doc_type] ?? doc.doc_type} • {format(parseISO(doc.created_at), 'yyyy/MM/dd')}
              </p>
            </div>
            <div className="flex shrink-0 items-center gap-1">
              <Button variant="ghost" size="icon" className="h-8 w-8" title="عرض" disabled={busyDocId === doc.id} onClick={() => handleView(doc)}>
                <Eye size={15} />
              </Button>
              <Button variant="ghost" size="icon" className="h-8 w-8" title="تنزيل" disabled={busyDocId === doc.id} onClick={() => handleDownload(doc)}>
                <Download size={15} />
              </Button>
              {canDelete && (
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-8 w-8 text-muted-foreground hover:text-destructive"
                  title="حذف"
                  onClick={() => setDeleteTarget(doc)}
                >
                  <Trash2 size={15} className="text-destructive" />
                </Button>
              )}
            </div>
          </li>
        ))}
      </ul>
    );
  };

  return (
    <>
      <Dialog open onOpenChange={(next) => !next && onClose()}>
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto" dir="rtl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FileText size={18} /> بيانات ومستندات المركبة — {vehicle.plate_number}
            </DialogTitle>
          </DialogHeader>

          {/* Vehicle summary */}
          <div className="rounded-xl border border-border/50 bg-muted/20 p-3">
            {infoRow('رقم اللوحة (عربي)', vehicle.plate_number)}
            {infoRow('رقم اللوحة (إنجليزي)', vehicle.plate_number_en ?? '')}
            {infoRow('النوع', typeLabels[vehicle.type])}
            {infoRow('الماركة / الموديل', [vehicle.brand, vehicle.model].filter(Boolean).join(' / '))}
            {infoRow('سنة الصنع', vehicle.year ? String(vehicle.year) : '')}
            {infoRow('الحالة', statusLabels[vehicle.status])}
            {infoRow('المندوب الحالي', vehicle.current_rider ?? '')}
            {infoRow('انتهاء التأمين', vehicle.insurance_expiry ? format(parseISO(vehicle.insurance_expiry), 'yyyy/MM/dd') : '')}
            {infoRow('انتهاء التسجيل', vehicle.registration_expiry ? format(parseISO(vehicle.registration_expiry), 'yyyy/MM/dd') : '')}
            {infoRow('انتهاء التفويض', vehicle.authorization_expiry ? format(parseISO(vehicle.authorization_expiry), 'yyyy/MM/dd') : '')}
            {infoRow('ملاحظات', vehicle.notes ?? '')}
          </div>

          {/* Upload new document */}
          {canEdit && (
            <div className="rounded-xl border border-border/50 p-3 space-y-2">
              <p className="text-sm font-semibold">رفع مستند جديد</p>
              <div className="grid grid-cols-1 sm:grid-cols-[9rem_1fr] gap-2">
                <Select value={docType} onValueChange={(v) => setDocType(v as VehicleDocumentType)}>
                  <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {DOC_TYPE_OPTIONS.map((t) => (
                      <SelectItem key={t} value={t}>{DOC_TYPE_LABELS[t]}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Input
                  ref={fileRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp,application/pdf"
                  className="h-9 text-xs file:h-full file:bg-transparent file:text-foreground file:text-xs file:font-medium file:border-0"
                  onChange={(e) => setFile(e.target.files?.[0] || null)}
                />
              </div>
              <div className="flex justify-end">
                <Button size="sm" className="gap-1.5" onClick={handleUpload} disabled={uploading || !file}>
                  {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
                  {uploading ? 'جاري الرفع...' : 'رفع المستند'}
                </Button>
              </div>
            </div>
          )}

          {/* Documents list */}
          <div className="rounded-xl border border-border/50">
            <div className="border-b border-border/50 px-3 py-2 text-sm font-semibold">المستندات ({documents.length})</div>
            {renderDocsContent()}
          </div>

          <DialogFooter className="mt-2">
            <Button variant="outline" onClick={onClose}>إغلاق</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => { if (!open) setDeleteTarget(null); }}>
        <AlertDialogContent dir="rtl">
          <AlertDialogHeader>
            <AlertDialogTitle>تأكيد حذف المستند</AlertDialogTitle>
            <AlertDialogDescription>
              هل أنت متأكد من حذف المستند <span className="font-semibold text-foreground">{deleteTarget?.file_name}</span>؟ لا يمكن التراجع عن هذا الإجراء.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>إلغاء</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={deleting} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              {deleting ? '⏳ جاري الحذف...' : 'حذف'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
