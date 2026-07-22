import assert from 'node:assert/strict';
import test from 'node:test';

import { compareCatalogs } from './compare-catalog.mjs';

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
