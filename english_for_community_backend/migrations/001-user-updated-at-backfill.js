/**
 * D1 — backfill User.updatedAt khi null (idempotent, batched).
 */
export const id = '001-user-updated-at-backfill';

export async function up({ dry, db }) {
  const col = db.collection('users');
  const filter = { $or: [{ updatedAt: null }, { updatedAt: { $exists: false } }] };

  let read = 0;
  let written = 0;
  let skipped = 0;

  const cursor = col.find(filter).batchSize(500);
  let batch = [];

  while (await cursor.hasNext()) {
    const doc = await cursor.next();
    read += 1;
    const fallback = doc.createdAt ?? new Date();
    if (dry) {
      written += 1;
      continue;
    }
    batch.push({
      updateOne: {
        filter: { _id: doc._id, $or: [{ updatedAt: null }, { updatedAt: { $exists: false } }] },
        update: { $set: { updatedAt: fallback } },
      },
    });
    if (batch.length >= 1000) {
      const r = await col.bulkWrite(batch, { ordered: false });
      written += r.modifiedCount ?? batch.length;
      batch = [];
    }
  }

  if (batch.length && !dry) {
    const r = await col.bulkWrite(batch, { ordered: false });
    written += r.modifiedCount ?? batch.length;
  }

  return { read, written, skipped, dry };
}

export default { id, up };
