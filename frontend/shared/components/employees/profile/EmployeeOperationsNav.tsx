import { Bike, DollarSign, ExternalLink, HandCoins, ShoppingBag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

import { Button } from '@shared/components/ui/button';

type EmployeeOperationsNavProps = Readonly<{
  employeeName: string;
  activeTab: string;
}>;

const operationByTab = {
  orders: { path: '/orders?tab=grid', label: 'فتح صفحة الطلبات', icon: ShoppingBag },
  salaries: { path: '/salaries', label: 'فتح صفحة الرواتب', icon: DollarSign },
  advances: { path: '/advances', label: 'فتح صفحة السلف', icon: HandCoins },
} as const;

const vehicleAssignmentOperation = {
  path: '/vehicle-assignment',
  label: 'العهدة',
  icon: Bike,
} as const;

export function EmployeeOperationsNav({ employeeName, activeTab }: EmployeeOperationsNavProps) {
  const navigate = useNavigate();
  const activeOperation = operationByTab[activeTab as keyof typeof operationByTab];
  const operations = activeOperation
    ? [activeOperation, vehicleAssignmentOperation]
    : [vehicleAssignmentOperation];

  return (
    <nav className="flex flex-wrap items-center gap-1" aria-label="إجراءات الموظف المرتبطة بالتبويب">
      {operations.map(({ path, label, icon: Icon }) => {
        const separator = path.includes('?') ? '&' : '?';
        const destination = `${path}${separator}search=${encodeURIComponent(employeeName)}`;
        return (
          <Button
            key={path}
            variant="outline"
            size="sm"
            className="h-8 gap-1.5"
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
