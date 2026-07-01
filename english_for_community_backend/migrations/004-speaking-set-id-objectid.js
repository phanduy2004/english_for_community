/**
 * D1 — SpeakingAttempt / SpeakingEnrollment: speakingSetId String → ObjectId.
 * Idempotent: chỉ convert document có speakingSetId kiểu string hợp lệ.
 */
import mongoose from 'mongoose';

export const id = '004-speaking-set-id-objectid';

async function convertCollection(col, dry) {
  let read = 0;
  let written = 0;
  let skipped = 0;

  const cursor = col.find({ speakingSetId: { $type: 'string' } }).batchSize(500);
  let batch = [];

  while (await cursor.hasNext()) {
    const doc = await cursor.next();
    read += 1;
    const raw = doc.speakingSetId;
    if (!mongoose.Types.ObjectId.isValid(String(raw))) {
      skipped += 1;
      continue;
    }
    const oid = new mongoose.Types.ObjectId(String(raw));
    if (dry) {
      written += 1;
      continue;
    }
    batch.push({
      updateOne: {
        filter: { _id: doc._id, speakingSetId: { $type: 'string' } },
        update: { $set: { speakingSetId: oid } },
      },
    });
    if (batch.length >= 500) {
      const r = await col.bulkWrite(batch, { ordered: false });
      written += r.modifiedCount ?? 0;
      batch = [];
    }
  }

  if (batch.length && !dry) {
    const r = await col.bulkWrite(batch, { ordered: false });
    written += r.modifiedCount ?? 0;
  }

  return { read, written, skipped };
}

export async function up({ dry, db }) {
  const attempts = await convertCollection(db.collection('speakingattempts'), dry);
  const enrollments = await convertCollection(db.collection('speakingenrollments'), dry);
  return { attempts, enrollments, dry };
}

export default { id, up };
