-- Keep INSERT/DELETE audit events for high-volume telemetry tables, but skip
-- UPDATE audit rows so frequent location/log refreshes do not overload storage.

CREATE OR REPLACE FUNCTION public.log_audit_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public /* NOSONAR */
AS $$
DECLARE
  v_row jsonb;
  v_id_text text;
  v_record_id uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND TG_TABLE_NAME IN ('driver_locations', 'app_logs') THEN
    RETURN NEW;
  END IF;

  v_row := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
  v_id_text := v_row ->> 'id';

  IF v_id_text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    v_record_id := v_id_text::uuid;
  END IF;

  INSERT INTO public.audit_log (user_id, table_name, action, record_id, old_value, new_value)
  VALUES (
    auth.uid(),
    TG_TABLE_NAME,
    TG_OP,
    v_record_id,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;
