-- Close the remaining privilege gaps at the API and file-storage boundaries.
-- This is a forward-only delta because all earlier migrations are already
-- applied to the linked production project.

-- Disabled accounts must not receive an application role from this RPC.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
  SELECT ur.role
  FROM public.user_roles ur
  WHERE ur.user_id = auth.uid()
    AND public.is_active_user(auth.uid())
  ORDER BY CASE ur.role
    WHEN 'admin'      THEN 1
    WHEN 'finance'    THEN 2
    WHEN 'hr'         THEN 3
    WHEN 'operations' THEN 4
    WHEN 'viewer'     THEN 5
    ELSE 99
  END
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_role() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated, service_role;

-- Rate limiting is enforced by the trusted API with the service-role client.
-- Browser clients do not need direct access to mutate the shared counters.
REVOKE EXECUTE ON FUNCTION public.enforce_rate_limit(text, integer, integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enforce_rate_limit(text, integer, integer)
  TO service_role;

-- Vehicle document metadata follows the same per-user permission source as
-- the vehicles page itself.
DROP POLICY IF EXISTS "Authenticated users can view vehicle documents"
  ON public.vehicle_documents;
CREATE POLICY "Authenticated users can view vehicle documents"
  ON public.vehicle_documents FOR SELECT
  TO authenticated
  USING (public.has_permission('vehicles', 'view'));

DROP POLICY IF EXISTS "Authenticated users can insert vehicle documents"
  ON public.vehicle_documents;
CREATE POLICY "Authenticated users can insert vehicle documents"
  ON public.vehicle_documents FOR INSERT
  TO authenticated
  WITH CHECK (public.has_permission('vehicles', 'write'));

DROP POLICY IF EXISTS "Authenticated users can update vehicle documents"
  ON public.vehicle_documents;
CREATE POLICY "Authenticated users can update vehicle documents"
  ON public.vehicle_documents FOR UPDATE
  TO authenticated
  USING (public.has_permission('vehicles', 'write'))
  WITH CHECK (public.has_permission('vehicles', 'write'));

DROP POLICY IF EXISTS "Authenticated users can delete vehicle documents"
  ON public.vehicle_documents;
CREATE POLICY "Authenticated users can delete vehicle documents"
  ON public.vehicle_documents FOR DELETE
  TO authenticated
  USING (public.has_permission('vehicles', 'delete'));

-- vehicle-documents storage access.
DROP POLICY IF EXISTS "Authenticated users can upload vehicle documents"
  ON storage.objects;
CREATE POLICY "Authenticated users can upload vehicle documents"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'vehicle-documents'
    AND public.has_permission('vehicles', 'write')
  );

DROP POLICY IF EXISTS "Authenticated users can update their vehicle documents"
  ON storage.objects;
CREATE POLICY "Authenticated users can update their vehicle documents"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'vehicle-documents'
    AND public.has_permission('vehicles', 'write')
  )
  WITH CHECK (
    bucket_id = 'vehicle-documents'
    AND public.has_permission('vehicles', 'write')
  );

DROP POLICY IF EXISTS "Authenticated users can delete vehicle documents"
  ON storage.objects;
CREATE POLICY "Authenticated users can delete vehicle documents"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'vehicle-documents'
    AND public.has_permission('vehicles', 'delete')
  );

DROP POLICY IF EXISTS "Authenticated users can view vehicle document files"
  ON storage.objects;
CREATE POLICY "Authenticated users can view vehicle document files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'vehicle-documents'
    AND public.has_permission('vehicles', 'view')
  );

-- Advance attachments are shared by the advances and treasury workflows.
DROP POLICY IF EXISTS "Authenticated users can upload advance attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can upload advance attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'advance-attachments'
    AND (
      public.has_permission('advances', 'write')
      OR public.has_permission('finance', 'write')
    )
  );

DROP POLICY IF EXISTS "Authenticated users can update their advance attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can update their advance attachments"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'advance-attachments'
    AND (
      public.has_permission('advances', 'write')
      OR public.has_permission('finance', 'write')
    )
  )
  WITH CHECK (
    bucket_id = 'advance-attachments'
    AND (
      public.has_permission('advances', 'write')
      OR public.has_permission('finance', 'write')
    )
  );

DROP POLICY IF EXISTS "Authenticated users can delete advance attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can delete advance attachments"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'advance-attachments'
    AND (
      public.has_permission('advances', 'delete')
      OR public.has_permission('finance', 'delete')
    )
  );

DROP POLICY IF EXISTS "Authenticated users can view advance attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can view advance attachments"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'advance-attachments'
    AND (
      public.has_permission('advances', 'view')
      OR public.has_permission('finance', 'view')
    )
  );

-- Invoice scans belong to the maintenance workflow.
DROP POLICY IF EXISTS "Authenticated users can upload invoice attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can upload invoice attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'invoice-attachments'
    AND public.has_permission('maintenance', 'write')
  );

DROP POLICY IF EXISTS "Authenticated users can update invoice attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can update invoice attachments"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'invoice-attachments'
    AND public.has_permission('maintenance', 'write')
  )
  WITH CHECK (
    bucket_id = 'invoice-attachments'
    AND public.has_permission('maintenance', 'write')
  );

DROP POLICY IF EXISTS "Authenticated users can delete invoice attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can delete invoice attachments"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'invoice-attachments'
    AND public.has_permission('maintenance', 'delete')
  );

DROP POLICY IF EXISTS "Authenticated users can view invoice attachments"
  ON storage.objects;
CREATE POLICY "Authenticated users can view invoice attachments"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'invoice-attachments'
    AND public.has_permission('maintenance', 'view')
  );
