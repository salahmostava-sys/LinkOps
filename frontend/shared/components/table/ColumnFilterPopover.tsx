import type React from 'react';
import { useState } from 'react';
import { ChevronDown, X } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Input } from '@shared/components/ui/input';
import { Popover, PopoverContent, PopoverTrigger } from '@shared/components/ui/popover';

type ColumnFilterPopoverProps = {
  label: string;
  active: boolean;
  children: React.ReactNode;
  onClear: () => void;
};

export function ColumnFilterPopover({
  label,
  active,
  children,
  onClear,
}: Readonly<ColumnFilterPopoverProps>) {
  const [open, setOpen] = useState(false);
  const { t } = useTranslation();

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          className={`inline-flex items-center gap-0.5 rounded text-current transition-colors ${active ? 'opacity-100' : 'opacity-45 hover:opacity-80'}`}
          title={t('filterBy', { label })}
          onClick={(event) => event.stopPropagation()}
        >
          <ChevronDown size={10} />
          {active && <span className="h-1.5 w-1.5 rounded-full bg-current" />}
        </button>
      </PopoverTrigger>
      <PopoverContent
        className="max-h-80 w-56 space-y-2 overflow-y-auto p-3"
        align="start"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-center justify-between">
          <span className="text-xs font-medium text-foreground">{label}</span>
          {active && (
            <button
              type="button"
              onClick={() => {
                onClear();
                setOpen(false);
              }}
              className="flex items-center gap-1 text-xs text-destructive hover:underline"
            >
              <X size={10} /> {t('clear')}
            </button>
          )}
        </div>
        {children}
      </PopoverContent>
    </Popover>
  );
}

export function ColumnTextFilter({
  value,
  onChange,
}: Readonly<{
  value: string;
  onChange: (value: string) => void;
}>) {
  const { t } = useTranslation();

  return (
    <Input
      className="h-7 px-2 text-xs"
      placeholder={t('searchShort')}
      value={value}
      onChange={(event) => onChange(event.target.value)}
      onClick={(event) => event.stopPropagation()}
      autoFocus
    />
  );
}
