/**
 * Xóa toàn bộ dữ liệu miền Lớp học / Đề thi / Bài giao / Bài nộp (giữ User + CMS).
 *
 * Run: npm run seed:purge-classroom
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ExamAssignment from '../models/ExamAssignment.js';
import Exam from '../models/Exam.js';
import ClassroomMember from '../models/ClassroomMember.js';
import Classroom from '../models/Classroom.js';
import ClassroomActivityLog from '../models/ClassroomActivityLog.js';
import Notification from '../models/Notification.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const CLASSROOM_NOTIFICATION_TYPES = [
  'CLASSROOM_JOIN_REQUEST',
  'CLASSROOM_JOIN_APPROVED',
  'CLASSROOM_JOIN_REJECTED',
  'EXAM_ASSIGNED',
  'EXAM_ASSIGNMENT_UPDATED',
  'EXAM_ASSIGNMENT_CLOSED',
  'EXAM_SESSION_LIVE',
  'EXAM_SUBMISSION_RECEIVED',
  'EXAM_RESULTS_RELEASED',
  'CO_TEACHER_INVITE',
  'CO_TEACHER_INVITE_ACCEPTED',
  'CO_TEACHER_INVITE_DECLINED',
  'CO_TEACHER_REMOVED',
];

export async function purgeClassroomDomain({ silent = false } = {}) {
  const log = silent ? () => {} : console.log;

  const rAttempts = await ExamAttempt.deleteMany({});
  log(`🧹 ExamAttempt: ${rAttempts.deletedCount}`);

  const rSessions = await ExamSession.deleteMany({});
  log(`🧹 ExamSession: ${rSessions.deletedCount}`);

  const rAssignments = await ExamAssignment.deleteMany({});
  log(`🧹 ExamAssignment: ${rAssignments.deletedCount}`);

  const rExams = await Exam.deleteMany({});
  log(`🧹 Exam: ${rExams.deletedCount}`);

  const rActivity = await ClassroomActivityLog.deleteMany({});
  log(`🧹 ClassroomActivityLog: ${rActivity.deletedCount}`);

  const rMembers = await ClassroomMember.deleteMany({});
  log(`🧹 ClassroomMember: ${rMembers.deletedCount}`);

  const rRooms = await Classroom.deleteMany({});
  log(`🧹 Classroom: ${rRooms.deletedCount}`);

  const rNoti = await Notification.deleteMany({ type: { $in: CLASSROOM_NOTIFICATION_TYPES } });
  log(`🧹 Notifications (classroom/exam): ${rNoti.deletedCount}`);

  return {
    attempts: rAttempts.deletedCount,
    sessions: rSessions.deletedCount,
    assignments: rAssignments.deletedCount,
    exams: rExams.deletedCount,
    activityLogs: rActivity.deletedCount,
    members: rMembers.deletedCount,
    classrooms: rRooms.deletedCount,
    notifications: rNoti.deletedCount,
  };
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);
  console.log('⚠️  Purging ALL classroom / exam / assignment / attempt data...\n');

  const totals = await purgeClassroomDomain();
  console.log('\n✅ Purge complete.', totals);

  await mongoose.connection.close();
  process.exit(0);
}

const isMain = process.argv[1]?.replace(/\\/g, '/').includes('purgeClassroomDomain');
if (isMain) {
  run().catch((e) => {
    console.error('❌ purgeClassroomDomain failed:', e);
    process.exit(1);
  });
}
