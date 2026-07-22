WITH app_schemas AS (
  SELECT unnest(ARRAY['public', 'private', 'app_archive']) AS schema_name
)
SELECT jsonb_build_object(
  'schemas', COALESCE((
    SELECT jsonb_agg(n.nspname ORDER BY n.nspname)
    FROM pg_namespace n
    JOIN app_schemas s ON s.schema_name = n.nspname
  ), '[]'::jsonb),
  'relations', COALESCE((
    SELECT jsonb_agg(to_jsonb(relation_row) ORDER BY relation_row.schema_name, relation_row.relation_name)
    FROM (
      SELECT
        n.nspname AS schema_name,
        c.relname AS relation_name,
        c.relkind AS relation_kind,
        c.relrowsecurity AS row_security,
        c.relforcerowsecurity AS force_row_security
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
      WHERE c.relkind IN ('r', 'p', 'v', 'm', 'S')
    ) AS relation_row
  ), '[]'::jsonb),
  'columns', COALESCE((
    SELECT jsonb_agg(to_jsonb(column_row) ORDER BY column_row.schema_name, column_row.relation_name, column_row.ordinal_position)
    FROM (
      SELECT
        n.nspname AS schema_name,
        c.relname AS relation_name,
        a.attnum AS ordinal_position,
        a.attname AS column_name,
        format_type(a.atttypid, a.atttypmod) AS data_type,
        a.attnotnull AS not_null,
        pg_get_expr(d.adbin, d.adrelid) AS default_expression,
        a.attgenerated AS generated_kind,
        a.attidentity AS identity_kind
      FROM pg_attribute a
      JOIN pg_class c ON c.oid = a.attrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
      LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
      WHERE c.relkind IN ('r', 'p', 'v', 'm')
        AND a.attnum > 0
        AND NOT a.attisdropped
    ) AS column_row
  ), '[]'::jsonb),
  'constraints', COALESCE((
    SELECT jsonb_agg(to_jsonb(constraint_row) ORDER BY constraint_row.schema_name, constraint_row.relation_name, constraint_row.constraint_name)
    FROM (
      SELECT
        n.nspname AS schema_name,
        c.relname AS relation_name,
        con.conname AS constraint_name,
        con.contype AS constraint_type,
        pg_get_constraintdef(con.oid, true) AS definition
      FROM pg_constraint con
      JOIN pg_class c ON c.oid = con.conrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
    ) AS constraint_row
  ), '[]'::jsonb),
  'indexes', COALESCE((
    SELECT jsonb_agg(to_jsonb(index_row) ORDER BY index_row.schema_name, index_row.index_name)
    FROM (
      SELECT
        n.nspname AS schema_name,
        i.relname AS index_name,
        t.relname AS relation_name,
        pg_get_indexdef(i.oid) AS definition
      FROM pg_index x
      JOIN pg_class i ON i.oid = x.indexrelid
      JOIN pg_class t ON t.oid = x.indrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
    ) AS index_row
  ), '[]'::jsonb),
  'routines', COALESCE((
    SELECT jsonb_agg(to_jsonb(routine_row) ORDER BY routine_row.schema_name, routine_row.identity)
    FROM (
      SELECT
        n.nspname AS schema_name,
        p.oid::regprocedure::text AS identity,
        p.prokind AS routine_kind,
        p.prosecdef AS security_definer,
        p.provolatile AS volatility,
        pg_get_functiondef(p.oid) AS definition
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
      WHERE p.prokind IN ('f', 'p')
    ) AS routine_row
  ), '[]'::jsonb),
  'views', COALESCE((
    SELECT jsonb_agg(to_jsonb(view_row) ORDER BY view_row.schema_name, view_row.view_name)
    FROM (
      SELECT
        n.nspname AS schema_name,
        c.relname AS view_name,
        c.relkind AS view_kind,
        pg_get_viewdef(c.oid, true) AS definition,
        c.reloptions AS options
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
      WHERE c.relkind IN ('v', 'm')
    ) AS view_row
  ), '[]'::jsonb),
  'triggers', COALESCE((
    SELECT jsonb_agg(to_jsonb(trigger_row) ORDER BY trigger_row.schema_name, trigger_row.relation_name, trigger_row.trigger_name)
    FROM (
      SELECT
        n.nspname AS schema_name,
        c.relname AS relation_name,
        t.tgname AS trigger_name,
        pg_get_triggerdef(t.oid, true) AS definition
      FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname IN ('public', 'private', 'app_archive', 'auth', 'storage')
        AND NOT t.tgisinternal
    ) AS trigger_row
  ), '[]'::jsonb),
  'policies', COALESCE((
    SELECT jsonb_agg(to_jsonb(policy_row) ORDER BY policy_row.schema_name, policy_row.relation_name, policy_row.policy_name)
    FROM (
      SELECT
        schemaname AS schema_name,
        tablename AS relation_name,
        policyname AS policy_name,
        permissive,
        roles,
        cmd AS command,
        qual AS using_expression,
        with_check AS check_expression
      FROM pg_policies
      WHERE schemaname IN ('public', 'private', 'app_archive', 'auth', 'storage')
    ) AS policy_row
  ), '[]'::jsonb),
  'grants', COALESCE((
    SELECT jsonb_agg(to_jsonb(grant_row) ORDER BY grant_row.schema_name, grant_row.relation_name, grant_row.grantee, grant_row.privilege_type)
    FROM (
      SELECT table_schema AS schema_name, table_name AS relation_name, grantee, privilege_type
      FROM information_schema.role_table_grants
      WHERE table_schema IN ('public', 'private', 'app_archive')
    ) AS grant_row
  ), '[]'::jsonb),
  'enums', COALESCE((
    SELECT jsonb_agg(to_jsonb(enum_row) ORDER BY enum_row.schema_name, enum_row.type_name, enum_row.sort_order)
    FROM (
      SELECT
        n.nspname AS schema_name,
        t.typname AS type_name,
        e.enumsortorder AS sort_order,
        e.enumlabel AS label
      FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      JOIN pg_namespace n ON n.oid = t.typnamespace
      JOIN app_schemas s ON s.schema_name = n.nspname
    ) AS enum_row
  ), '[]'::jsonb),
  'publication_tables', COALESCE((
    SELECT jsonb_agg(to_jsonb(publication_row) ORDER BY publication_row.publication_name, publication_row.schema_name, publication_row.relation_name)
    FROM (
      SELECT pubname AS publication_name, schemaname AS schema_name, tablename AS relation_name
      FROM pg_publication_tables
      WHERE schemaname IN ('public', 'private', 'app_archive')
    ) AS publication_row
  ), '[]'::jsonb)
) AS catalog;
