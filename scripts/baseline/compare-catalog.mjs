#!/usr/bin/env node

import { readFileSync, writeFileSync } from 'node:fs';
import process from 'node:process';

function readCatalog(filePath) {
  const raw = readFileSync(filePath, 'utf8').trim();
  const firstBrace = raw.indexOf('{');
  const lastBrace = raw.lastIndexOf('}');
  if (firstBrace < 0 || lastBrace < firstBrace) {
    throw new Error(`No JSON payload found in ${filePath}`);
  }
  const payload = JSON.parse(raw.slice(firstBrace, lastBrace + 1));
  const firstRow = Array.isArray(payload) ? payload[0] : payload.rows?.[0];
  const catalog = firstRow?.catalog ?? payload.catalog ?? (payload.data ? payload : null);
  if (!catalog) throw new Error(`No catalog row found in ${filePath}`);
  return catalog;
}

function collectDifferences(left, right, path = '$', differences = []) {
  if (differences.length >= 50) return differences;
  if (Object.is(left, right)) return differences;
  if (Array.isArray(left) && Array.isArray(right)) {
    if (left.length !== right.length) {
      differences.push(`${path}.length: ${left.length} != ${right.length}`);
    }
    const sharedLength = Math.min(left.length, right.length);
    for (let index = 0; index < sharedLength; index += 1) {
      collectDifferences(left[index], right[index], `${path}[${index}]`, differences);
      if (differences.length >= 50) break;
    }
    return differences;
  }
  if (left && right && typeof left === 'object' && typeof right === 'object') {
    const keys = [...new Set([...Object.keys(left), ...Object.keys(right)])].sort();
    for (const key of keys) {
      if (!(key in left)) differences.push(`${path}.${key}: missing from historical catalog`);
      else if (!(key in right)) differences.push(`${path}.${key}: missing from baseline catalog`);
      else collectDifferences(left[key], right[key], `${path}.${key}`, differences);
      if (differences.length >= 50) break;
    }
    return differences;
  }
  differences.push(`${path}: ${JSON.stringify(left)} != ${JSON.stringify(right)}`);
  return differences;
}

export function compareCatalogs(historicalCatalog, baselineCatalog) {
  const differences = collectDifferences(historicalCatalog, baselineCatalog);
  return { matches: differences.length === 0, differences };
}

export function compareCatalogFiles(historicalPath, baselinePath) {
  return compareCatalogs(readCatalog(historicalPath), readCatalog(baselinePath));
}

function main() {
  const [historicalPath, baselinePath, reportPath] = process.argv.slice(2);
  if (!historicalPath || !baselinePath || !reportPath) {
    throw new Error('Usage: compare-catalog.mjs <historical.json> <baseline.json> <report.json>');
  }
  const comparison = compareCatalogFiles(historicalPath, baselinePath);
  writeFileSync(reportPath, `${JSON.stringify(comparison, null, 2)}\n`, 'utf8');
  if (!comparison.matches) {
    process.stderr.write(`Baseline catalog mismatch:\n- ${comparison.differences.join('\n- ')}\n`);
    process.exitCode = 1;
    return;
  }
  process.stdout.write('Baseline catalog matches the full migration history.\n');
}

if (process.argv[1]?.endsWith('compare-catalog.mjs')) main();
