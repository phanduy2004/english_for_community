/**
 * Wipes teacher exam system: attempts, sessions, assignments, and exams (draft + published).
 *
 * Usage (from english_for_community_backend):
 *   node src/scripts/clearAllExamData.js
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ExamAssignment from '../models/ExamAssignment.js';
import Exam from '../models/Exam.js';

const MONGO_URI = process.env.MONGO_URI ?? process.env.MONGODB_URI;
if (!MONGO_URI) {
  console.error('Missing MONGO_URI / MONGODB_URI');
  process.exit(1);
}

await mongoose.connect(MONGO_URI);
const attempts = await ExamAttempt.deleteMany({});
const sessions = await ExamSession.deleteMany({});
const assignments = await ExamAssignment.deleteMany({});
const exams = await Exam.deleteMany({});
console.log('Cleared all exam system data:', {
  examAttempts: attempts.deletedCount,
  examSessions: sessions.deletedCount,
  examAssignments: assignments.deletedCount,
  exams: exams.deletedCount,
});
await mongoose.disconnect();
process.exit(0);
