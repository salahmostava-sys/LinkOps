import assert from 'node:assert/strict';
import test from 'node:test';

import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

import { compareCatalogFiles, compareCatalogs } from './compare-catalog.mjs';

test('accepts identical catalog snapshots', () => {
  const catalog = { relations: [{ name: 'employees' }], policies: [] };
  assert.deepEqual(compareCatalogs(catalog, structuredClone(catalog)), {
    matches: true,
    differences: [],
  });
});

test('reports the first structural differences', () => {
  const comparison = compareCatalogs(
    { relations: [{ name: 'employees' }], policies: [] },
    { relations: [{ name: 'roles' }], policies: [{ name: 'read' }] },
  );
  assert.equal(comparison.matches, false);
  assert.match(comparison.differences.join('\n'), /relations\[0\]\.name/u);
  assert.match(comparison.differences.join('\n'), /policies\.length/u);
});

test('reads Supabase CLI and direct psql JSON snapshot formats', () => {
  const directory = mkdtempSync(path.join(tmpdir(), 'baseline-catalog-'));
  const cliPath = path.join(directory, 'cli.json');
  const psqlPath = path.join(directory, 'psql.json');

  try {
    writeFileSync(cliPath, JSON.stringify([{ catalog: { relations: ['employees'] } }]), 'utf8');
    writeFileSync(psqlPath, JSON.stringify({ data: [{ relation_name: 'employees' }] }), 'utf8');
    assert.deepEqual(compareCatalogFiles(cliPath, cliPath), { matches: true, differences: [] });
    assert.deepEqual(compareCatalogFiles(psqlPath, psqlPath), { matches: true, differences: [] });
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
