import assert from 'node:assert/strict';
import test from 'node:test';

import { classifyDml } from './audit-dml.mjs';

test('finds top-level reference-data inserts', () => {
  assert.deepEqual(classifyDml("INSERT INTO public.roles (title) VALUES ('admin');"), [
    { operation: 'INSERT INTO', target: 'public.roles', priority: 'required-review' },
  ]);
});

test('finds data changes inside migration DO blocks', () => {
  const matches = classifyDml('DO $$ BEGIN UPDATE public.employees SET status = \'active\'; END $$;');
  assert.equal(matches[0]?.operation, 'UPDATE');
  assert.equal(matches[0]?.target, 'public.employees');
});

test('ignores DML inside persisted function definitions', () => {
  const sql = 'CREATE OR REPLACE FUNCTION public.f() RETURNS void LANGUAGE sql AS $$ DELETE FROM public.roles; $$;';
  assert.deepEqual(classifyDml(sql), []);
});

test('ignores update keywords in policies and triggers', () => {
  assert.deepEqual(classifyDml('CREATE POLICY p ON public.roles FOR UPDATE USING (true);'), []);
  assert.deepEqual(
    classifyDml('CREATE TRIGGER t BEFORE INSERT OR UPDATE ON public.roles EXECUTE FUNCTION public.f();'),
    [],
  );
});

test('finds cron and vault calls omitted by schema squash', () => {
  assert.deepEqual(classifyDml("SELECT cron.schedule('daily', '0 0 * * *', $$SELECT 1$$);"), [
    { operation: 'CALL', target: 'cron.schedule', priority: 'required-review' },
  ]);
  assert.deepEqual(classifyDml("SELECT vault.create_secret('value', 'name');"), [
    { operation: 'CALL', target: 'vault.create_secret', priority: 'required-review' },
  ]);
});
