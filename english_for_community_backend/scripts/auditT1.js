/**
 * T1 audit — orphan counts, index presence, sample explain (mongosh-style via driver).
 *
 * Usage: node scripts/auditT1.js
 */
import mongoose from 'mongoose';
import { getMongoUri, getMongoUriForLog } from '../src/lib/mongoUri.js';

const REQUIRED_INDEXES = [
  { collection: 'cuecomments', name: 'listeningId_1_cueId_1_createdAt_-1' },
  { collection: 'enrollments', name: 'userId_1_listeningId_1' },
  { collection: 'examsessions', name: 'assignmentId_1_status_1' },
  { collection: 'notifications', name: 'recipientId_1_isRead_1_createdAt_-1' },
  { collection: 'classroommessages', name: 'senderId_1_createdAt_-1' },
  { collection: 'admin_audit_logs', name: 'targetType_1_targetId_1_createdAt_-1' },
  { collection: 'admin_audit_logs', name: 'actorId_1_createdAt_-1' },
  { collection: 'readingattempts', name: 'userId_1_readingId_1_createdAt_-1' },
];

const TTL_INDEXES = [
  { collection: 'notifications', field: 'createdAt' },
  { collection: 'admin_audit_logs', field: 'createdAt' },
  { collection: 'classroomactivitylogs', field: 'createdAt' },
];

async function countOrphans(db, fromCol, localField, toCol) {
  const pipeline = [
    { $match: { [localField]: { $ne: null } } },
    {
      $lookup: {
        from: toCol,
        localField,
        foreignField: '_id',
        as: '_parent',
      },
    },
    { $match: { _parent: { $size: 0 } } },
    { $count: 'n' },
  ];
  const r = await db.collection(fromCol).aggregate(pipeline).toArray();
  return r[0]?.n ?? 0;
}

async function explainIxscan(db, collection, query) {
  const plan = await db.collection(collection).find(query).explain('executionStats');
  const stage =
    plan?.executionStats?.executionStages?.stage ??
    plan?.queryPlanner?.winningPlan?.inputStage?.stage ??
    'unknown';
  return stage;
}

async function main() {
  const uri = getMongoUri();
  if (!uri) throw new Error('MONGO_URI not set');
  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  console.log('[T1] DB', getMongoUriForLog(uri));

  const indexesOk = [];
  const indexesMissing = [];
  for (const req of REQUIRED_INDEXES) {
    const idx = await db.collection(req.collection).indexes();
    const found = idx.some((i) => i.name === req.name);
    (found ? indexesOk : indexesMissing).push(req);
  }

  const ttlFound = [];
  for (const t of TTL_INDEXES) {
    const idx = await db.collection(t.collection).indexes();
    const hit = idx.find((i) => i.expireAfterSeconds != null && JSON.stringify(i.key).includes(t.field));
    ttlFound.push({ ...t, expireAfterSeconds: hit?.expireAfterSeconds ?? null, present: !!hit });
  }

  const orphans = {
    examAttemptsMissingAssignment: await countOrphans(
      db,
      'examattempts',
      'assignmentId',
      'examassignments'
    ),
    classroomMembersMissingClassroom: await countOrphans(
      db,
      'classroommembers',
      'classroomId',
      'classrooms'
    ),
  };

  const usersNullUpdatedAt = await db.collection('users').countDocuments({
    $or: [{ updatedAt: null }, { updatedAt: { $exists: false } }],
  });

  const explains = {
    notificationsUnread: await explainIxscan(db, 'notifications', {
      recipientId: new mongoose.Types.ObjectId(),
      isRead: false,
    }),
    cueComments: await explainIxscan(db, 'cuecomments', {
      listeningId: new mongoose.Types.ObjectId(),
      cueId: '0',
    }),
  };

  const report = {
    at: new Date().toISOString(),
    indexesOk,
    indexesMissing,
    ttlFound,
    orphans,
    usersNullUpdatedAt,
    explains,
  };

  console.log(JSON.stringify(report, null, 2));
  await mongoose.disconnect();

  const failed =
    indexesMissing.length > 0 ||
    Object.values(orphans).some((n) => n > 0) ||
    usersNullUpdatedAt > 0;
  process.exit(failed ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
