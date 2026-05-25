/**
 * Kiểm tra dữ liệu học tập (4 kỹ năng) cho seed.hd.student01@e4c.dev
 *   node src/scripts/checkSeedStudentData.js
 */
import mongoose from 'mongoose';
import User from '../models/User.js';
import UserDailyProgress from '../models/UserDailyProgress.js';
import Enrollment from '../models/Enrollment.js';
import ReadingProgress from '../models/ReadingProgress.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import WritingSubmission from '../models/WritingSubmission.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';
import ExamAttempt from '../models/ExamAttempt.js';
import historyService from '../services/historyService.js';
import { progressService } from '../services/progressService.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const EMAIL = process.argv[2] || 'seed.hd.student01@e4c.dev';

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI');
    process.exit(1);
  }
  await mongoose.connect(uri);
  console.log(`🔌 DB: ${getMongoUriForLog(uri)}\n`);

  const user = await User.findOne({ email: EMAIL.trim().toLowerCase() });
  if (!user) {
    console.log(`❌ User not found: ${EMAIL}`);
    console.log('   → npm run seed:teacher-hoangdong');
    process.exit(1);
  }
  console.log(`👤 ${user.fullName} (${user.email}) id=${user._id}\n`);

  const uid = user._id;
  const counts = {
    dailyProgress: await UserDailyProgress.countDocuments({ userId: uid }),
    dictationAttempts: await DictationAttempt.countDocuments({ userId: uid }),
    listeningEnrollment: await Enrollment.countDocuments({ userId: uid, isCompleted: true }),
    readingCompleted: await ReadingProgress.countDocuments({ userId: uid, status: 'completed' }),
    speakingCompleted: await SpeakingEnrollment.countDocuments({ userId: uid, isCompleted: true }),
    writingSubmitted: await WritingSubmission.countDocuments({
      userId: uid,
      status: { $in: ['submitted', 'reviewed'] },
    }),
    listeningComp: await ListeningCompAttempt.countDocuments({ userId: uid }),
    examAttempts: await ExamAttempt.countDocuments({ userId: uid }),
  };

  console.log('--- Collections (raw) ---');
  Object.entries(counts).forEach(([k, v]) => console.log(`  ${k}: ${v}`));

  const end = new Date().toISOString().slice(0, 10);
  const start = new Date();
  start.setDate(start.getDate() - 30);
  const startStr = start.toISOString().slice(0, 10);

  const history = await historyService.getHistoryPaginated(
    uid.toString(),
    startStr,
    end,
    null,
    { page: 1, limit: 50 },
  );

  console.log('\n--- API Lịch sử (30 ngày) — giống app Profile → Lịch sử ---');
  console.log(`  total: ${history.total}`);
  history.data.forEach((item, i) => {
    console.log(
      `  ${i + 1}. [${item.type}] ${item.subType || '-'} | ${item.title} | score=${item.score}`,
    );
  });

  if (counts.dailyProgress === 0 && history.total === 0) {
    console.log('\n❌ Chưa có dữ liệu kỹ năng. Chạy:');
    console.log('   npm run seed:student-app');
  } else if (history.total === 0 && counts.examAttempts > 0) {
    console.log('\n⚠️ Có bài THI (exam) nhưng không có bài LUYỆN KỸ NĂNG trong Lịch sử.');
    console.log('   Bài thi lớp ≠ Lịch sử bài tập (Nghe/Đọc/Viết/Nói).');
    console.log('   → npm run seed:student-app');
  } else if (history.total > 0) {
    console.log('\n✅ App Lịch sử bài tập sẽ thấy dữ liệu (pull-to-refresh / mở lại màn).');
  }

  console.log('\n--- Progress → chi tiết kỹ năng (giống dialog Reading attempts) ---');
  for (const range of ['day', 'week', 'month']) {
    const { data: readingDetail } = await progressService.getStatDetailData(
      uid.toString(),
      'reading',
      range,
    );
    console.log(`  reading / ${range}: ${readingDetail.length} bản ghi`);
    readingDetail.slice(0, 2).forEach((row, i) => {
      console.log(`    ${i + 1}. ${row.title} | score=${row.score} | ${row.date}`);
    });
  }
  if (counts.readingCompleted === 0) {
    console.log('\n⚠️ Không có ReadingProgress completed → dialog Tiến độ Đọc sẽ trống.');
    console.log('   (Thẻ % vẫn có thể hiện từ UserDailyProgress.) → npm run seed:student-app');
  }

  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
