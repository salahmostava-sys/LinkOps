-- Fix remaining auth.role() warnings

DROP POLICY IF EXISTS "unified_delete_policy" ON public."edge_rate_limits";
CREATE POLICY "unified_delete_policy" ON public."edge_rate_limits" FOR DELETE
  USING (((select auth.role()) = 'service_role'::text));

DROP POLICY IF EXISTS "unified_insert_policy" ON public."edge_rate_limits";
CREATE POLICY "unified_insert_policy" ON public."edge_rate_limits" FOR INSERT
  WITH CHECK (((select auth.role()) = 'service_role'::text));

DROP POLICY IF EXISTS "unified_select_policy" ON public."edge_rate_limits";
CREATE POLICY "unified_select_policy" ON public."edge_rate_limits" FOR SELECT
  USING (((select auth.role()) = 'service_role'::text));

DROP POLICY IF EXISTS "unified_update_policy" ON public."edge_rate_limits";
CREATE POLICY "unified_update_policy" ON public."edge_rate_limits" FOR UPDATE
  USING (((select auth.role()) = 'service_role'::text))
  WITH CHECK (((select auth.role()) = 'service_role'::text));

DROP POLICY IF EXISTS "unified_delete_policy" ON public."finance_transactions";
CREATE POLICY "unified_delete_policy" ON public."finance_transactions" FOR DELETE
  USING (((select auth.role()) = 'authenticated'::text));

DROP POLICY IF EXISTS "unified_insert_policy" ON public."finance_transactions";
CREATE POLICY "unified_insert_policy" ON public."finance_transactions" FOR INSERT
  WITH CHECK (((select auth.role()) = 'authenticated'::text));

DROP POLICY IF EXISTS "unified_select_policy" ON public."finance_transactions";
CREATE POLICY "unified_select_policy" ON public."finance_transactions" FOR SELECT
  USING (((select auth.role()) = 'authenticated'::text));

DROP POLICY IF EXISTS "unified_update_policy" ON public."finance_transactions";
CREATE POLICY "unified_update_policy" ON public."finance_transactions" FOR UPDATE
  USING (((select auth.role()) = 'authenticated'::text))
  WITH CHECK (((select auth.role()) = 'authenticated'::text));

DROP POLICY IF EXISTS "unified_delete_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_delete_policy" ON public."salary_slip_templates" FOR DELETE
  USING ((((select auth.role()) = 'authenticated'::text) OR (is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)) AND (has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_admin()) OR has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_operations())))));

DROP POLICY IF EXISTS "unified_insert_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_insert_policy" ON public."salary_slip_templates" FOR INSERT
  WITH CHECK ((((select auth.role()) = 'authenticated'::text) OR (is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)) AND (has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_admin()) OR has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_operations())))));

DROP POLICY IF EXISTS "unified_select_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_select_policy" ON public."salary_slip_templates" FOR SELECT
  USING ((((select auth.role()) = 'authenticated'::text) OR (is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)) AND (has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_admin()) OR has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_operations()))) OR (true OR is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)))));

DROP POLICY IF EXISTS "unified_update_policy" ON public."salary_slip_templates";
CREATE POLICY "unified_update_policy" ON public."salary_slip_templates" FOR UPDATE
  USING ((((select auth.role()) = 'authenticated'::text) OR (is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)) AND (has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_admin()) OR has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_operations())))))
  WITH CHECK ((((select auth.role()) = 'authenticated'::text) OR (is_active_user(( SELECT ( SELECT auth.uid() AS uid) AS uid)) AND (has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_admin()) OR has_role(( SELECT ( SELECT auth.uid() AS uid) AS uid), _const_role_operations())))));

