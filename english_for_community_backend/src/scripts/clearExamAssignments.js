/**
 * Deletes all teacher exam assignments and related runtime data.
 * Order: attempts → sessions → assignments (FK safety).
 *
 * Usage (from english_for_community_backend):
 *   node src/scripts/clearExamAssignments.js
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ExamAssignment from '../models/ExamAssignment.js';

const MONGO_URI = process.env.MONGO_URI ?? process.env.MONGODB_URI;
if (!MONGO_URI) {
  console.error('Missing MONGO_URI / MONGODB_URI');
  process.exit(1);
}

await mongoose.connect(MONGO_URI);
const attempts = await ExamAttempt.deleteMany({});
const sessions = await ExamSession.deleteMany({});
const assignments = await ExamAssignment.deleteMany({});
console.log('Cleared exam assignment data:', {
  examAttempts: attempts.deletedCount,
  examSessions: sessions.deletedCount,
  examAssignments: assignments.deletedCount,
});
await mongoose.disconnect();
process.exit(0);
