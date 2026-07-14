-- Complete the medium-risk archive step without deleting historical rows.
-- The legacy maintenance table remains recoverable by service_role, while
-- application roles cannot accidentally mutate the archived pre-fleet data.

DO $$
BEGIN
  IF to_regclass('public.maintenance_logs_legacy_pre_fleet') IS NOT NULL THEN
    ALTER TABLE public.maintenance_logs_legacy_pre_fleet ENABLE ROW LEVEL SECURITY;

    REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
      ON TABLE public.maintenance_logs_legacy_pre_fleet
      FROM PUBLIC, anon, authenticated;

    COMMENT ON TABLE public.maintenance_logs_legacy_pre_fleet IS
      'Read-only pre-fleet maintenance archive. Retained for recovery; application writes are revoked.';
  END IF;
END;
$$;
