import { useLanguage } from '@app/providers/LanguageContext';
import { cn } from '@shared/lib/utils';

interface LanguageToggleProps {
  className?: string;
}

export function LanguageToggle({ className }: Readonly<LanguageToggleProps>) {
  const { lang, setLang } = useLanguage();

  return (
    <button
      onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}
      type="button"
      className={cn(
        'relative h-9 w-9 flex items-center justify-center rounded-full',
        'border border-border/60 bg-card/80 text-muted-foreground',
        'hover:bg-muted transition-colors flex-shrink-0 overflow-hidden font-bold text-xs',
        className
      )}
      title={lang === 'ar' ? 'Switch to English' : 'التبديل للعربية'}
      aria-label={lang === 'ar' ? 'Switch to English' : 'التبديل للعربية'}
    >
      {lang === 'ar' ? 'EN' : 'ع'}
    </button>
  );
}
