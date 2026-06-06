-- Fix remaining auth_rls_initplan warnings

DROP POLICY IF EXISTS "unified_delete_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_delete_policy" ON public."salary_slip_templates" FOR DELETE
  USING (((auth.role() = 'authenticated'::text) OR (is_active_user(( SELECT (select auth.uid()) AS uid)) AND (has_role(( SELECT (select auth.uid()) AS uid), 'admin'::app_role) OR has_role(( SELECT (select auth.uid()) AS uid), 'operations'::app_role)))));

DROP POLICY IF EXISTS "unified_insert_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_insert_policy" ON public."salary_slip_templates" FOR INSERT
  WITH CHECK (((auth.role() = 'authenticated'::text) OR (is_active_user(( SELECT (select auth.uid()) AS uid)) AND (has_role(( SELECT (select auth.uid()) AS uid), 'admin'::app_role) OR has_role(( SELECT (select auth.uid()) AS uid), 'operations'::app_role)))));

DROP POLICY IF EXISTS "unified_select_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_select_policy" ON public."salary_slip_templates" FOR SELECT
  USING (((auth.role() = 'authenticated'::text) OR (is_active_user(( SELECT (select auth.uid()) AS uid)) AND (has_role(( SELECT (select auth.uid()) AS uid), 'admin'::app_role) OR has_role(( SELECT (select auth.uid()) AS uid), 'operations'::app_role))) OR (true OR is_active_user(( SELECT (select auth.uid()) AS uid)))));

DROP POLICY IF EXISTS "unified_update_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_update_policy" ON public."salary_slip_templates" FOR UPDATE
  USING (((auth.role() = 'authenticated'::text) OR (is_active_user(( SELECT (select auth.uid()) AS uid)) AND (has_role(( SELECT (select auth.uid()) AS uid), 'admin'::app_role) OR has_role(( SELECT (select auth.uid()) AS uid), 'operations'::app_role)))))
  WITH CHECK (((auth.role() = 'authenticated'::text) OR (is_active_user(( SELECT (select auth.uid()) AS uid)) AND (has_role(( SELECT (select auth.uid()) AS uid), 'admin'::app_role) OR has_role(( SELECT (select auth.uid()) AS uid), 'operations'::app_role)))));

