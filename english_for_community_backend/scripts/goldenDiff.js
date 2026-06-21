/**
 * Diff hai file golden JSON (T2). Bỏ qua capturedAt / accessToken.
 *
 * Usage: node scripts/goldenDiff.js migrations/golden/baseline.json migrations/golden/after-d1.json
 */
import fs from 'fs';

const [aPath, bPath] = process.argv.slice(2);
if (!aPath || !bPath) {
  console.error('Usage: node scripts/goldenDiff.js <before.json> <after.json>');
  process.exit(1);
}

const IGNORE_KEYS = new Set(['capturedAt', 'accessToken', 'refreshToken']);

function stripVolatile(obj, path = '') {
  if (obj == null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map((v, i) => stripVolatile(v, `${path}[${i}]`));
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (IGNORE_KEYS.has(k)) continue;
    out[k] = stripVolatile(v, path ? `${path}.${k}` : k);
  }
  return out;
}

function diff(a, b, p = '') {
  const changes = [];
  if (typeof a !== typeof b) {
    changes.push({ path: p || '(root)', type: 'type', a: typeof a, b: typeof b });
    return changes;
  }
  if (a == null || b == null || typeof a !== 'object') {
    if (JSON.stringify(a) !== JSON.stringify(b)) {
      changes.push({ path: p || '(root)', type: 'value', a, b });
    }
    return changes;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) changes.push({ path: p, type: 'arrayLen', a: a.length, b: b.length });
    const n = Math.max(a.length, b.length);
    for (let i = 0; i < n; i++) {
      changes.push(...diff(a[i], b[i], `${p}[${i}]`));
    }
    return changes;
  }
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    const hasA = Object.prototype.hasOwnProperty.call(a, k);
    const hasB = Object.prototype.hasOwnProperty.call(b, k);
    const np = p ? `${p}.${k}` : k;
    if (!hasA) changes.push({ path: np, type: 'added', b: b[k] });
    else if (!hasB) changes.push({ path: np, type: 'removed', a: a[k] });
    else changes.push(...diff(a[k], b[k], np));
  }
  return changes;
}

const before = stripVolatile(JSON.parse(fs.readFileSync(aPath, 'utf8')));
const after = stripVolatile(JSON.parse(fs.readFileSync(bPath, 'utf8')));
const changes = diff(before, after);

const addedIdOnly = changes.filter(
  (c) => c.type === 'added' && (c.path.endsWith('.id') || c.path.endsWith('.attemptId'))
);
const other = changes.filter(
  (c) => !(c.type === 'added' && (c.path.endsWith('.id') || c.path.endsWith('.attemptId')))
);

console.log(JSON.stringify({ total: changes.length, addedIdFields: addedIdOnly.length, otherChanges: other.slice(0, 50) }, null, 2));
process.exit(other.length > 0 ? 1 : 0);
