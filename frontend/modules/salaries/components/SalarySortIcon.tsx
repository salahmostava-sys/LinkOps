import { ChevronUp, ChevronDown } from 'lucide-react';
import type { SortDir } from '@modules/salaries/types/salary.types';

type SalarySortIconProps = Readonly<{
  field: string;
  sortField: string | null;
  sortDir: SortDir;
}>;

export function SalarySortIcon({ field, sortField, sortDir }: Readonly<SalarySortIconProps>) {
  if (sortField !== field || sortDir === null) return <span className="inline-block size-[10px] me-0.5" aria-hidden />;
  if (sortDir === 'asc') return <ChevronUp size={10} className="inline me-0.5 text-primary" />;
  return <ChevronDown size={10} className="inline me-0.5 text-primary" />;
}
