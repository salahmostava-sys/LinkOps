import { renderHook, act } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { useAdvancedFilter, type FilterConfig } from '../useAdvancedFilter';

describe('useAdvancedFilter', () => {
  const configs: FilterConfig[] = [
    { key: 'status', label: 'Status', type: 'single_select', defaultValues: ['active'] },
    { key: 'tags', label: 'Tags', type: 'multi_select' },
  ];

  it('initializes with default values', () => {
    const { result } = renderHook(() => useAdvancedFilter(configs));
    expect(result.current.filters).toEqual({
      status: ['active'],
      tags: [],
    });
    expect(result.current.activeCount).toBe(0);
  });

  it('sets a filter and updates active count', () => {
    const { result } = renderHook(() => useAdvancedFilter(configs));
    
    act(() => {
      result.current.setFilter('status', ['inactive']);
    });

    expect(result.current.filters.status).toEqual(['inactive']);
    expect(result.current.activeCount).toBe(1);
  });

  it('resets filters to default state', () => {
    const { result } = renderHook(() => useAdvancedFilter(configs));
    
    act(() => {
      result.current.setFilter('tags', ['tag1']);
      result.current.setFilter('status', ['inactive']);
    });

    expect(result.current.activeCount).toBe(2);

    act(() => {
      result.current.resetFilters();
    });

    expect(result.current.filters).toEqual({
      status: ['active'],
      tags: [],
    });
    expect(result.current.activeCount).toBe(0);
  });
});
