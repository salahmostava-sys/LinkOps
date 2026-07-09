#!/usr/bin/env node
/**
 * Dump full public schema from Supabase using direct PostgreSQL connection.
 * Uses pg (node-postgres) to query information_schema and pg_catalog.
 */

const PGHOST = 'aws-1-ap-south-1.pooler.supabase.com';
const PGPORT = 5432;
const PGUSER = 'cli_login_postgres.plxpehtkabmfkdlgjyin';
const PGPASSWORD = process.env.DB_PASSWORD || '';
const PGDATABASE = 'postgres';

import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { writeFileSync, existsSync } from 'node:fs';
import { execSync } from 'node:child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');

// Install pg if not available
try {
  createRequire(import.meta.url)('pg');
} catch {
  console.log('Installing pg...');
  // NOSONAR
  execSync('npm install pg --no-save', { cwd: repoRoot, stdio: 'inherit' });
}

const { default: pg } = await import('pg');
const { Client } = pg;

const client = new Client({
  host: PGHOST,
  port: PGPORT,
  user: PGUSER,
  password: PGPASSWORD,
  database: PGDATABASE,
  ssl: { rejectUnauthorized: false },
});

console.log('Connecting to Supabase PostgreSQL...');
await client.connect();
console.log('Connected ✅');

const lines = [];
const out = (...args) => lines.push(args.join(' '));

out('-- ================================================================');
out('-- Full Schema Dump: public schema');
out(`-- Host: ${PGHOST}`);
out(`-- Generated: ${new Date().toISOString()}`);
out('-- ================================================================');
out('');

// 1. ENUMS
out('-- ================================================================');
out('-- ENUMS');
out('-- ================================================================');
const enums = await client.query(`
  SELECT t.typname AS enum_name,
         array_agg(e.enumlabel ORDER BY e.enumsortorder) AS enum_values
  FROM pg_type t
  JOIN pg_enum e ON t.oid = e.enumtypid
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'public'
  GROUP BY t.typname
  ORDER BY t.typname;
`);
for (const row of enums.rows) {
  out(`CREATE TYPE public.${row.enum_name} AS ENUM (`);
  const vals = Array.isArray(row.enum_values) ? row.enum_values : JSON.parse(row.enum_values.replace('{','[').replace('}',']').replace(/(\w+)/g, '"$1"'));
  out('  ' + vals.map(v => `'${v}'`).join(',\n  '));
  out(');');
  out('');
}

// 2. TABLES with columns
out('-- ================================================================');
out('-- TABLES');
out('-- ================================================================');
const tables = await client.query(`
  SELECT tablename AS table_name
  FROM pg_tables
  WHERE schemaname = 'public'
  ORDER BY tablename;
`);

for (const trow of tables.rows) {
  const tname = trow.table_name;
  
  const cols = await client.query(`
    SELECT
      a.attname AS column_name,
      pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
      CASE WHEN a.attnotnull THEN 'NO' ELSE 'YES' END AS is_nullable,
      pg_catalog.pg_get_expr(d.adbin, d.adrelid) AS column_default
    FROM pg_catalog.pg_attribute a
    LEFT JOIN pg_catalog.pg_attrdef d ON (a.attrelid = d.adrelid AND a.attnum = d.adnum)
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = $1
      AND a.attnum > 0
      AND NOT a.attisdropped
    ORDER BY a.attnum;
  `, [tname]);

  out(`CREATE TABLE IF NOT EXISTS public."${tname}" (`);
  const colDefs = [];
  for (const col of cols.rows) {
    const nullable = col.is_nullable === 'NO' ? ' NOT NULL' : '';
    const def = col.column_default ? ` DEFAULT ${col.column_default}` : '';
    colDefs.push(`    "${col.column_name}" ${col.data_type}${nullable}${def}`);
  }
  out(colDefs.join(',\n'));
  out(');');
  out('');
}

// 3. FOREIGN KEYS
out('-- ================================================================');
out('-- FOREIGN KEYS');
out('-- ================================================================');
const fkeys = await client.query(`
  SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
  FROM information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
  JOIN information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
  ORDER BY tc.table_name, tc.constraint_name;
`);
for (const fk of fkeys.rows) {
  out(`ALTER TABLE ONLY public."${fk.table_name}"`);
  out(`  ADD CONSTRAINT "${fk.constraint_name}" FOREIGN KEY ("${fk.column_name}") REFERENCES public."${fk.foreign_table_name}"("${fk.foreign_column_name}") ON DELETE ${fk.delete_rule};`);
}
out('');

// 4. INDEXES
out('-- ================================================================');
out('-- INDEXES');
out('-- ================================================================');
const indexes = await client.query(`
  SELECT indexname, tablename, indexdef
  FROM pg_indexes
  WHERE schemaname = 'public' AND indexname NOT LIKE '%_pkey'
  ORDER BY tablename, indexname;
`);
for (const idx of indexes.rows) {
  out(`${idx.indexdef};`);
}
out('');

// 5. RLS POLICIES
out('-- ================================================================');
out('-- RLS POLICIES');
out('-- ================================================================');
const policies = await client.query(`
  SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
  FROM pg_policies
  WHERE schemaname = 'public'
  ORDER BY tablename, policyname;
`);
for (const p of policies.rows) {
  out(`-- Table: ${p.tablename}, Policy: ${p.policyname} (${p.cmd})`);
  out(`CREATE POLICY "${p.policyname}" ON public."${p.tablename}"`);
  out(`  AS ${p.permissive} FOR ${p.cmd}`);
  if (p.qual) out(`  USING (${p.qual})`);
  if (p.with_check) out(`  WITH CHECK (${p.with_check})`);
  out(';');
  out('');
}

// 6. FUNCTIONS (non-system)
out('-- ================================================================');
out('-- FUNCTIONS');
out('-- ================================================================');
const funcs = await client.query(`
  SELECT 
    p.proname AS func_name,
    pg_get_function_identity_arguments(p.oid) AS args,
    pg_get_functiondef(p.oid) AS definition
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.prokind = 'f'
    AND p.proname NOT LIKE '\\_%'
  ORDER BY p.proname;
`);
for (const fn of funcs.rows) {
  out(`-- Function: public.${fn.func_name}(${fn.args})`);
  out(fn.definition);
  out('');
}

// 7. VIEWS
out('-- ================================================================');
out('-- VIEWS');
out('-- ================================================================');
const views = await client.query(`
  SELECT c.relname AS table_name,
         pg_get_viewdef(c.oid, true) AS view_definition
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'v'
  ORDER BY c.relname;
`);
for (const v of views.rows) {
  out(`CREATE OR REPLACE VIEW public."${v.table_name}" AS`);
  out(v.view_definition);
  out(';');
  out('');
}

await client.end();

const output = lines.join('\n');
const outputPath = resolve(repoRoot, 'full_schema_dump.sql');
writeFileSync(outputPath, output, 'utf-8');

console.log(`\n✅ Schema dump written to: ${outputPath}`);
console.log(`   Lines: ${lines.length}`);
console.log(`   Tables: ${tables.rows.length}`);
console.log(`   Enums: ${enums.rows.length}`);
console.log(`   Policies: ${policies.rows.length}`);
console.log(`   Functions: ${funcs.rows.length}`);
console.log(`   Views: ${views.rows.length}`);
