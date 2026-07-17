import { createContext, useCallback, useContext, useEffect, ReactNode, useMemo, useState } from 'react';
import { DirectionProvider } from '@radix-ui/react-direction';
import i18n from '@app/i18n';
import {
  getInitialLanguage,
  persistLanguage,
  type AppLanguage,
} from '@app/i18n/language';

interface LanguageContextType {
  lang: AppLanguage;
  isRTL: boolean;
  setLang: (lang: AppLanguage) => void;
}

const LanguageContext = createContext<LanguageContextType>({} as LanguageContextType);

export const LanguageProvider = ({ children }: { children: ReactNode }) => {
  const [language, setLanguage] = useState<AppLanguage>(getInitialLanguage);

  const isRTL = language === 'ar';
  const setLang = useCallback((nextLanguage: AppLanguage) => {
    setLanguage(nextLanguage);
    persistLanguage(nextLanguage);
  }, []);

  useEffect(() => {
    document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
    document.documentElement.lang = language;
    document.documentElement.style.fontFamily = isRTL
      ? "'Tajawal', 'IBM Plex Sans Arabic', sans-serif"
      : "Inter, ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif";
    void i18n.changeLanguage(language);
  }, [language, isRTL]);

  const value = useMemo<LanguageContextType>(
    () => ({ lang: language, isRTL, setLang }),
    [language, isRTL, setLang],
  );

  return (
    <DirectionProvider dir={isRTL ? 'rtl' : 'ltr'}>
      <LanguageContext.Provider value={value}>
        {children}
      </LanguageContext.Provider>
    </DirectionProvider>
  );
};

export const useLanguage = () => useContext(LanguageContext);
