import assert from 'node:assert/strict';
import test from 'node:test';

import {
  evaluateChanges,
  extractDefinedObjects,
  findDuplicateDefinitions,
  splitSqlStatements,
} from './check-migration-history.mjs';

test('keeps function bodies with semicolons in one statement', () => {
  const statements = splitSqlStatements(
    'CREATE FUNCTION public.f() RETURNS void AS $$ BEGIN PERFORM 1; END; $$ LANGUAGE plpgsql; SELECT 1;',
  );
  assert.equal(statements.length, 2);
});

test('extracts schema objects and overloaded function identities', () => {
  const objects = extractDefinedObjects(`
    CREATE OR REPLACE VIEW public.sample_view AS SELECT 1;
    CREATE FUNCTION public.sample(p_id uuid) RETURNS void LANGUAGE sql AS $$ SELECT; $$;
    CREATE FUNCTION public.sample(p_id text) RETURNS void LANGUAGE sql AS $$ SELECT; $$;
    CREATE POLICY "read sample" ON public.samples FOR SELECT USING (true);
    CREATE TRIGGER touch_sample BEFORE UPDATE ON public.samples
      FOR EACH ROW EXECUTE FUNCTION public.touch_row();
  `);

  assert.deepEqual(objects, [
    'view:public.sample_view',
    'function:public.sample(p_id uuid)',
    'function:public.sample(p_id text)',
    'policy:public.samples:read sample',
    'trigger:public.samples:touch_sample',
  ]);
});

test('finds repeated definitions across newly added migrations', () => {
  const duplicates = findDuplicateDefinitions([
    { name: 'one.sql', sql: 'CREATE OR REPLACE VIEW public.dashboard AS SELECT 1;' },
    { name: 'two.sql', sql: 'CREATE OR REPLACE VIEW public.dashboard AS SELECT 2;' },
  ]);

  assert.deepEqual(duplicates, [
    { object: 'view:public.dashboard', occurrences: ['one.sql', 'two.sql'] },
  ]);
});

test('blocks edits to applied history and backdated additions', () => {
  const errors = evaluateChanges({
    immutableThrough: '20260722000000',
    changes: [
      { status: 'M', path: 'supabase/migrations/20260721000000_old.sql' },
      { status: 'A', path: 'supabase/migrations/20260701000000_backdated.sql' },
    ],
    newFiles: [],
  });

  assert.equal(errors.length, 2);
  assert.match(errors[0], /immutable/u);
  assert.match(errors[1], /newer than/u);
});

test('allows one forward-only migration for one object', () => {
  const errors = evaluateChanges({
    immutableThrough: '20260722000000',
    changes: [{ status: 'A', path: 'supabase/migrations/20260723000000_dashboard.sql' }],
    newFiles: [
      {
        name: 'supabase/migrations/20260723000000_dashboard.sql',
        sql: 'CREATE OR REPLACE VIEW public.dashboard AS SELECT 1;',
      },
    ],
  });

  assert.deepEqual(errors, []);
});
