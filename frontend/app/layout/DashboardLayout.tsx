import type { ReactNode } from 'react';
import AppLayout from '@shared/components/AppLayout';

interface DashboardLayoutProps {
  children: ReactNode;
}

/**
 * Dashboard wrapper requested by routing refactor.
 * It keeps the existing sidebar + header behavior from `AppLayout`.
 */
const DashboardLayout = ({ children }: Readonly<DashboardLayoutProps>) => {
  return <AppLayout>{children}</AppLayout>;
};

export default DashboardLayout;

