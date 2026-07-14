import { act, renderHook } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import type { PropsWithChildren } from 'react';

import { useUrlParamState } from '@shared/hooks/useUrlParamState';

function createWrapper(initialEntry: string) {
  return function RouterWrapper({ children }: PropsWithChildren) {
    return <MemoryRouter initialEntries={[initialEntry]}>{children}</MemoryRouter>;
  };
}

describe('useUrlParamState', () => {
  it('reads and updates a query parameter while preserving other parameters', () => {
    const { result } = renderHook(() => {
      const [search, setSearch] = useUrlParamState('search');
      const location = useLocation();
      return { search, setSearch, location };
    }, { wrapper: createWrapper('/orders?tab=grid&search=أحمد') });

    expect(result.current.search).toBe('أحمد');

    act(() => result.current.setSearch('محمد'));

    expect(result.current.search).toBe('محمد');
    expect(result.current.location.search).toContain('tab=grid');
    expect(result.current.location.search).toContain(`search=${encodeURIComponent('محمد')}`);
  });

  it('removes the parameter when it returns to the default value', () => {
    const { result } = renderHook(() => {
      const [status, setStatus] = useUrlParamState('status', 'all');
      const location = useLocation();
      return { status, setStatus, location };
    }, { wrapper: createWrapper('/salaries?status=approved') });

    act(() => result.current.setStatus('all'));

    expect(result.current.status).toBe('all');
    expect(result.current.location.search).toBe('');
  });
});
