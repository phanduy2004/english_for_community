/**
 * D4 discovery — compare examSnapshot across attempts per assignment.
 *
 * Usage:
 *   node scripts/discoverExamSnapshotParity.js
 *   node scripts/discoverExamSnapshotParity.js --json
 */
import mongoose from 'mongoose';
import { getMongoUri, getMongoUriForLog } from '../src/lib/mongoUri.js';

function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  const keys = Object.keys(value).sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`).join(',')}}`;
}

function snapshotFingerprint(snap) {
  if (!snap || typeof snap !== 'object') return 'null';
  const clone = { ...snap };
  delete clone._id;
  delete clone.id;
  return stableStringify(clone);
}

function byteSize(snap) {
  try {
    return Buffer.byteLength(JSON.stringify(snap ?? {}), 'utf8');
  } catch {
    return 0;
  }
}

async function main() {
  const asJson = process.argv.includes('--json');
  const uri = getMongoUri();
  if (!uri) throw new Error('MONGO_URI not set');
  await mongoose.connect(uri);
  const db = mongoose.connection.db;

  const attemptsCol = db.collection('examattempts');
  const sessionsCol = db.collection('examsessions');
  const assignmentsCol = db.collection('examassignments');

  const agg = await attemptsCol
    .aggregate([
      { $match: { examSnapshot: { $exists: true, $ne: null } } },
      { $group: { _id: '$assignmentId', count: { $sum: 1 } } },
      { $match: { count: { $gte: 2 } } },
      { $sort: { count: -1 } },
    ])
    .toArray();

  const report = {
    at: new Date().toISOString(),
    db: getMongoUriForLog(uri),
    writePaths: [
      'examAttemptService.startAttempt — exam.toObject() from assignment.examId',
      'examSessionService.createSession — exam.toObject() at lobby create',
      'examSessionService.startSession — fresh Exam.findById at live start → session + each attempt',
      'examAttemptService.attachRuntimeContextToAttempt — healExamSnapshotFromLiveExam may WRITE back',
      'seedTeacherHoangDongData.createAttemptsForAssignment — shared snapshot per assignment',
    ],
    assignmentsWithMultipleAttempts: agg.length,
    identicalGroups: 0,
    divergentGroups: 0,
    divergentSamples: [],
    sessionVsAttemptMismatches: 0,
    totalAttempts: await attemptsCol.countDocuments({ examSnapshot: { $exists: true } }),
    avgSnapshotBytes: 0,
  };

  let byteSum = 0;
  let byteN = 0;
  const allAttempts = await attemptsCol.find({ examSnapshot: { $exists: true } }).project({ examSnapshot: 1 }).toArray();
  for (const a of allAttempts) {
    byteSum += byteSize(a.examSnapshot);
    byteN += 1;
  }
  report.avgSnapshotBytes = byteN ? Math.round(byteSum / byteN) : 0;
  report.totalSnapshotBytes = byteSum;

  for (const g of agg) {
    const assignmentId = g._id;
    const attempts = await attemptsCol
      .find({ assignmentId })
      .project({ examSnapshot: 1, userId: 1, status: 1, sessionId: 1 })
      .toArray();

    const fps = new Map();
    for (const att of attempts) {
      const fp = snapshotFingerprint(att.examSnapshot);
      if (!fps.has(fp)) fps.set(fp, []);
      fps.get(fp).push(att);
    }

    if (fps.size === 1) {
      report.identicalGroups += 1;
    } else {
      report.divergentGroups += 1;
      if (report.divergentSamples.length < 10) {
        const assignment = await assignmentsCol.findOne({ _id: assignmentId });
        report.divergentSamples.push({
          assignmentId: String(assignmentId),
          attemptCount: attempts.length,
          distinctFingerprints: fps.size,
          fingerprintSizes: [...fps.entries()].map(([fp, rows]) => ({
            count: rows.length,
            bytes: byteSize(rows[0]?.examSnapshot),
            fpPrefix: fp.slice(0, 80),
            statuses: [...new Set(rows.map((r) => r.status))],
          })),
          assignmentCreatedAt: assignment?.createdAt,
          modes: assignment?.mode,
        });
      }
    }

    const sessions = await sessionsCol.find({ assignmentId }).project({ examSnapshot: 1, status: 1 }).toArray();
    for (const sess of sessions) {
      const sessFp = snapshotFingerprint(sess.examSnapshot);
      for (const att of attempts.filter((a) => String(a.sessionId) === String(sess._id))) {
        if (snapshotFingerprint(att.examSnapshot) !== sessFp) {
          report.sessionVsAttemptMismatches += 1;
        }
      }
    }
  }

  report.safeForAssignmentLevelDedup = report.divergentGroups === 0 && report.sessionVsAttemptMismatches === 0;

  await mongoose.disconnect();

  if (asJson) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log('=== D4 examSnapshot discovery ===');
    console.log('DB:', report.db);
    console.log('Total attempts with snapshot:', report.totalAttempts);
    console.log('Avg snapshot size (bytes):', report.avgSnapshotBytes);
    console.log('Total snapshot storage (bytes):', report.totalSnapshotBytes);
    console.log('Assignments with ≥2 attempts:', report.assignmentsWithMultipleAttempts);
    console.log('Identical snapshot groups:', report.identicalGroups);
    console.log('DIVERGENT snapshot groups:', report.divergentGroups);
    console.log('Session vs attempt mismatches:', report.sessionVsAttemptMismatches);
    console.log('SAFE for assignment-level dedup:', report.safeForAssignmentLevelDedup);
    if (report.divergentSamples.length) {
      console.log('\nDivergent samples:', JSON.stringify(report.divergentSamples, null, 2));
    }
    console.log('\nWrite paths:', report.writePaths.join('\n  - '));
  }

  process.exit(report.safeForAssignmentLevelDedup ? 0 : 2);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
