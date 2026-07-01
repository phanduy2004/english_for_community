/**
 * Migration runner — ghi nhận đã chạy vào collection `migrations`.
 *
 * Usage:
 *   node migrations/runner.js --dry
 *   node migrations/runner.js
 *   node migrations/runner.js --only 003-unset-duplicate-exam-snapshot
 *
 * Prod: backup Atlas snapshot / mongodump trước khi chạy thật.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import mongoose from 'mongoose';
import { getMongoUri, getMongoUriForLog, getMongoDbName } from '../src/lib/mongoUri.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const dry = argv.includes('--dry');
  const force = argv.includes('--force');
  const onlyIdx = argv.indexOf('--only');
  const only = onlyIdx >= 0 ? argv[onlyIdx + 1] : null;
  return { dry, force, only };
}

export async function runMigrations(options = {}) {
  const dry = options.dry ?? false;
  const force = options.force ?? false;
  const only = options.only ?? null;

  const uri = getMongoUri();
  if (!uri) {
    throw new Error('MONGO_URI is not set. Configure english_for_community_backend/.env first.');
  }

  console.log(`[migrate] connect ${getMongoUriForLog(uri)} db=${getMongoDbName()} dry=${dry} force=${force}`);
  await mongoose.connect(uri, { dbName: getMongoDbName() });

  const db = mongoose.connection.db;
  const ledger = db.collection('migrations');
  await ledger.createIndex({ id: 1 }, { unique: true });

  const files = fs
    .readdirSync(__dirname)
    .filter((f) => /^\d{3}-.+\.js$/.test(f))
    .sort();

  const summary = [];

  for (const file of files) {
    const mod = await import(pathToFileURL(path.join(__dirname, file)).href);
    const migration = mod.default ?? mod;
    const id = migration.id ?? file.replace(/\.js$/, '');

    if (only && id !== only) continue;

    const applied = await ledger.findOne({ id });
    if (applied && !force) {
      console.log(`[migrate] skip ${id} (applied ${applied.appliedAt?.toISOString?.() ?? applied.appliedAt})`);
      summary.push({ id, status: 'skipped' });
      continue;
    }

    console.log(`[migrate] run ${id} ...`);
    const stats = await migration.up({ dry, mongoose, db, force });
    console.log(`[migrate] stats ${id}:`, stats);

    if (!dry) {
      await ledger.updateOne(
        { id },
        {
          $set: {
            id,
            file,
            appliedAt: new Date(),
            stats,
          },
        },
        { upsert: true }
      );
    }

    summary.push({ id, status: dry ? 'dry-run' : 'applied', stats });
  }

  await mongoose.disconnect();
  return summary;
}

const isMain =
  process.argv[1] &&
  pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url;

if (isMain) {
  const { dry, force, only } = parseArgs(process.argv.slice(2));
  runMigrations({ dry, force, only })
    .then((s) => {
      console.log('[migrate] done', s);
      process.exit(0);
    })
    .catch((err) => {
      console.error('[migrate] failed', err);
      process.exit(1);
    });
}
