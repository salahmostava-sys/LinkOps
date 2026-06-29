CREATE TABLE IF NOT EXISTS public.edge_rate_limits (
  key text PRIMARY KEY,
  window_start timestamptz NOT NULL,
  request_count integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- FILE: 20260325213500_generate_missing_multitenant_rls_policies.sql
DO $$
DECLARE
  t record;
  v_policy_count integer;
BEGIN
  FOR t IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables tb
      ON tb.table_schema = c.table_schema
     AND tb.table_name = c.table_name
    WHERE c.table_schema = 'public'
      AND c.column_name = 'company_id'
      AND tb.table_type = 'BASE TABLE'
  LOOP
ALTER TABLE public.edge_rate_limits ENABLE ROW LEVEL SECURITY;

-- FILE: 20260411030000_fix_preview_salary_shift_threshold.sql
BEGIN;
COMMIT;

-- FILE: 20260411040000_fix_preview_salary_read_scheme.sql
BEGIN;
COMMIT;

-- FILE: 20260411050000_finance_transactions.sql