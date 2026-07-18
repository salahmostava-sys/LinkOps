import type { ReactNode } from 'react';
import { Inbox, Loader2 } from 'lucide-react';

export interface TableColumn<T> {
  key: string | keyof T;
  title: string;
  render?: (item: T, index: number) => ReactNode;
  className?: string;
}

export interface BaseTableProps<T> {
  data: T[];
  columns: TableColumn<T>[];
  emptyMessage?: string;
  className?: string;
  isLoading?: boolean;
  rowKey?: (item: T, index: number) => string;
}

export function BaseTable<T>({ 
  data, 
  columns, 
  emptyMessage = 'لا توجد سجلات لعرضها', 
  className = '', 
  isLoading = false,
  rowKey
}: Readonly<BaseTableProps<T>>) {
  if (isLoading) {
    return (
      <div className="ds-section flex min-h-48 w-full flex-col items-center justify-center gap-3 text-muted-foreground animate-pulse">
        <Loader2 className="w-8 h-8 animate-spin text-primary/50" />
        <p className="text-sm">جاري جلب البيانات...</p>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="ds-section flex min-h-48 w-full flex-col items-center justify-center gap-3 p-8 text-center text-muted-foreground">
        <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
          <Inbox className="w-6 h-6 opacity-60" />
        </div>
        <p className="text-sm">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className={`data-table-wrapper ${className}`}>
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((col, idx) => (
              <th key={String(col.key) + idx} className={`min-w-28 whitespace-normal ${col.className || ''}`}>
                {col.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {data.map((row, rowIndex) => (
            <tr key={rowKey ? rowKey(row, rowIndex) : String(((row as Record<string, unknown>).id as string | number | undefined) ?? rowIndex)} className="hover:bg-muted/30 transition-colors">
              {columns.map((col, colIndex) => (
                <td key={String(col.key) + colIndex} className={col.className || ''}>
                  {col.render ? col.render(row, rowIndex) : String((row as Record<keyof T, unknown>)[col.key as keyof T] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
