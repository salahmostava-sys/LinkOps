import { useCallback, type Dispatch, type SetStateAction } from 'react';
import { useSearchParams } from 'react-router-dom';

export function useUrlParamState(
  key: string,
  defaultValue = '',
): readonly [string, Dispatch<SetStateAction<string>>] {
  const [searchParams, setSearchParams] = useSearchParams();
  const value = searchParams.get(key) ?? defaultValue;

  const setValue = useCallback<Dispatch<SetStateAction<string>>>((nextValue) => {
    setSearchParams((currentParams) => {
      const params = new URLSearchParams(currentParams);
      const currentValue = params.get(key) ?? defaultValue;
      const resolvedValue = typeof nextValue === 'function'
        ? nextValue(currentValue)
        : nextValue;

      if (!resolvedValue || resolvedValue === defaultValue) {
        params.delete(key);
      } else {
        params.set(key, resolvedValue);
      }
      return params;
    }, { replace: true });
  }, [defaultValue, key, setSearchParams]);

  return [value, setValue] as const;
}
