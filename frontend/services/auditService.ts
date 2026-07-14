import { supabase } from '@services/supabase/client';
import type { Json } from '@services/supabase/types';
import { authService } from '@services/authService';

export type AdminActionLogPayload = {
  action: string;
  table_name?: string | null;
  record_id?: string | null;
  meta?: Record<string, unknown>;
};

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export const auditService = {
  logAdminAction: async (payload: AdminActionLogPayload) => {
    const user = await authService.getCurrentUser();
    const userId = user?.id ?? null;
    const { error } = await supabase.from('audit_log').insert({
      user_id: userId,
      action: payload.action,
      table_name: payload.table_name ?? 'system',
      record_id: payload.record_id && UUID_PATTERN.test(payload.record_id) ? payload.record_id : null,
      new_value: { meta: payload.meta ?? {} } as Json,
    });
    // Audit logging is a secondary side-effect. Never throw here — an RLS
    // error or transient network failure must not block the user's primary
    // action (delete, save, etc.).
    if (error) {
      console.warn('[auditService] logAdminAction failed (non-fatal):', error.message);
    }
  },
};
