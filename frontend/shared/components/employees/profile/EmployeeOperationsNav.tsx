import { Bike, DollarSign, ExternalLink, HandCoins, ShoppingBag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

import { Button } from '@shared/components/ui/button';

type EmployeeOperationsNavProps = Readonly<{
  employeeName: string;
}>;

const operations = [
  { path: '/orders?tab=grid', label: 'الطلبات', icon: ShoppingBag },
  { path: '/salaries', label: 'الرواتب', icon: DollarSign },
  { path: '/advances', label: 'السلف', icon: HandCoins },
  { path: '/vehicle-assignment', label: 'العهدة', icon: Bike },
] as const;

export function EmployeeOperationsNav({ employeeName }: EmployeeOperationsNavProps) {
  const navigate = useNavigate();

  return (
    <nav className="flex flex-wrap items-center gap-2" aria-label="الانتقال إلى عمليات الموظف">
      {operations.map(({ path, label, icon: Icon }) => {
        const separator = path.includes('?') ? '&' : '?';
        const destination = `${path}${separator}search=${encodeURIComponent(employeeName)}`;
        return (
          <Button
            key={path}
            variant="outline"
            size="sm"
            className="gap-1.5"
            onClick={() => navigate(destination)}
          >
            <Icon size={14} />
            {label}
            <ExternalLink size={12} />
          </Button>
        );
      })}
    </nav>
  );
}
