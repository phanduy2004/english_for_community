/**
 * D4 audit — parity + storage savings estimate.
 * node scripts/auditD4.js
 */
import mongoose from 'mongoose';
import { getMongoUri, getMongoUriForLog } from '../src/lib/mongoUri.js';
import {
  loadAssignmentSnapshot,
  snapshotsDeepEqual,
  stableSnapshotString,
} from '../src/services/examSnapshotStore.js';

async function main() {
  await mongoose.connect(getMongoUri());
  const db = mongoose.connection.db;
  const attempts = db.collection('examattempts');
  const assignments = db.collection('examassignments');

  const assignmentWithSnap = await assignments.countDocuments({
    examSnapshot: { $exists: true, $ne: null },
  });
  const totalAssignments = await assignments.countDocuments({});

  let attemptBytes = 0;
  let parityOk = 0;
  let parityFail = 0;
  const failSamples = [];

  const cursor = attempts.find({ examSnapshot: { $exists: true } }).batchSize(500);
  while (await cursor.hasNext()) {
    const att = await cursor.next();
    attemptBytes += Buffer.byteLength(JSON.stringify(att.examSnapshot ?? {}), 'utf8');
    const fromAssignment = await loadAssignmentSnapshot(att.assignmentId);
    if (!fromAssignment) continue;
    if (snapshotsDeepEqual(fromAssignment, att.examSnapshot)) {
      parityOk += 1;
    } else {
      parityFail += 1;
      if (failSamples.length < 10) {
        failSamples.push({
          attemptId: String(att._id),
          assignmentId: String(att.assignmentId),
        });
      }
    }
  }

  const frozenAssignments = await assignments
    .find({ examSnapshot: { $exists: true, $ne: null } })
    .project({ examSnapshot: 1 })
    .toArray();
  let assignmentBytes = 0;
  for (const a of frozenAssignments) {
    assignmentBytes += Buffer.byteLength(stableSnapshotString(a.examSnapshot), 'utf8');
  }

  const totalAttempts = await attempts.countDocuments({ examSnapshot: { $exists: true } });
  const duplicateBytesEstimate = Math.max(0, attemptBytes - assignmentBytes);

  const report = {
    at: new Date().toISOString(),
    db: getMongoUriForLog(),
    assignmentsFrozen: assignmentWithSnap,
    assignmentsTotal: totalAssignments,
    attemptsWithSnapshot: totalAttempts,
    attemptSnapshotBytes: attemptBytes,
    assignmentSnapshotBytes: assignmentBytes,
    duplicateBytesEstimate,
    parityOk,
    parityFail,
    failSamples,
  };

  console.log(JSON.stringify(report, null, 2));
  await mongoose.disconnect();
  process.exit(parityFail > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
