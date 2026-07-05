import { Wrench } from 'lucide-react';
import { Tabs, TabsContent } from '@shared/components/ui/tabs';
import { Card, CardContent } from '@shared/components/ui/card';
import { ResponsiveTabBar } from '@shared/components/ResponsiveTabBar';
import { MaintenanceLogsTab } from '@modules/maintenance/components/MaintenanceLogsTab';
import { SparePartsTab } from '@modules/maintenance/components/SparePartsTab';
import { VehicleReportsTab } from '@modules/maintenance/components/VehicleReportsTab';
import { useAuthQueryGate } from '@shared/hooks/useAuthQueryGate';
import { usePermissions } from '@shared/hooks/usePermissions';
import { useUrlTab } from '@shared/hooks/useUrlTab';
import { PageLoadingState, PageAccessDeniedState } from '@shared/components/PageAccessState';

const MAINT_TABS = ['logs', 'inventory', 'vehicle-reports'] as const;
type MaintTab = (typeof MAINT_TABS)[number];

const isMaintTab = (v: string | null): v is MaintTab =>
  v !== null && MAINT_TABS.includes(v as MaintTab);

const MaintenancePage = () => {
  const { authLoading } = useAuthQueryGate();
  const { permissions, loading: permsLoading } = usePermissions('maintenance');
  const { tab, onTabChange } = useUrlTab(isMaintTab, 'logs');

  if (authLoading || permsLoading) {
    return <PageLoadingState />;
  }

  if (!permissions.can_view) {
    return <PageAccessDeniedState message="ليس لديك صلاحية الوصول لصفحة الصيانة" />;
  }

  return (
    <div className="flex flex-col gap-4 w-full max-w-[1600px]" dir="rtl">
      <div className="flex-shrink-0 space-y-1">
        <nav className="page-breadcrumb">
          <span>الرئيسية</span>
          <span className="page-breadcrumb-sep">/</span>
          <span>الصيانة والمخزون</span>
        </nav>
        <h1 className="page-title flex items-center gap-2">
          <Wrench size={18} /> الصيانة والمخزون
        </h1>
        <p className="text-sm text-muted-foreground">
          سجّل عمليات صيانة المركبات وتابع مخزون قطع الغيار وتكاليف الشراء
        </p>
      </div>

      <Card className="border-border/60 shadow-sm overflow-hidden">
        <CardContent className="p-3 sm:p-5 pt-4 sm:pt-5">
          <Tabs value={tab} onValueChange={onTabChange} dir="rtl" className="w-full">
            <ResponsiveTabBar
              value={tab}
              onValueChange={onTabChange}
              selectAriaLabel="قسم الصيانة والمخزون"
              options={[
                { value: 'logs', label: '🔧 سجل الصيانة', selectLabel: 'سجل الصيانة' },
                { value: 'inventory', label: '📦 المخزون وقطع الغيار', selectLabel: 'المخزون وقطع الغيار' },
                { value: 'vehicle-reports', label: '📊 تقارير المركبات', selectLabel: 'تقارير المركبات' },
              ]}
            />
            <TabsContent value="logs" className="mt-4 sm:mt-5 outline-none">
              <MaintenanceLogsTab />
            </TabsContent>
            <TabsContent value="inventory" className="mt-4 sm:mt-5 outline-none">
              <SparePartsTab />
            </TabsContent>
            <TabsContent value="vehicle-reports" className="mt-4 sm:mt-5 outline-none">
              <VehicleReportsTab />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
};

export default MaintenancePage;
