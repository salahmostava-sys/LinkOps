import { useLocation, Navigate } from 'react-router-dom';
import { useAuth } from '@app/providers/AuthContext';
import { ReactNode, useEffect, useState } from 'react';
import Loading from '@shared/components/Loading';

const ProtectedRoute = ({ children }: { children: ReactNode }) => {
  const { session, loading, recoverSessionSilently } = useAuth();
  const [checkingRecovery, setCheckingRecovery] = useState(false);
  const location = useLocation();

  useEffect(() => {
    if (loading || session) return;
    let mounted = true;
    setCheckingRecovery(true);
    recoverSessionSilently().catch(() => {}).finally(() => {
      if (mounted) setCheckingRecovery(false);
    });
    return () => {
      mounted = false;
    };
  }, [loading, recoverSessionSilently, session]);

  if (loading || checkingRecovery) {
    const resetKey = `${location.pathname}${location.search}`;
    return <Loading minHeightClassName="min-h-screen" className="bg-background" resetKey={resetKey} />;
  }

  if (!session) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
