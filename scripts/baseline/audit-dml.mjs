#!/usr/bin/env node

import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { splitSqlStatements } from '../check-migration-history.mjs';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const MIGRATIONS_DIR = path.join(REPO_ROOT, 'supabase', 'migrations');
const DML_PATTERN = /(?:^|[;\r\n]|\bBEGIN\b|\bTHEN\b|\bELSE\b)\s*(INSERT\s+INTO|UPDATE|DELETE\s+FROM|COPY)\s+(?:ONLY\s+)?([A-Za-z0-9_."]+)/giu;
const SERVICE_CALL_PATTERN = /\b(?:SELECT|PERFORM)\s+((?:cron\.schedule)|(?:vault\.[A-Za-z0-9_]+))\s*\(/giu;
const CRITICAL_TARGET = /(?:storage\.buckets|cron\.|vault\.|public\.(?:roles|salary_constants|system_settings|app_permissions|role_permissions))/iu;

function stripComments(statement) {
  return statement
    .replace(/\/\*[\s\S]*?\*\//gu, ' ')
    .replace(/--[^\r\n]*/gu, ' ')
    .trim();
}

export function classifyDml(statement) {
  const sql = stripComments(statement);
  if (/^CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\b/iu.test(sql)) return [];
  const dataChanges = [...sql.matchAll(DML_PATTERN)].map((match) => {
    const operation = match[1].replace(/\s+/gu, ' ').toUpperCase();
    const target = match[2]?.replaceAll('"', '') || '(expression)';
    return {
      operation,
      target,
      priority: CRITICAL_TARGET.test(`${operation} ${target}`) ? 'required-review' : 'review',
    };
  });
  const serviceCalls = [...sql.matchAll(SERVICE_CALL_PATTERN)].map((match) => ({
    operation: 'CALL',
    target: match[1],
    priority: 'required-review',
  }));
  return [...dataChanges, ...serviceCalls];
}

function buildInventory() {
  const entries = [];
  const migrationFiles = readdirSync(MIGRATIONS_DIR).filter((name) => name.endsWith('.sql')).sort();
  for (const fileName of migrationFiles) {
    const sql = readFileSync(path.join(MIGRATIONS_DIR, fileName), 'utf8');
    for (const statement of splitSqlStatements(sql)) {
      for (const match of classifyDml(statement)) {
        entries.push({
          file: fileName,
          ...match,
          excerpt: stripComments(statement).replace(/\s+/gu, ' ').slice(0, 240),
        });
      }
    }
  }
  return {
    generatedAt: new Date().toISOString(),
    migrationCount: migrationFiles.length,
    dmlStatementCount: entries.length,
    requiredReviewCount: entries.filter((entry) => entry.priority === 'required-review').length,
    entries,
  };
}

function writeReports(outputDirectory, inventory) {
  mkdirSync(outputDirectory, { recursive: true });
  writeFileSync(path.join(outputDirectory, 'dml-inventory.json'), `${JSON.stringify(inventory, null, 2)}\n`, 'utf8');
  const rows = inventory.entries.map((entry) =>
    `| \`${entry.file}\` | ${entry.operation} | \`${entry.target}\` | ${entry.priority} |`,
  );
  const markdown = [
    '# Baseline DML inventory',
    '',
    `- Migrations scanned: ${inventory.migrationCount}`,
    `- DML operations found: ${inventory.dmlStatementCount}`,
    `- Required manual review: ${inventory.requiredReviewCount}`,
    '',
    'Supabase schema squash omits these operations. Required-review entries must be restored in a separate idempotent seed migration before the baseline can be approved.',
    '',
    '| Migration | Operation | Target | Priority |',
    '|---|---|---|---|',
    ...rows,
    '',
  ].join('\n');
  writeFileSync(path.join(outputDirectory, 'dml-inventory.md'), markdown, 'utf8');
}

function main() {
  const outputIndex = process.argv.indexOf('--output-dir');
  const outputDirectory = outputIndex >= 0
    ? path.resolve(process.argv[outputIndex + 1])
    : path.join(REPO_ROOT, 'supabase', 'migrations_consolidated_draft');
  const inventory = buildInventory();
  writeReports(outputDirectory, inventory);
  process.stdout.write(
    `Baseline DML audit: ${inventory.dmlStatementCount} operations, ${inventory.requiredReviewCount} require manual review.\n`,
  );
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
