/**
 * Targeted cleanup of the Hoàng Đông demo dataset.
 *
 * Removes ONLY the seeded teacher + students and their classroom / exam /
 * assignment / attempt / session data (identified by the teacher email + the
 * student school domain). It NEVER uses `deleteMany({})`, so real classroom
 * data owned by other teachers is untouched.
 *
 * Dry-run by default — prints what WOULD be deleted, changes nothing.
 *
 *   node src/seeds/cleanupDemoSeed.js                       # dry-run (safe preview)
 *   node src/seeds/cleanupDemoSeed.js --confirm             # delete classroom/exam/attempt + student learning data
 *   node src/seeds/cleanupDemoSeed.js --confirm --with-users        # also delete the seeded user accounts
 *   node src/seeds/cleanupDemoSeed.js --confirm --keep-learning     # keep student learning data (vocab/attempts)
 *
 * Requires MONGO_URI in .env. Override targets with HOANGDONG_TEACHER_EMAIL /
 * HOANGDONG_STUDENT_DOMAIN if you changed them when seeding.
 */
import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import User from '../models/User.js';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ClassroomActivityLog from '../models/ClassroomActivityLog.js';
import Exam from '../models/Exam.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import ReadingProgress from '../models/ReadingProgress.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import WritingSubmission from '../models/WritingSubmission.js';
import UserDailyProgress from '../models/UserDailyProgress.js';
import Word from '../models/Word.js';
import Enrollment from '../models/Enrollment.js';
import Notification from '../models/Notification.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const TEACHER_EMAIL = (process.env.HOANGDONG_TEACHER_EMAIL || 'hoangdong.teacher@e4c.dev')
  .trim()
  .toLowerCase();
const STUDENT_SCHOOL_DOMAIN = process.env.HOANGDONG_STUDENT_DOMAIN || 'thptchuyene4c.edu.vn';

const CONFIRM = process.argv.includes('--confirm');
const WITH_USERS = process.argv.includes('--with-users');
const WITH_LEARNING = !process.argv.includes('--keep-learning');

function domainRegex(domain) {
  const esc = String(domain).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`@${esc}$`, 'i');
}

/** A filter is "real" only if it targets something — never allow a blank match. */
function isTargeted(filter) {
  if (!filter || typeof filter !== 'object') return false;
  if (Array.isArray(filter.$or)) return filter.$or.length > 0;
  return Object.keys(filter).length > 0;
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})`);
  console.log(`🎯 Target teacher <${TEACHER_EMAIL}> + students @${STUDENT_SCHOOL_DOMAIN}`);
  console.log(
    CONFIRM
      ? '🔴 MODE: DELETE (--confirm)\n'
      : '🟡 MODE: DRY-RUN (no --confirm) — nothing will be deleted\n'
  );

  const teacher = await User.findOne({ email: TEACHER_EMAIL }).select('_id fullName email').lean();
  const students = await User.find({ email: domainRegex(STUDENT_SCHOOL_DOMAIN) })
    .select('_id')
    .lean();
  const teacherId = teacher?._id ?? null;
  const studentIds = students.map((s) => s._id);

  console.log(
    `Found: teacher=${teacherId ? '1' : '0'}, students=${studentIds.length}`
  );
  if (!teacherId && studentIds.length === 0) {
    console.log('Nothing to clean — no seed teacher or students found.');
    await mongoose.connection.close();
    process.exit(0);
  }

  const classrooms = teacherId ? await Classroom.find({ teacherId }).select('_id').lean() : [];
  const classroomIds = classrooms.map((c) => c._id);
  const exams = teacherId ? await Exam.find({ teacherId }).select('_id').lean() : [];
  const examIds = exams.map((e) => e._id);

  const assignmentOr = [
    ...(teacherId ? [{ teacherId }] : []),
    ...(classroomIds.length ? [{ classroomId: { $in: classroomIds } }] : []),
    ...(examIds.length ? [{ examId: { $in: examIds } }] : []),
  ];
  const assignments = assignmentOr.length
    ? await ExamAssignment.find({ $or: assignmentOr }).select('_id').lean()
    : [];
  const assignmentIds = assignments.map((a) => a._id);

  const plan = [];
  const add = (label, Model, filter) => plan.push({ label, Model, filter });

  add('ExamAttempt', ExamAttempt, {
    $or: [
      ...(assignmentIds.length ? [{ assignmentId: { $in: assignmentIds } }] : []),
      ...(studentIds.length ? [{ userId: { $in: studentIds } }] : []),
    ],
  });
  add('ExamSession', ExamSession, {
    $or: [
      ...(assignmentIds.length ? [{ assignmentId: { $in: assignmentIds } }] : []),
      ...(teacherId ? [{ leaderTeacherId: teacherId }] : []),
    ],
  });
  if (assignmentIds.length) add('ExamAssignment', ExamAssignment, { _id: { $in: assignmentIds } });
  if (examIds.length) add('Exam', Exam, { _id: { $in: examIds } });
  if (classroomIds.length) {
    add('ClassroomMember', ClassroomMember, { classroomId: { $in: classroomIds } });
    add('ClassroomActivityLog', ClassroomActivityLog, { classroomId: { $in: classroomIds } });
    add('Classroom', Classroom, { _id: { $in: classroomIds } });
  }

  if (WITH_LEARNING && studentIds.length) {
    const byUser = { userId: { $in: studentIds } };
    add('ReadingAttempt', ReadingAttempt, byUser);
    add('ReadingProgress', ReadingProgress, byUser);
    add('ListeningCompAttempt', ListeningCompAttempt, byUser);
    add('DictationAttempt', DictationAttempt, byUser);
    add('SpeakingAttempt', SpeakingAttempt, byUser);
    add('SpeakingEnrollment', SpeakingEnrollment, byUser);
    add('WritingSubmission', WritingSubmission, byUser);
    add('UserDailyProgress', UserDailyProgress, byUser);
    add('Word', Word, byUser);
    add('Enrollment', Enrollment, byUser);
    add('Notification', Notification, byUser);
  }

  for (const { label, Model, filter } of plan) {
    if (!isTargeted(filter)) continue;
    if (CONFIRM) {
      const r = await Model.deleteMany(filter);
      console.log(`🧹 ${label}: ${r.deletedCount}`);
    } else {
      const c = await Model.countDocuments(filter);
      console.log(`   ${label}: ${c} (would delete)`);
    }
  }

  if (WITH_USERS) {
    const userOr = [
      ...(teacherId ? [{ _id: teacherId }] : []),
      ...(studentIds.length ? [{ _id: { $in: studentIds } }] : []),
    ];
    const userFilter = { $or: userOr };
    if (isTargeted(userFilter)) {
      if (CONFIRM) {
        const r = await User.deleteMany(userFilter);
        console.log(`🧹 User (teacher+students): ${r.deletedCount}`);
      } else {
        const c = await User.countDocuments(userFilter);
        console.log(`   User (teacher+students): ${c} (would delete, --with-users)`);
      }
    }
  } else {
    console.log(`   User accounts KEPT (add --with-users to also delete ${(teacherId ? 1 : 0) + studentIds.length} accounts)`);
  }

  console.log(
    CONFIRM ? '\n✅ Cleanup complete.' : '\n🟡 Dry-run only. Re-run with --confirm to actually delete.'
  );
  await mongoose.connection.close();
  process.exit(0);
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  run().catch((e) => {
    console.error('❌ cleanupDemoSeed failed:', e);
    process.exit(1);
  });
}

export { run as runCleanupDemoSeed };
