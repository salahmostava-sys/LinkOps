    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.table_name);
    SELECT COUNT(*)
    INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = t.table_name;
    IF v_policy_count = 0 THEN
      EXECUTE format(
        '
      EXECUTE format(
        '
      EXECUTE format(
        '
      EXECUTE format(
        '
    END IF;
  END LOOP;
END
$$;

-- FILE: 20260325233000_fix_employees_rls_company_id_null.sql
﻿-- Fix employees RLS when jwt_company_id() is NULL.