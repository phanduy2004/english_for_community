/**
 * D4 contract — xoá examSnapshot trùng trên ExamAttempt / ExamSession
 * (canonical copy nằm trên ExamAssignment sau 002).
 *
 * Chỉ $unset khi assignment đã có examSnapshot frozen.
 */
export const id = '003-unset-duplicate-exam-snapshot';

const BATCH = 200;

async function flushBulk(col, ops, dry) {
  if (!ops.length || dry) return ops.length;
  await col.bulkWrite(ops, { ordered: false });
  return ops.length;
}

export async function up({ dry, db }) {
  const assignments = db.collection('examassignments');
  const attempts = db.collection('examattempts');
  const sessions = db.collection('examsessions');

  const frozenIds = await assignments
    .find({ examSnapshot: { $exists: true, $ne: null } })
    .project({ _id: 1 })
    .toArray();
  const frozenSet = new Set(frozenIds.map((a) => String(a._id)));

  let attemptUnset = 0;
  let attemptSkipped = 0;
  let sessionUnset = 0;
  let sessionSkipped = 0;
  let attemptOps = [];
  let sessionOps = [];

  const attemptCursor = attempts.find({ examSnapshot: { $exists: true } }).batchSize(BATCH);
  while (await attemptCursor.hasNext()) {
    const att = await attemptCursor.next();
    const aid = att.assignmentId ? String(att.assignmentId) : '';
    if (!aid || !frozenSet.has(aid)) {
      attemptSkipped += 1;
      continue;
    }
    if (dry) {
      attemptUnset += 1;
      continue;
    }
    attemptOps.push({
      updateOne: {
        filter: { _id: att._id },
        update: { $unset: { examSnapshot: '' } },
      },
    });
    if (attemptOps.length >= BATCH) {
      attemptUnset += await flushBulk(attempts, attemptOps, dry);
      attemptOps = [];
    }
  }
  if (attemptOps.length) {
    attemptUnset += await flushBulk(attempts, attemptOps, dry);
  }

  const sessionCursor = sessions.find({ examSnapshot: { $exists: true } }).batchSize(BATCH);
  while (await sessionCursor.hasNext()) {
    const sess = await sessionCursor.next();
    const aid = sess.assignmentId ? String(sess.assignmentId) : '';
    if (!aid || !frozenSet.has(aid)) {
      sessionSkipped += 1;
      continue;
    }
    if (dry) {
      sessionUnset += 1;
      continue;
    }
    sessionOps.push({
      updateOne: {
        filter: { _id: sess._id },
        update: { $unset: { examSnapshot: '' } },
      },
    });
    if (sessionOps.length >= BATCH) {
      sessionUnset += await flushBulk(sessions, sessionOps, dry);
      sessionOps = [];
    }
  }
  if (sessionOps.length) {
    sessionUnset += await flushBulk(sessions, sessionOps, dry);
  }

  return {
    dry,
    assignmentsFrozen: frozenSet.size,
    attemptUnset,
    attemptSkipped,
    sessionUnset,
    sessionSkipped,
  };
}

export default { id, up };
