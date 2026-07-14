import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { gzipSync } from 'node:zlib';

const projectRoot = path.resolve(import.meta.dirname, '..');
const distDirectory = path.join(projectRoot, 'frontend', 'dist');
const assetsDirectory = path.join(distDirectory, 'assets');

const budgets = {
  initialGzipBytes: 300 * 1024,
  largestChunkGzipBytes: 180 * 1024,
  totalJavaScriptGzipBytes: 1400 * 1024,
};

const formatKilobytes = (bytes) => `${(bytes / 1024).toFixed(1)} KB`;

async function gzipSize(filePath) {
  return gzipSync(await readFile(filePath)).length;
}

async function collectJavaScriptAssets() {
  const names = (await readdir(assetsDirectory)).filter((name) => name.endsWith('.js'));
  return Promise.all(names.map(async (name) => ({
    name,
    gzipBytes: await gzipSize(path.join(assetsDirectory, name)),
  })));
}

function initialAssetNames(html) {
  return [...html.matchAll(/(?:src|href)="\/assets\/([^"?]+\.js)(?:\?[^"#]*)?"/g)]
    .map((match) => match[1]);
}

function assertBudget(label, actual, budget) {
  if (actual <= budget) return null;
  return `${label}: ${formatKilobytes(actual)} exceeds ${formatKilobytes(budget)}`;
}

const html = await readFile(path.join(distDirectory, 'index.html'), 'utf8');
const assets = await collectJavaScriptAssets();
const sizesByName = new Map(assets.map((asset) => [asset.name, asset.gzipBytes]));
const initialAssets = initialAssetNames(html);
const missingInitialAssets = initialAssets.filter((name) => !sizesByName.has(name));

if (missingInitialAssets.length > 0) {
  throw new Error(`Initial bundle references missing assets: ${missingInitialAssets.join(', ')}`);
}

const initialGzipBytes = initialAssets.reduce((total, name) => total + sizesByName.get(name), 0);
const totalJavaScriptGzipBytes = assets.reduce((total, asset) => total + asset.gzipBytes, 0);
const largestChunk = assets.reduce(
  (largest, asset) => asset.gzipBytes > largest.gzipBytes ? asset : largest,
  { name: 'none', gzipBytes: 0 },
);

console.log('Frontend bundle budget (gzip)');
console.log(`  Initial JavaScript: ${formatKilobytes(initialGzipBytes)} / ${formatKilobytes(budgets.initialGzipBytes)}`);
console.log(`  Largest chunk: ${largestChunk.name} at ${formatKilobytes(largestChunk.gzipBytes)} / ${formatKilobytes(budgets.largestChunkGzipBytes)}`);
console.log(`  Total JavaScript: ${formatKilobytes(totalJavaScriptGzipBytes)} / ${formatKilobytes(budgets.totalJavaScriptGzipBytes)}`);

const failures = [
  assertBudget('Initial JavaScript', initialGzipBytes, budgets.initialGzipBytes),
  assertBudget(`Largest chunk (${largestChunk.name})`, largestChunk.gzipBytes, budgets.largestChunkGzipBytes),
  assertBudget('Total JavaScript', totalJavaScriptGzipBytes, budgets.totalJavaScriptGzipBytes),
].filter(Boolean);

if (failures.length > 0) {
  console.error('\nBundle budget failed:');
  failures.forEach((failure) => console.error(`  - ${failure}`));
  process.exitCode = 1;
}
