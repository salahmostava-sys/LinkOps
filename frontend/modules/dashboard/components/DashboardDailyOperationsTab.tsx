import {
  AlertTriangle,
  Bike,
  CheckCircle2,
  ClipboardX,
  Smartphone,
  UserRoundX,
  Users,
} from 'lucide-react';
import type { ComponentType } from 'react';

import type {
  DailyOperationsSnapshot,
  OperationsRiderIssue,
  OperationsVehicleIssue,
} from '@services/operationsMonitorService';
import { Badge } from '@shared/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@shared/components/ui/card';
import { Skeleton } from '@shared/components/ui/skeleton';

type MetricCardProps = {
  label: string;
  value: number;
  sub?: string;
  icon: ComponentType<{ size?: number; className?: string }>;
  tone: 'blue' | 'green' | 'amber' | 'rose' | 'slate';
};

const toneClasses: Record<MetricCardProps['tone'], string> = {
  blue: 'bg-blue-50 text-blue-700',
  green: 'bg-emerald-50 text-emerald-700',
  amber: 'bg-amber-50 text-amber-700',
  rose: 'bg-rose-50 text-rose-700',
  slate: 'bg-slate-100 text-slate-700',
};

const issueTone: Record<OperationsRiderIssue['issueType'], string> = {
  absent: 'bg-rose-50 text-rose-700 border-rose-100',
  no_attendance: 'bg-amber-50 text-amber-700 border-amber-100',
  without_app: 'bg-blue-50 text-blue-700 border-blue-100',
  without_vehicle: 'bg-slate-100 text-slate-700 border-slate-200',
  inactive_orders: 'bg-orange-50 text-orange-700 border-orange-100',
};

function MetricCard({ label, value, sub, icon: Icon, tone }: Readonly<MetricCardProps>) {
  return (
    <Card className="shadow-card rounded-2xl">
      <CardContent className="p-4">
        <div className="flex items-start justify-between gap-3">
          <div className={`h-10 w-10 rounded-xl flex items-center justify-center ${toneClasses[tone]}`}>
            <Icon size={18} />
          </div>
          <p className="text-2xl font-black text-foreground leading-none">{value.toLocaleString('en-US')}</p>
        </div>
        <p className="mt-3 text-sm font-bold text-foreground">{label}</p>
        {sub ? <p className="mt-1 text-[11px] text-muted-foreground">{sub}</p> : null}
      </CardContent>
    </Card>
  );
}

function RiderIssuesTable({ issues }: Readonly<{ issues: OperationsRiderIssue[] }>) {
  return (
    <Card className="shadow-card rounded-2xl">
      <CardHeader className="p-5 pb-3">
        <div className="flex items-center justify-between gap-3">
          <CardTitle className="text-base font-black">مناديب تحتاج متابعة</CardTitle>
          <Badge variant="secondary">{issues.length.toLocaleString('en-US')}</Badge>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        {issues.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">لا توجد حالات متابعة اليوم</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/40 text-muted-foreground">
                <tr>
                  <th className="px-5 py-3 text-right font-bold">المندوب</th>
                  <th className="px-5 py-3 text-right font-bold">السبب</th>
                  <th className="px-5 py-3 text-right font-bold">المدينة</th>
                  <th className="px-5 py-3 text-right font-bold">طلبات حديثة</th>
                </tr>
              </thead>
              <tbody>
                {issues.map((issue) => (
                  <tr key={`${issue.employeeId}-${issue.issueType}`} className="border-t border-border/70">
                    <td className="px-5 py-3 font-bold text-foreground">{issue.name}</td>
                    <td className="px-5 py-3">
                      <span className={`inline-flex rounded-full border px-2.5 py-1 text-xs font-bold ${issueTone[issue.issueType]}`}>
                        {issue.issueLabel}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-muted-foreground">{issue.city}</td>
                    <td className="px-5 py-3 font-bold text-foreground">{issue.recentOrders.toLocaleString('en-US')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function VehiclesTable({ vehicles }: Readonly<{ vehicles: OperationsVehicleIssue[] }>) {
  return (
    <Card className="shadow-card rounded-2xl">
      <CardHeader className="p-5 pb-3">
        <div className="flex items-center justify-between gap-3">
          <CardTitle className="text-base font-black">مركبات غير مستغلة</CardTitle>
          <Badge variant="secondary">{vehicles.length.toLocaleString('en-US')}</Badge>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        {vehicles.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted-foreground">كل المركبات التشغيلية عليها تعيين مفتوح</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/40 text-muted-foreground">
                <tr>
                  <th className="px-5 py-3 text-right font-bold">رقم اللوحة</th>
                  <th className="px-5 py-3 text-right font-bold">الحالة</th>
                  <th className="px-5 py-3 text-right font-bold">النوع</th>
                  <th className="px-5 py-3 text-right font-bold">الشريحة</th>
                </tr>
              </thead>
              <tbody>
                {vehicles.map((vehicle) => (
                  <tr key={vehicle.vehicleId} className="border-t border-border/70">
                    <td className="px-5 py-3 font-black text-foreground">{vehicle.plateNumber}</td>
                    <td className="px-5 py-3 text-muted-foreground">{vehicle.status}</td>
                    <td className="px-5 py-3 text-muted-foreground">{vehicle.type}</td>
                    <td className="px-5 py-3">
                      <Badge variant={vehicle.hasFuelChip ? 'default' : 'outline'}>
                        {vehicle.hasFuelChip ? 'موجودة' : 'غير موجودة'}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export function DashboardDailyOperationsTab(props: Readonly<{
  loading: boolean;
  snapshot: DailyOperationsSnapshot | null;
}>) {
  const { loading, snapshot } = props;

  if (loading || !snapshot) {
    return (
      <div className="space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">
          {Array.from({ length: 5 }, (_, index) => (
            <Skeleton key={index} className="h-28 rounded-2xl bg-card shadow-card" />
          ))}
        </div>
        <Skeleton className="h-80 rounded-2xl bg-card shadow-card" />
      </div>
    );
  }

  const { totals } = snapshot;

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">
        <MetricCard label="مناديب تشغيل" value={totals.activeRiders} sub={snapshot.date} icon={Users} tone="blue" />
        <MetricCard label="حضور اليوم" value={totals.presentToday} icon={CheckCircle2} tone="green" />
        <MetricCard label="بدون حضور" value={totals.noAttendance} icon={ClipboardX} tone="amber" />
        <MetricCard label="بدون تطبيق" value={totals.ridersWithoutApps} icon={Smartphone} tone="rose" />
        <MetricCard label="مركبات غير مستغلة" value={totals.underusedVehicles} icon={Bike} tone="slate" />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-4 gap-4">
        <MetricCard label="غياب اليوم" value={totals.absentToday} icon={UserRoundX} tone="rose" />
        <MetricCard label="إجازة أو مرض" value={totals.leaveOrSickToday} icon={AlertTriangle} tone="amber" />
        <MetricCard label="بدون مركبة" value={totals.ridersWithoutVehicle} icon={Bike} tone="slate" />
        <MetricCard
          label="بدون طلبات حديثة"
          value={totals.inactiveRiders}
          sub={`آخر ${snapshot.inactiveWindowDays} أيام`}
          icon={ClipboardX}
          tone="amber"
        />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-[1.4fr,0.8fr] gap-4">
        <RiderIssuesTable issues={snapshot.riderIssues} />
        <VehiclesTable vehicles={snapshot.underusedVehicles} />
      </div>
    </div>
  );
}
