/**
 * Pre-migration inventory — counts + byte estimate (không thay DB).
 * node scripts/backupPreMigration.js
 */
import mongoose from 'mongoose';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { getMongoUri, getMongoUriForLog } from '../src/lib/mongoUri.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const uri = getMongoUri();
  if (!uri) throw new Error('MONGO_URI not set');
  await mongoose.connect(uri);
  const db = mongoose.connection.db;

  const names = [
    'users',
    'examassignments',
    'examattempts',
    'examsessions',
    'exams',
    'migrations',
  ];
  const counts = {};
  for (const n of names) {
    try {
      counts[n] = await db.collection(n).countDocuments({});
    } catch {
      counts[n] = null;
    }
  }

  const ledger = await db
    .collection('migrations')
    .find({})
    .project({ _id: 1, appliedAt: 1 })
    .toArray();

  const report = {
    at: new Date().toISOString(),
    db: getMongoUriForLog(uri),
    counts,
    migrationsLedger: ledger,
    note: 'Atlas: tạo snapshot trong UI trước migrate prod. Local: mongodump --uri="$MONGO_URI" --out=./backup',
  };

  const outDir = path.join(__dirname, '..', 'migrations', 'artifacts');
  fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, `pre-migration-${Date.now()}.json`);
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  console.log('Wrote', outPath);
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
