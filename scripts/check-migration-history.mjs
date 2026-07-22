#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const POLICY_PATH = path.join(REPO_ROOT, 'supabase', 'migration-policy.json');
const MIGRATION_NAME = /^(\d{14})_([a-z0-9][a-z0-9_-]*)\.sql$/u;

function normalizeIdentifier(value) {
  return value
    .trim()
    .split('.')
    .map((part) => part.trim().replace(/^"|"$/gu, '').replaceAll('""', '"').toLowerCase())
    .join('.');
}

function normalizeSql(value) {
  return value.replace(/\s+/gu, ' ').trim().toLowerCase();
}

function stripLeadingComments(value) {
  let sql = value.trimStart().replace(/^\uFEFF/u, '');
  while (sql.startsWith('--') || sql.startsWith('/*')) {
    if (sql.startsWith('--')) {
      const newline = sql.indexOf('\n');
      sql = newline < 0 ? '' : sql.slice(newline + 1).trimStart();
      continue;
    }
    const end = sql.indexOf('*/', 2);
    if (end < 0) return sql;
    sql = sql.slice(end + 2).trimStart();
  }
  return sql;
}

export function splitSqlStatements(sql) {
  const statements = [];
  let start = 0;
  let index = 0;
  let quote = null;
  let dollarTag = null;
  let blockDepth = 0;
  let lineComment = false;

  while (index < sql.length) {
    const current = sql[index];
    const following = sql[index + 1] ?? '';

    if (lineComment) {
      if (current === '\n') lineComment = false;
      index += 1;
      continue;
    }
    if (blockDepth > 0) {
      if (current === '/' && following === '*') {
        blockDepth += 1;
        index += 2;
      } else if (current === '*' && following === '/') {
        blockDepth -= 1;
        index += 2;
      } else {
        index += 1;
      }
      continue;
    }
    if (dollarTag) {
      if (sql.startsWith(dollarTag, index)) {
        index += dollarTag.length;
        dollarTag = null;
      } else {
        index += 1;
      }
      continue;
    }
    if (quote) {
      if (current === quote) {
        if (following === quote) {
          index += 2;
          continue;
        }
        quote = null;
      }
      index += 1;
      continue;
    }

    if (current === '-' && following === '-') {
      lineComment = true;
      index += 2;
    } else if (current === '/' && following === '*') {
      blockDepth = 1;
      index += 2;
    } else if (current === "'" || current === '"') {
      quote = current;
      index += 1;
    } else if (current === '$') {
      const match = sql.slice(index).match(/^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/u);
      if (match) {
        dollarTag = match[0];
        index += dollarTag.length;
      } else {
        index += 1;
      }
    } else if (current === ';') {
      const statement = sql.slice(start, index + 1).trim();
      if (statement) statements.push(statement);
      start = index + 1;
      index += 1;
    } else {
      index += 1;
    }
  }

  const trailing = sql.slice(start).trim();
  if (trailing) statements.push(trailing);
  return statements;
}

function findMatchingParenthesis(sql, openingIndex) {
  let depth = 0;
  let quote = null;
  for (let index = openingIndex; index < sql.length; index += 1) {
    const current = sql[index];
    const following = sql[index + 1] ?? '';
    if (quote) {
      if (current === quote) {
        if (following === quote) {
          index += 1;
        } else {
          quote = null;
        }
      }
      continue;
    }
    if (current === "'" || current === '"') {
      quote = current;
    } else if (current === '(') {
      depth += 1;
    } else if (current === ')') {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}

function functionIdentity(statement) {
  const match = statement.match(
    /^CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+((?:"[^"]+"|[A-Za-z_][\w$]*)(?:\s*\.\s*(?:"[^"]+"|[A-Za-z_][\w$]*))?)\s*\(/iu,
  );
  if (!match) return null;
  const opening = statement.indexOf('(', match.index + match[0].length - 1);
  const closing = findMatchingParenthesis(statement, opening);
  if (closing < 0) return null;
  const args = statement
    .slice(opening + 1, closing)
    .replace(/\bDEFAULT\b[\s\S]*?(?=,|$)/giu, '')
    .replace(/\s*=\s*[^,]+(?=,|$)/gu, '');
  return `function:${normalizeIdentifier(match[1])}(${normalizeSql(args)})`;
}

export function extractDefinedObjects(sql) {
  const definitions = [];
  for (const rawStatement of splitSqlStatements(sql)) {
    const statement = stripLeadingComments(rawStatement);
    if (!statement) continue;

    const functionKey = functionIdentity(statement);
    if (functionKey) {
      definitions.push(functionKey);
      continue;
    }

    const relation = statement.match(
      /^CREATE\s+(?:OR\s+REPLACE\s+)?(MATERIALIZED\s+VIEW|VIEW|TABLE)\s+(?:IF\s+NOT\s+EXISTS\s+)?((?:"[^"]+"|[A-Za-z_][\w$]*)(?:\s*\.\s*(?:"[^"]+"|[A-Za-z_][\w$]*))?)/iu,
    );
    if (relation) {
      definitions.push(`${normalizeSql(relation[1])}:${normalizeIdentifier(relation[2])}`);
      continue;
    }

    const policy = statement.match(
      /^CREATE\s+POLICY\s+("(?:[^"]|"")+"|[A-Za-z_][\w$]*)\s+ON\s+((?:"[^"]+"|[A-Za-z_][\w$]*)(?:\s*\.\s*(?:"[^"]+"|[A-Za-z_][\w$]*))?)/iu,
    );
    if (policy) {
      definitions.push(`policy:${normalizeIdentifier(policy[2])}:${normalizeIdentifier(policy[1])}`);
      continue;
    }

    const trigger = statement.match(
      /^CREATE\s+(?:OR\s+REPLACE\s+)?TRIGGER\s+("(?:[^"]|"")+"|[A-Za-z_][\w$]*)[\s\S]*?\sON\s+((?:"[^"]+"|[A-Za-z_][\w$]*)(?:\s*\.\s*(?:"[^"]+"|[A-Za-z_][\w$]*))?)/iu,
    );
    if (trigger) {
      definitions.push(`trigger:${normalizeIdentifier(trigger[2])}:${normalizeIdentifier(trigger[1])}`);
      continue;
    }

    const index = statement.match(
      /^CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:CONCURRENTLY\s+)?(?:IF\s+NOT\s+EXISTS\s+)?((?:"[^"]+"|[A-Za-z_][\w$]*)(?:\s*\.\s*(?:"[^"]+"|[A-Za-z_][\w$]*))?)/iu,
    );
    if (index) definitions.push(`index:${normalizeIdentifier(index[1])}`);
  }
  return definitions;
}

export function findDuplicateDefinitions(files) {
  const owners = new Map();
  for (const file of files) {
    for (const object of extractDefinedObjects(file.sql)) {
      const occurrences = owners.get(object) ?? [];
      occurrences.push(file.name);
      owners.set(object, occurrences);
    }
  }
  return [...owners.entries()]
    .filter(([, occurrences]) => occurrences.length > 1)
    .map(([object, occurrences]) => ({ object, occurrences }));
}

function git(args) {
  return execFileSync('git', args, { cwd: REPO_ROOT, encoding: 'utf8' }).trim();
}

function isValidGitRef(value) {
  if (!value || /^0+$/u.test(value)) return false;
  try {
    git(['rev-parse', '--verify', `${value}^{commit}`]);
    return true;
  } catch {
    return false;
  }
}

function parseNameStatus(output) {
  if (!output) return [];
  return output.split(/\r?\n/u).flatMap((line) => {
    const parts = line.split('\t');
    const status = parts[0];
    if (status.startsWith('R') || status.startsWith('C')) {
      return [{ status: status[0], oldPath: parts[1], path: parts[2] }];
    }
    return [{ status: status[0], path: parts[1] }];
  });
}

function changedMigrations(base) {
  const migrationsPath = 'supabase/migrations';
  if (isValidGitRef(base)) {
    return parseNameStatus(git(['diff', '--name-status', `${base}...HEAD`, '--', migrationsPath]));
  }

  const tracked = parseNameStatus(git(['diff', '--name-status', 'HEAD', '--', migrationsPath]));
  const untracked = git(['ls-files', '--others', '--exclude-standard', '--', migrationsPath]);
  const additions = untracked
    ? untracked.split(/\r?\n/u).map((filePath) => ({ status: 'A', path: filePath }))
    : [];
  return [...tracked, ...additions];
}

function migrationVersion(filePath) {
  const match = path.basename(filePath).match(MIGRATION_NAME);
  return match?.[1] ?? null;
}

function validateAllVersions(migrationsDirectory) {
  const errors = [];
  const versions = new Map();
  for (const file of readdirSync(migrationsDirectory).filter((name) => name.endsWith('.sql'))) {
    const version = migrationVersion(file);
    if (!version) {
      errors.push(`Invalid migration filename: ${file}`);
      continue;
    }
    const owner = versions.get(version);
    if (owner) errors.push(`Duplicate migration version ${version}: ${owner}, ${file}`);
    versions.set(version, file);
  }
  return errors;
}

export function evaluateChanges({ changes, immutableThrough, newFiles }) {
  const errors = [];
  for (const change of changes) {
    for (const candidate of [change.oldPath, change.path].filter(Boolean)) {
      const version = migrationVersion(candidate);
      if (!version) continue;
      const mutatesExisting = change.status !== 'A';
      const backdatedAddition = change.status === 'A' && version <= immutableThrough;
      if (mutatesExisting && version <= immutableThrough) {
        errors.push(`Applied migration is immutable (${change.status}): ${candidate}`);
      } else if (backdatedAddition) {
        errors.push(`New migration must be newer than ${immutableThrough}: ${candidate}`);
      }
    }
  }

  for (const duplicate of findDuplicateDefinitions(newFiles)) {
    errors.push(
      `Repeated SQL object ${duplicate.object} in new migrations: ${duplicate.occurrences.join(', ')}`,
    );
  }
  return errors;
}

function main() {
  if (!existsSync(POLICY_PATH)) throw new Error('Missing supabase/migration-policy.json');
  const policy = JSON.parse(readFileSync(POLICY_PATH, 'utf8'));
  const migrationsDirectory = path.join(REPO_ROOT, policy.migrationsDirectory);
  const baseIndex = process.argv.indexOf('--base');
  const base = baseIndex >= 0 ? process.argv[baseIndex + 1] : '';
  const changes = changedMigrations(base);
  const addedPaths = [...new Set(changes.filter((item) => item.status === 'A').map((item) => item.path))];
  const newFiles = addedPaths
    .filter((filePath) => existsSync(path.join(REPO_ROOT, filePath)))
    .map((filePath) => ({
      name: filePath,
      sql: readFileSync(path.join(REPO_ROOT, filePath), 'utf8'),
    }));
  const errors = [
    ...validateAllVersions(migrationsDirectory),
    ...evaluateChanges({ changes, immutableThrough: policy.immutableThrough, newFiles }),
  ];

  if (errors.length > 0) {
    process.stderr.write(`Migration history check failed:\n- ${errors.join('\n- ')}\n`);
    process.exitCode = 1;
    return;
  }
  process.stdout.write(
    `Migration history check passed: ${newFiles.length} new migration(s), immutable through ${policy.immutableThrough}.\n`,
  );
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
