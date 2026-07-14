import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, act, fireEvent } from '@testing-library/react';
import { AuthProvider, useAuth } from '../AuthContext';
import { authService } from '@services/authService';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import React from 'react';

vi.mock('@services/authService', () => ({
  authService: {
    fetchUserRole: vi.fn(),
    fetchIsActive: vi.fn(),
    signIn: vi.fn(),
    signOut: vi.fn(),
    removeRealtimeChannel: vi.fn(),
    subscribeToProfileActiveChanges: vi.fn(() => ({
      unsubscribe: vi.fn()
    })),
    onAuthStateChange: vi.fn(() => ({
      unsubscribe: vi.fn()
    })),
    getSession: vi.fn(),
    refreshSession: vi.fn(),
  },
}));

vi.mock('@shared/lib/logger', () => ({
  logError: vi.fn(),
  logInfo: vi.fn(),
  logDebug: vi.fn(),
}));

// A test component to consume context
const TestConsumer = () => {
  const { user, role, loading, authLoading, signIn, signOut } = useAuth();
  
  if (loading || authLoading) return <div data-testid="loading">Loading...</div>;
  
  return (
    <div>
      <div data-testid="user-id">{user?.id || 'no-user'}</div>
      <div data-testid="role">{role || 'no-role'}</div>
      <button onClick={() => signIn('test@test.com', 'pass')} data-testid="btn-signin">Sign In</button>
      <button onClick={() => signOut()} data-testid="btn-signout">Sign Out</button>
    </div>
  );
};

describe('AuthContext', () => {
  let queryClient: QueryClient;

  beforeEach(() => {
    vi.clearAllMocks();
    queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false },
      },
    });
  });

  const renderWithProviders = (ui: React.ReactNode) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter>
          <AuthProvider>{ui}</AuthProvider>
        </MemoryRouter>
      </QueryClientProvider>
    );
  };

  it('provides null user and role when not authenticated', async () => {
    vi.mocked(authService.getSession).mockResolvedValue(null);
    vi.mocked(authService.refreshSession).mockResolvedValue({ session: null, user: null });

    renderWithProviders(<TestConsumer />);
    
    await waitFor(() => {
      expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    });

    expect(screen.getByTestId('user-id')).toHaveTextContent('no-user');
    expect(screen.getByTestId('role')).toHaveTextContent('no-role');
    await waitFor(() => expect(authService.refreshSession).toHaveBeenCalledTimes(1));
  });

  it('provides user and role when authenticated', async () => {
    const mockUser = { id: 'user-123', email: 'test@test.com' };
    const mockSession = { user: mockUser, access_token: 'token' };
    
    vi.mocked(authService.getSession).mockResolvedValue(mockSession as any);
    vi.mocked(authService.fetchUserRole).mockResolvedValue('admin');
    vi.mocked(authService.fetchIsActive).mockResolvedValue(true);

    renderWithProviders(<TestConsumer />);
    
    await waitFor(() => {
      expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    });

    expect(screen.getByTestId('user-id')).toHaveTextContent('user-123');
    expect(screen.getByTestId('role')).toHaveTextContent('admin');
  });

  it('handles signIn', async () => {
    vi.mocked(authService.getSession).mockResolvedValue(null);
    vi.mocked(authService.signIn).mockResolvedValue({ error: null } as any);

    renderWithProviders(<TestConsumer />);
    
    await waitFor(() => {
      expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    });

    const btn = screen.getByTestId('btn-signin');
    fireEvent.click(btn);

    await waitFor(() => {
      expect(authService.signIn).toHaveBeenCalledWith('test@test.com', 'pass');
    });
  });

  it('handles signOut', async () => {
    const mockUser = { id: 'user-123', email: 'test@test.com' };
    const mockSession = { user: mockUser, access_token: 'token' };
    
    vi.mocked(authService.getSession).mockResolvedValue(mockSession as any);
    vi.mocked(authService.fetchUserRole).mockResolvedValue('admin');
    vi.mocked(authService.fetchIsActive).mockResolvedValue(true);
    vi.mocked(authService.signOut).mockResolvedValue({ error: null } as any);

    renderWithProviders(<TestConsumer />);
    
    await waitFor(() => {
      expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    });

    await act(async () => {
      fireEvent.click(screen.getByTestId('btn-signout'));
    });

    expect(authService.signOut).toHaveBeenCalled();
  });
});
