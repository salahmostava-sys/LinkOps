CREATE OR REPLACE FUNCTION pg_temp.baseline_data_snapshot()
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  relation_record record;
  relation_count bigint;
  relation_hash text;
  snapshot jsonb := '[]'::jsonb;
BEGIN
  FOR relation_record IN
    SELECT n.nspname AS schema_name, c.relname AS relation_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'p')
      AND (
        n.nspname IN ('public', 'private', 'app_archive')
        OR (n.nspname = 'storage' AND c.relname = 'buckets')
      )
    ORDER BY n.nspname, c.relname
  LOOP
    IF relation_record.schema_name = 'storage' AND relation_record.relation_name = 'buckets' THEN
      SELECT
        count(*),
        md5(COALESCE(string_agg(
          md5(jsonb_build_object(
            'id', id,
            'name', name,
            'public', public,
            'file_size_limit', file_size_limit,
            'allowed_mime_types', allowed_mime_types
          )::text),
          '' ORDER BY id
        ), ''))
      INTO relation_count, relation_hash
      FROM storage.buckets;
    ELSE
      EXECUTE format(
        'SELECT count(*), md5(COALESCE(string_agg(md5(to_jsonb(source_row)::text), '''' ORDER BY md5(to_jsonb(source_row)::text)), '''')) FROM %I.%I AS source_row',
        relation_record.schema_name,
        relation_record.relation_name
      )
      INTO relation_count, relation_hash;
    END IF;

    snapshot := snapshot || jsonb_build_array(jsonb_build_object(
      'schema_name', relation_record.schema_name,
      'relation_name', relation_record.relation_name,
      'row_count', relation_count,
      'content_hash', relation_hash
    ));
  END LOOP;

  RETURN snapshot;
END;
$$;

SELECT jsonb_build_object('data', pg_temp.baseline_data_snapshot()) AS catalog;
