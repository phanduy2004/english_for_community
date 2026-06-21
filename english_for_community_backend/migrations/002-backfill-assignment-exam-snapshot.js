/**
 * D4 backfill — freeze examSnapshot once per ExamAssignment from existing attempts/sessions.
 */
import {
  buildSnapshotFromExam,
  snapshotsDeepEqual,
  stableSnapshotString,
} from '../src/services/examSnapshotStore.js';
import { normalizeExamSnapshot } from '../src/services/examSkillSectionResources.js';

export const id = '002-backfill-assignment-exam-snapshot';

function pickCanonicalSnapshot(attempts, sessions) {
  const candidates = [];
  for (const a of attempts) {
    if (a.examSnapshot) candidates.push(a.examSnapshot);
  }
  for (const s of sessions) {
    if (s.examSnapshot) candidates.push(s.examSnapshot);
  }
  if (candidates.length === 0) return null;
  candidates.sort(
    (x, y) =>
      Buffer.byteLength(stableSnapshotString(y), 'utf8') -
      Buffer.byteLength(stableSnapshotString(x), 'utf8')
  );
  return normalizeExamSnapshot(candidates[0]);
}

export async function up({ dry, db }) {
  const assignments = db.collection('examassignments');
  const attempts = db.collection('examattempts');
  const sessions = db.collection('examsessions');
  const exams = db.collection('exams');

  let read = 0;
  let written = 0;
  let skipped = 0;
  let parityFail = 0;
  const paritySamples = [];

  const cursor = assignments.find({}).batchSize(200);

  while (await cursor.hasNext()) {
    const assignment = await cursor.next();
    read += 1;

    if (assignment.examSnapshot && typeof assignment.examSnapshot === 'object') {
      skipped += 1;
      continue;
    }

    const attRows = await attempts.find({ assignmentId: assignment._id }).toArray();
    const sessRows = await sessions.find({ assignmentId: assignment._id }).toArray();
    let canonical = pickCanonicalSnapshot(attRows, sessRows);

    if (!canonical && assignment.examId) {
      const exam = await exams.findOne({ _id: assignment.examId });
      if (exam) canonical = buildSnapshotFromExam(exam);
    }

    if (!canonical) {
      skipped += 1;
      continue;
    }

    if (!dry) {
      await assignments.updateOne(
        { _id: assignment._id, examSnapshot: { $in: [null, undefined] } },
        {
          $set: {
            examSnapshot: canonical,
            examSnapshotFrozenAt: assignment.examSnapshotFrozenAt || new Date(),
          },
        }
      );
    }
    written += 1;

    for (const att of attRows) {
      if (!att.examSnapshot) continue;
      if (!snapshotsDeepEqual(canonical, att.examSnapshot)) {
        parityFail += 1;
        if (paritySamples.length < 30) {
          paritySamples.push({
            assignmentId: String(assignment._id),
            attemptId: String(att._id),
            canonicalBytes: Buffer.byteLength(stableSnapshotString(canonical), 'utf8'),
            attemptBytes: Buffer.byteLength(stableSnapshotString(att.examSnapshot), 'utf8'),
          });
        }
      }
    }
  }

  const stats = { read, written, skipped, parityFail, paritySamples, dry };
  if (parityFail > 0) {
    console.warn('[002] parity mismatches (heal drift, not shuffle):', parityFail);
  }
  return stats;
}

export default { id, up };
