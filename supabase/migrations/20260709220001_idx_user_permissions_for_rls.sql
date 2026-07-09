-- ══════════════════════════════════════════════════════════════════════════════
-- Perf: Add index on user_permissions(user_id, permission_key, can_view)
-- to speed up the EXISTS subquery added in the previous migration.
-- ══════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_user_permissions_user_page_view
  ON public.user_permissions (user_id, permission_key, can_view);
