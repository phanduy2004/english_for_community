/**
 * Deep-diff examSnapshots for one assignment (debug D4 discovery).
 * node scripts/diffAssignmentSnapshots.js <assignmentId>
 */
import mongoose from 'mongoose';
import { getMongoUri } from '../src/lib/mongoUri.js';

const assignmentId = process.argv[2];
if (!assignmentId) {
  console.error('Usage: node scripts/diffAssignmentSnapshots.js <assignmentId>');
  process.exit(1);
}

function diffKeys(a, b, path = '') {
  const out = [];
  if (typeof a !== typeof b) {
    out.push({ path, a: typeof a, b: typeof b });
    return out;
  }
  if (a == null || b == null || typeof a !== 'object') {
    if (JSON.stringify(a) !== JSON.stringify(b)) out.push({ path, a, b });
    return out;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) out.push({ path, aLen: a.length, bLen: b.length });
    const n = Math.max(a.length, b.length);
    for (let i = 0; i < n; i++) out.push(...diffKeys(a[i], b[i], `${path}[${i}]`));
    return out;
  }
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    const p = path ? `${path}.${k}` : k;
    if (!(k in a)) out.push({ path: p, missing: 'a', b: b[k] });
    else if (!(k in b)) out.push({ path: p, missing: 'b', a: a[k] });
    else out.push(...diffKeys(a[k], b[k], p));
  }
  return out;
}

async function main() {
  await mongoose.connect(getMongoUri());
  const oid = new mongoose.Types.ObjectId(assignmentId);
  const attempts = await mongoose.connection.db
    .collection('examattempts')
    .find({ assignmentId: oid })
    .project({ examSnapshot: 1, status: 1, userId: 1, createdAt: 1, updatedAt: 1 })
    .toArray();

  console.log('attempts:', attempts.length);
  const groups = new Map();
  for (const a of attempts) {
    const key = JSON.stringify(a.examSnapshot?.sections?.length) + '|' + JSON.stringify(a.examSnapshot?.settings?.contentVersion ?? a.examSnapshot?.contentVersion);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(a);
  }

  const snaps = [...new Set(attempts.map((a) => JSON.stringify(a.examSnapshot)))].map((s) => JSON.parse(s));
  if (snaps.length >= 2) {
    const d = diffKeys(snaps[0], snaps[1]);
    console.log('diff count:', d.length);
    console.log('first 40 diffs:', JSON.stringify(d.slice(0, 40), null, 2));
    console.log('snap0 sections:', snaps[0]?.sections?.length, 'bytes', Buffer.byteLength(JSON.stringify(snaps[0])));
    console.log('snap1 sections:', snaps[1]?.sections?.length, 'bytes', Buffer.byteLength(JSON.stringify(snaps[1])));
  }

  const outlier = attempts.find((a) => Buffer.byteLength(JSON.stringify(a.examSnapshot)) > 1100);
  const majority = attempts.find((a) => Buffer.byteLength(JSON.stringify(a.examSnapshot)) < 1100);
  if (outlier && majority) {
    console.log('\nOutlier attempt:', outlier._id, outlier.status, 'updatedAt', outlier.updatedAt);
    console.log('Majority sample:', majority._id, majority.status);
    const d2 = diffKeys(majority.examSnapshot, outlier.examSnapshot);
    console.log('outlier vs majority diffs (first 25):', JSON.stringify(d2.slice(0, 25), null, 2));
  }

  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
