/**
 * Gỡ tiền tố [SEED:…] khỏi tên lớp / tiêu đề đề thi trên DB hiện có (không xóa dữ liệu).
 *
 * Run: npm run seed:migrate-labels
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import Classroom from '../models/Classroom.js';
import Exam from '../models/Exam.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const BRACKET_PREFIX = /^\[SEED:[^\]]+\]\s*/;
/** Match documents whose name/title still has a [SEED:…] prefix. */
const HAS_SEED_PREFIX = /^\[SEED:/;

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);

  const rooms = await Classroom.find({ name: HAS_SEED_PREFIX });
  for (const room of rooms) {
    const next = room.name.replace(BRACKET_PREFIX, '').trim();
    if (next && next !== room.name) {
      console.log(`  Classroom: "${room.name}" → "${next}"`);
      room.name = next;
      await room.save();
    }
  }

  const exams = await Exam.find({ title: HAS_SEED_PREFIX });
  for (const exam of exams) {
    const next = exam.title.replace(BRACKET_PREFIX, '').trim();
    if (next && next !== exam.title) {
      console.log(`  Exam: "${exam.title}" → "${next}"`);
      exam.title = next;
      await exam.save();
    }
  }

  console.log(`\n✅ Done: ${rooms.length} classroom(s), ${exams.length} exam(s) updated.`);
  console.log('Hot-restart Flutter web / refresh trang giáo viên để thấy tên mới.\n');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ seedMigrateDemoLabels failed:', e);
  process.exit(1);
});
