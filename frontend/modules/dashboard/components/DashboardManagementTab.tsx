import { useQuery } from '@tanstack/react-query';
import { formatDistanceToNow } from 'date-fns';
import { ar } from 'date-fns/locale';
import { Clock, History } from 'lucide-react';

import { useTemporalContext } from '@app/providers/TemporalContext';
import { authQueryUserId, useAuthQueryGate } from '@shared/hooks/useAuthQueryGate';
import { Skeleton } from '@shared/components/ui/skeleton';
import { dashboardService } from '@services/dashboardService';

const FINANCE_VISIBLE_ROLES = new Set(['admin', 'hr', 'finance']);

function actionLabel(action: string, table: string) {
  if (table === 'violations') {
    if (action === 'INSERT') return 'تسجيل مخالفة جديدة';
    if (action === 'UPDATE') return 'تحديث مخالفة';
    if (action === 'DELETE') return 'حذف مخالفة';
  }
  if (table === 'salaries') {
    if (action === 'INSERT') return 'إصدار مسودة رواتب';
    if (action === 'UPDATE') return 'تحديث رواتب';
  }
  return `${action} على ${table}`;
}

export function DashboardManagementTab() {
  const { enabled, userId, role } = useAuthQueryGate();
  const uid = authQueryUserId(userId);
  const { selectedMonth: currentMonth } = useTemporalContext();

  const canSeeFinance = role ? FINANCE_VISIBLE_ROLES.has(role) : false;

  const managementQuery = useQuery({
    queryKey: ['system-management', uid, currentMonth, canSeeFinance] as const,
    enabled,
    staleTime: 60_000,
    queryFn: async () => {
      const [supervisorPerf, recentActivity] = await Promise.all([
        dashboardService.getSupervisorPerformance(currentMonth),
        canSeeFinance ? dashboardService.getRecentActivity(10) : Promise.resolve([]),
      ]);
      return { supervisorPerf, recentActivity };
    },
  });

  if (managementQuery.isLoading || !managementQuery.data) {
    return (
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <Skeleton className="bg-card h-64 shadow-card rounded-2xl" />
        {canSeeFinance && <Skeleton className="bg-card h-64 shadow-card rounded-2xl" />}
      </div>
    );
  }

  const { supervisorPerf, recentActivity } = managementQuery.data;

  return (
    <div className="grid grid-cols-1 xl:grid-cols-[1.2fr,0.8fr] gap-4">
      {/* Supervisor Performance */}
      <div className="bg-card p-5 shadow-card rounded-2xl">
        <div className="flex items-center justify-between gap-3 mb-4">
          <h3 className="text-lg font-bold text-foreground">أداء المشرفين</h3>
          <span className="text-sm font-semibold text-muted-foreground">{supervisorPerf.length} مشرف</span>
        </div>
        {supervisorPerf.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-6">لا توجد بيانات أهداف للمشرفين هذا الشهر</p>
        ) : (
          <div className="space-y-3">
            {supervisorPerf.map((row) => (
              <div key={row.supervisor_id} className="rounded-xl bg-muted/30 px-4 py-3 flex items-center justify-between gap-3">
                <span className="text-sm font-medium text-foreground">{row.supervisor_name}</span>
                <div className="flex items-center gap-3 text-xs">
                  <span className="text-muted-foreground font-semibold">
                    {row.actual_orders.toLocaleString('en-US')} طلب
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Recent Activity */}
      {canSeeFinance && (
        <div className="bg-card p-5 shadow-card rounded-2xl">
          <div className="flex items-center gap-2 mb-4">
            <History size={18} className="text-muted-foreground" />
            <h3 className="text-lg font-bold text-foreground">آخر الأنشطة في النظام</h3>
          </div>
          {recentActivity.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-6">لا توجد أنشطة حديثة</p>
          ) : (
            <div className="space-y-2">
              {recentActivity.map((entry) => (
                <div
                  key={`${entry.user_id ?? 'system'}-${entry.table_name}-${entry.created_at}`}
                  className="flex items-center justify-between gap-2 text-sm py-3 border-b border-border/40 last:border-0"
                >
                  <span className="text-foreground/85 font-medium">{actionLabel(entry.action, entry.table_name)}</span>
                  <span className="text-[12px] text-muted-foreground flex items-center gap-1">
                    <Clock size={12} />
                    {formatDistanceToNow(new Date(entry.created_at), { addSuffix: true, locale: ar })}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
