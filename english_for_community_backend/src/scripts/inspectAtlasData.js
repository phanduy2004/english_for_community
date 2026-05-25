/**
 * Kiểm tra dữ liệu seed HoangDong có trên DB mà MONGO_URI trỏ tới không.
 *   npm run db:inspect
 */
import mongoose from 'mongoose';
import User from '../models/User.js';
import Classroom from '../models/Classroom.js';
import Exam from '../models/Exam.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Không có MONGO_URI trong english_for_community_backend/.env');
    process.exit(1);
  }

  console.log('📋 MONGO_URI →', getMongoUriForLog(uri));
  await mongoose.connect(uri);

  const dbName = mongoose.connection.db.databaseName;
  const host = mongoose.connection.host;
  console.log(`📦 Đang đọc database: "${dbName}" (host: ${host})\n`);

  const seedStudents = await User.countDocuments({
    email: /^seed\.hd\.student\d+@e4c\.dev$/i,
    _destroy: { $ne: true },
  });
  const teacher = await User.findOne({
    email: /^hoangdong\.teacher@e4c\.dev$/i,
    _destroy: { $ne: true },
  }).select('email fullName role');
  const seedClassrooms = await Classroom.countDocuments({
    name: /^\[SEED:HoangDong\]/,
  });
  const seedExams = await Exam.countDocuments({
    title: /^\[SEED:HoangDong\]/,
  });

  console.log('--- HoangDong seed trên DB này ---');
  console.log(`  Học sinh seed.hd.student*: ${seedStudents} (kỳ vọng 15)`);
  console.log(`  Giáo viên: ${teacher ? `${teacher.email} (${teacher.role})` : 'KHÔNG CÓ'}`);
  console.log(`  Lớp [SEED:HoangDong]*: ${seedClassrooms} (kỳ vọng 2)`);
  console.log(`  Đề [SEED:HoangDong]*: ${seedExams} (kỳ vọng 5)`);

  if (seedStudents === 0) {
    console.log('\n⚠️ Không thấy học sinh seed trên DB này.');
    console.log('   → Chạy: npm run seed:teacher-hoangdong (từ thư mục english_for_community_backend)');
    console.log('   → Trong Atlas Compass: chọn đúng cluster + database "' + dbName + '" + collection "users"');
  } else {
    const sample = await User.findOne({ email: 'seed.hd.student01@e4c.dev' }).select('email _id');
    console.log(`\n✅ Có dữ liệu. Ví dụ student01 _id: ${sample?._id}`);
    console.log('\nAtlas UI: Browse Collections → database "' + dbName + '" → users / classrooms / exams');
  }

  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
