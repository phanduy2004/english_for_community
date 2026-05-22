/**
 * Copy CMS skill content from one MongoDB to another (e.g. local → Atlas).
 *
 * Usage:
 *   1. Set in .env (or one-off env vars):
 *      MONGO_URI_SOURCE=mongodb://localhost:27017/english_community
 *      MONGO_URI_TARGET=mongodb+srv://.../english_community?...
 *   2. npm run migrate:cms
 *
 * Only copies admin/CMS collections — not users, attempts, exams, classrooms.
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

dotenv.config();

const SOURCE_URI =
  process.env.MONGO_URI_SOURCE ||
  process.env.MONGODB_URI_SOURCE ||
  'mongodb://127.0.0.1:27017/english_community';

const TARGET_URI =
  process.env.MONGO_URI_TARGET ||
  process.env.MONGO_URI ||
  process.env.MONGODB_URI;

/** Mongoose collection names (lowercase plural unless overridden in model). */
const CMS_COLLECTIONS = [
  'listenings',
  'readings',
  'speakingsets',
  'listeningcomprehensions',
  'writing_topics',
  'writing_topic_versions',
  'cuecomments',
];

const BATCH = 200;

async function copyCollection(sourceDb, targetDb, name) {
  const src = sourceDb.collection(name);
  const tgt = targetDb.collection(name);

  const total = await src.countDocuments();
  if (total === 0) {
    console.log(`  ⏭ ${name}: empty on source — skip`);
    return { name, read: 0, upserted: 0 };
  }

  let read = 0;
  let upserted = 0;
  const cursor = src.find({}).batchSize(BATCH);

  let batch = [];
  for await (const doc of cursor) {
    batch.push(doc);
    read += 1;
    if (batch.length >= BATCH) {
      upserted += await flushBatch(tgt, batch);
      batch = [];
    }
  }
  if (batch.length) upserted += await flushBatch(tgt, batch);

  console.log(`  ✅ ${name}: ${read} doc(s) → ${upserted} upserted`);
  return { name, read, upserted };
}

async function flushBatch(targetCol, docs) {
  if (!docs.length) return 0;
  const ops = docs.map((doc) => ({
    replaceOne: {
      filter: { _id: doc._id },
      replacement: doc,
      upsert: true,
    },
  }));
  const r = await targetCol.bulkWrite(ops, { ordered: false });
  return (r.upsertedCount ?? 0) + (r.modifiedCount ?? 0) + (r.matchedCount ?? 0);
}

async function run() {
  if (!TARGET_URI) {
    console.error('❌ Set MONGO_URI_TARGET (or MONGO_URI) = Atlas DB in .env');
    process.exit(1);
  }

  if (SOURCE_URI === TARGET_URI) {
    console.error('❌ SOURCE and TARGET must be different URIs');
    process.exit(1);
  }

  console.log('📤 Source:', SOURCE_URI.replace(/:[^:@/]+@/, ':****@'));
  console.log('📥 Target:', TARGET_URI.replace(/:[^:@/]+@/, ':****@'));
  console.log('📦 Collections:', CMS_COLLECTIONS.join(', '), '\n');

  const sourceConn = mongoose.createConnection(SOURCE_URI);
  const targetConn = mongoose.createConnection(TARGET_URI);

  await Promise.all([sourceConn.asPromise(), targetConn.asPromise()]);
  console.log('🔌 Connected to source & target\n');

  const sourceDb = sourceConn.db;
  const targetDb = targetConn.db;

  const summary = [];
  for (const name of CMS_COLLECTIONS) {
    try {
      const exists = await sourceDb.listCollections({ name }).toArray();
      if (!exists.length) {
        console.log(`  ⏭ ${name}: collection not on source — skip`);
        continue;
      }
      summary.push(await copyCollection(sourceDb, targetDb, name));
    } catch (e) {
      console.error(`  ❌ ${name}:`, e.message);
    }
  }

  console.log('\n========== MIGRATE CMS SUMMARY ==========');
  for (const row of summary) {
    console.log(`  ${row.name}: ${row.read} read, ${row.upserted} upserted`);
  }
  console.log('==========================================\n');
  console.log('Re-run seed:teacher-hoangdong if exams need fresh CMS links.');

  await sourceConn.close();
  await targetConn.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ migrateCmsContent failed:', e);
  process.exit(1);
});
