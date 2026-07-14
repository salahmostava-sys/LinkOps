import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import { createElement, type ReactNode } from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { routesManifest } from '@app/routesManifest';

const mockAuthState = vi.hoisted(() => ({
  user: null as { id: string } | null,
}));

const permissionsServiceMock = vi.hoisted(() => ({
  getUserPermissions: vi.fn(() => Promise.resolve({})),
}));

vi.mock('@app/providers/AuthContext', () => ({
  useAuth: () => mockAuthState,
}));

vi.mock('@services/permissionsService', () => ({
  permissionsService: permissionsServiceMock,
}));

import { DEFAULT_PERMISSIONS, usePermissions, type PagePermission } from './usePermissions';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return function Wrapper({ children }: { children: ReactNode }) {
    return createElement(QueryClientProvider, { client: queryClient }, children);
  };
};

describe('DEFAULT_PERMISSIONS role templates', () => {
  it('keeps the expected high-risk role templates', () => {
    expect(DEFAULT_PERMISSIONS.admin.employees).toEqual({
      can_view: true,
      can_edit: true,
      can_delete: true,
    });
    expect(DEFAULT_PERMISSIONS.finance.salaries).toEqual({
      can_view: true,
      can_edit: true,
      can_delete: false,
    });
    expect(DEFAULT_PERMISSIONS.operations.maintenance).toEqual({
      can_view: true,
      can_edit: true,
      can_delete: true,
    });
  });

  it('keeps viewer templates read-only', () => {
    for (const permission of Object.values(DEFAULT_PERMISSIONS.viewer)) {
      expect(permission.can_edit).toBe(false);
      expect(permission.can_delete).toBe(false);
    }
  });

  it('covers every gated route', () => {
    const pageKeys = routesManifest
      .filter((route) => route.permission)
      .map((route) => route.permission?.replace(/^view_/, ''));

    for (const rolePermissions of Object.values(DEFAULT_PERMISSIONS)) {
      for (const pageKey of pageKeys) {
        expect(rolePermissions).toHaveProperty(pageKey as string);
      }
    }
  });
});

describe('usePermissions', () => {
  beforeEach(() => {
    mockAuthState.user = null;
    vi.clearAllMocks();
    permissionsServiceMock.getUserPermissions.mockResolvedValue({});
  });

  it('denies actions while the permission map is loading', async () => {
    let resolvePermissions!: (permissions: Record<string, PagePermission>) => void;
    const pendingPermissions = new Promise<Record<string, PagePermission>>((resolve) => {
      resolvePermissions = resolve;
    });
    mockAuthState.user = { id: 'u1' };
    permissionsServiceMock.getUserPermissions.mockReturnValue(pendingPermissions);

    const { result } = renderHook(() => usePermissions('employees'), { wrapper: createWrapper() });

    await waitFor(() => expect(result.current.loading).toBe(true));
    expect(result.current.permissions).toEqual({
      can_view: false,
      can_edit: false,
      can_delete: false,
    });

    resolvePermissions({
      employees: { can_view: true, can_edit: false, can_delete: false },
    });
    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.permissions.can_view).toBe(true);
  });

  it('denies actions when there is no authenticated user', () => {
    const { result } = renderHook(() => usePermissions('employees'), { wrapper: createWrapper() });

    expect(result.current.loading).toBe(false);
    expect(result.current.permissions).toEqual({
      can_view: false,
      can_edit: false,
      can_delete: false,
    });
  });

  it('uses one permission-map request for every page in the session', async () => {
    mockAuthState.user = { id: 'u1' };
    permissionsServiceMock.getUserPermissions.mockResolvedValue({
      employees: { can_view: true, can_edit: true, can_delete: false },
      salaries: { can_view: true, can_edit: false, can_delete: false },
    });

    const { result } = renderHook(() => ({
      employees: usePermissions('employees'),
      salaries: usePermissions('salaries'),
    }), { wrapper: createWrapper() });

    await waitFor(() => expect(result.current.employees.loading).toBe(false));
    expect(result.current.employees.permissions.can_edit).toBe(true);
    expect(result.current.salaries.permissions.can_edit).toBe(false);
    expect(permissionsServiceMock.getUserPermissions).toHaveBeenCalledTimes(1);
  });

  it('denies a page missing from the stored permission map', async () => {
    mockAuthState.user = { id: 'u1' };
    permissionsServiceMock.getUserPermissions.mockResolvedValue({
      alerts: { can_view: true, can_edit: false, can_delete: false },
    });

    const { result } = renderHook(() => usePermissions('employees'), { wrapper: createWrapper() });

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.permissions.can_view).toBe(false);
  });

  it('denies all actions when permission loading fails', async () => {
    mockAuthState.user = { id: 'u1' };
    permissionsServiceMock.getUserPermissions.mockRejectedValue(new Error('database unavailable'));

    const { result } = renderHook(() => usePermissions('employees'), { wrapper: createWrapper() });

    await waitFor(() => expect(result.current.loading).toBe(false));
    expect(result.current.permissions).toEqual({
      can_view: false,
      can_edit: false,
      can_delete: false,
    });
  });
});
