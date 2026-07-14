import { supabase } from '@services/supabase/client';
import { handleSupabaseError } from '@services/serviceError';

export interface PagePermission {
  can_view: boolean;
  can_edit: boolean;
  can_delete: boolean;
}

export type PermissionMap = Record<string, PagePermission>;

export const permissionsService = {
  getUserPermissions: async (userId: string): Promise<PermissionMap> => {
    const { data, error } = await supabase
      .from('user_permissions')
      .select('permission_key, can_view, can_edit, can_delete')
      .eq('user_id', userId);

    if (error) handleSupabaseError(error, 'permissionsService.getUserPermissions');

    return Object.fromEntries((data ?? []).map((row) => [
      row.permission_key,
      {
        can_view: row.can_view,
        can_edit: row.can_edit,
        can_delete: row.can_delete,
      },
    ]));
  },
};
