import { renderHook, act } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { TemporalProvider, useTemporalContext } from '../TemporalContext';
import { format } from 'date-fns';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <TemporalProvider>{children}</TemporalProvider>
);

describe('TemporalContext', () => {
  beforeEach(() => {
    sessionStorage.clear();
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('throws an error if used outside provider', () => {
    // Suppress console.error for expected React errors
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => renderHook(() => useTemporalContext())).toThrow('useTemporalContext must be used within a TemporalProvider');
    consoleError.mockRestore();
  });

  it('initializes with current month if sessionStorage is empty', () => {
    const { result } = renderHook(() => useTemporalContext(), { wrapper });
    expect(result.current.selectedMonth).toBe(format(new Date(), 'yyyy-MM'));
  });

  it('initializes with sessionStorage value if valid', () => {
    sessionStorage.setItem('global_selected_month', '2026-05');
    const { result } = renderHook(() => useTemporalContext(), { wrapper });
    expect(result.current.selectedMonth).toBe('2026-05');
  });

  it('initializes with current month if sessionStorage value is invalid', () => {
    sessionStorage.setItem('global_selected_month', 'invalid-date');
    const { result } = renderHook(() => useTemporalContext(), { wrapper });
    expect(result.current.selectedMonth).toBe(format(new Date(), 'yyyy-MM'));
  });

  it('updates selected month and sets sessionStorage on setSelectedMonth', () => {
    const { result } = renderHook(() => useTemporalContext(), { wrapper });
    
    act(() => {
      result.current.setSelectedMonth('2026-08');
    });

    expect(result.current.selectedMonth).toBe('2026-08');
    expect(sessionStorage.getItem('global_selected_month')).toBe('2026-08');
  });

  it('ignores invalid month string in setSelectedMonth', () => {
    const { result } = renderHook(() => useTemporalContext(), { wrapper });
    const current = result.current.selectedMonth;
    
    act(() => {
      result.current.setSelectedMonth('26-08');
    });

    expect(result.current.selectedMonth).toBe(current);
  });
});
