import { useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';

/**
 * يدير حالة التبويب النشط عبر معامل `tab` في رابط الصفحة (URL search params).
 * التبويب الافتراضي لا يُكتب في الرابط (يُحذف بدلاً من ذلك) لإبقاء الرابط نظيفاً.
 *
 * @param isValidTab دالة تتحقق من أن القيمة القادمة من الرابط تبويب صالح.
 * @param defaultTab التبويب الافتراضي عند غياب المعامل أو كونه غير صالح.
 */
export function useUrlTab<TTab extends string>(
  isValidTab: (value: string | null) => value is TTab,
  defaultTab: TTab,
) {
  const [searchParams, setSearchParams] = useSearchParams();

  const tab = useMemo(() => {
    const v = searchParams.get('tab');
    return isValidTab(v) ? v : defaultTab;
  }, [searchParams, isValidTab, defaultTab]);

  const onTabChange = useCallback(
    (v: string) => {
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (v === defaultTab) next.delete('tab');
          else next.set('tab', v);
          return next;
        },
        { replace: true },
      );
    },
    [setSearchParams, defaultTab],
  );

  return { tab, onTabChange } as const;
}
