import type React from 'react';
import { ChevronDown, ChevronUp, ChevronsUpDown } from 'lucide-react';
import { Skeleton } from '@shared/components/ui/skeleton';
import { useSignedUrl, extractStoragePath } from '@shared/hooks/useSignedUrl';
import { getEmployeeCities } from '@modules/employees/model/employeeUtils';
import { cityLabel } from '@modules/employees/model/employeeCity';
import { useTranslation } from 'react-i18next';

export const CityBadge = ({ city }: { city?: string | null }) => {
  if (!city) return <span className="text-muted-foreground/40">•</span>;
  return (
    <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-muted text-muted-foreground">
      {cityLabel(city, city)}
    </span>
  );
};

export const CityBadges = ({ cities, city }: { cities?: string[] | null; city?: string | null }) => {
  const values = getEmployeeCities({ cities, city });
  if (values.length === 0) return <span className="text-muted-foreground/40">•</span>;
  return (
    <div className="flex flex-wrap justify-center gap-1">
      {values.map((value) => (
        <CityBadge key={value} city={value} />
      ))}
    </div>
  );
};

export const LicenseBadge = ({ status }: { status?: string | null }) => {
  const { t } = useTranslation();
  if (!status) return <span className="text-muted-foreground/40">•</span>;
  const map: Record<string, { label: string; cls: string }> = {
    has_license: { label: t('hasLicense'), cls: 'badge-success' },
    no_license: { label: t('noLicense'), cls: 'badge-urgent' },
    applied: { label: t('applied'), cls: 'badge-warning' },
  };
  const m = map[status];
  return m ? <span className={m.cls}>{m.label}</span> : null;
};

export const SponsorBadge = ({ status }: { status?: string | null }) => {
  const { t } = useTranslation();
  if (!status) return <span className="text-muted-foreground/40">•</span>;
  const map: Record<string, { label: string; cls: string }> = {
    sponsored: { label: t('sponsored'), cls: 'badge-info' },
    not_sponsored: {
      label: t('notSponsored'),
      cls: 'bg-muted text-muted-foreground text-xs font-medium px-2.5 py-0.5 rounded-full',
    },
    absconded: { label: t('absconded'), cls: 'badge-urgent' },
    terminated: { label: t('terminated'), cls: 'badge-urgent' },
  };
  const m = map[status];
  return m ? <span className={m.cls}>{m.label}</span> : null;
};

export const StatusBadge = ({ status }: { status?: string | null }) => {
  const { t } = useTranslation();
  if (!status) return <span className="text-muted-foreground/40">•</span>;
  if (status === 'active') return <span className="badge-success">{t('active')}</span>;
  if (status === 'inactive') return <span className="badge-warning">{t('inactive')}</span>;
  if (status === 'ended')
    return <span className="bg-muted text-muted-foreground text-xs font-medium px-2.5 py-0.5 rounded-full">{t('ended')}</span>;
  return <span className="text-muted-foreground/40">{status || '•'}</span>;
};

export const EmployeeAvatar = ({ path, name }: { path?: string | null; name: string }) => {
  const storagePath = extractStoragePath(path);
  const signedUrl = useSignedUrl('employee-documents', storagePath);
  if (!path) return null;
  if (!signedUrl) {
    return (
      <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center flex-shrink-0 text-xs font-semibold text-muted-foreground select-none">
        {name.charAt(0)}
      </div>
    );
  }
  return <img src={signedUrl} className="w-8 h-8 rounded-full object-cover flex-shrink-0" alt="" />;
};

export const SortIcon = ({
  field,
  sortField,
  sortDir,
}: {
  field: string;
  sortField: string | null;
  sortDir: 'asc' | 'desc' | null;
}) => {
  if (sortField !== field) return <ChevronsUpDown size={11} className="inline ms-1 text-current opacity-45" />;
  if (sortDir === 'asc') return <ChevronUp size={11} className="inline ms-1 text-current" />;
  return <ChevronDown size={11} className="inline ms-1 text-current" />;
};

export const SkeletonRow = ({ cols }: { cols: number }) => (
  <tr className="border-b border-border/30">
    {Array.from({ length: cols }, (_, i) => (
      <td key={i} className="ta-td">
        <Skeleton className="h-4 w-full" />
      </td>
    ))}
  </tr>
);


