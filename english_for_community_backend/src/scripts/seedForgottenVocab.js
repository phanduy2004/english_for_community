/**
 * Seed dữ liệu cho phần "Học từ lãng quên" (Vocabulary Review / Ebbinghaus)
 * cho MỘT user cụ thể (mặc định: minhan.nguyen@thptchuyene4c.edu.vn).
 *
 * "Từ lãng quên" = Word có status='learning' và nextReviewDate <= now
 * (getReviewWords → màn Review Session / FAB "Ôn tập ngay").
 *
 * An toàn: chỉ UPSERT theo {user, headword}, KHÔNG xoá từ cũ của user.
 * Idempotent: chạy lại nhiều lần cho kết quả nhất quán (reset lịch ôn về "đến hạn").
 *
 * Run:
 *   node src/scripts/seedForgottenVocab.js
 *   node src/scripts/seedForgottenVocab.js someone@else.edu.vn   # override email
 *
 * Requires MONGO_URI in .env
 */
import mongoose from 'mongoose';
import User from '../models/User.js';
import Word from '../models/Word.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const TARGET_EMAIL = (process.argv[2] || 'minhan.nguyen@thptchuyene4c.edu.vn')
  .trim()
  .toLowerCase();

/** Ngày lệch so với bây giờ (âm = quá khứ, dương = tương lai). */
function daysFromNow(days, hour = 9, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(hour, minute, 0, 0);
  return d;
}

/**
 * Bộ từ vựng.
 *  - due (số): số ngày đã QUÁ HẠN ôn tập (nextReviewDate = now - due) → từ "lãng quên".
 *  - due âm: chưa tới hạn (nextReviewDate ở tương lai) → không hiện trong review.
 *  - level: learningLevel (0..).
 */
const WORDS = [
  // ===== learning + ĐÃ QUÁ HẠN (từ lãng quên, sẽ vào phiên ôn tập) =====
  { headword: 'abandon',     ipa: 'əˈbændən',     shortDefinition: 'từ bỏ, bỏ rơi',        pos: 'verb', status: 'learning', level: 2, due: 1 },
  { headword: 'accomplish',  ipa: 'əˈkʌmplɪʃ',    shortDefinition: 'hoàn thành, đạt được',  pos: 'verb', status: 'learning', level: 1, due: 2 },
  { headword: 'anxiety',     ipa: 'æŋˈzaɪəti',    shortDefinition: 'sự lo âu, lo lắng',     pos: 'noun', status: 'learning', level: 3, due: 3 },
  { headword: 'brilliant',   ipa: 'ˈbrɪliənt',    shortDefinition: 'xuất sắc, chói lọi',    pos: 'adj',  status: 'learning', level: 2, due: 4 },
  { headword: 'cautious',    ipa: 'ˈkɔːʃəs',      shortDefinition: 'thận trọng, cẩn thận',  pos: 'adj',  status: 'learning', level: 1, due: 5 },
  { headword: 'compromise',  ipa: 'ˈkɒmprəmaɪz',  shortDefinition: 'thỏa hiệp, nhượng bộ',  pos: 'noun', status: 'learning', level: 4, due: 6 },
  { headword: 'deliberate',  ipa: 'dɪˈlɪbərət',   shortDefinition: 'có chủ ý, cố tình',     pos: 'adj',  status: 'learning', level: 2, due: 2 },
  { headword: 'emphasize',   ipa: 'ˈemfəsaɪz',    shortDefinition: 'nhấn mạnh',             pos: 'verb', status: 'learning', level: 3, due: 1 },
  { headword: 'fascinating', ipa: 'ˈfæsɪneɪtɪŋ',  shortDefinition: 'hấp dẫn, mê hoặc',      pos: 'adj',  status: 'learning', level: 1, due: 8 },
  { headword: 'genuine',     ipa: 'ˈdʒenjuɪn',    shortDefinition: 'chân thật, xác thực',   pos: 'adj',  status: 'learning', level: 2, due: 10 },
  { headword: 'hesitate',    ipa: 'ˈhezɪteɪt',    shortDefinition: 'do dự, ngần ngại',      pos: 'verb', status: 'learning', level: 1, due: 3 },
  { headword: 'inevitable',  ipa: 'ɪnˈevɪtəbl',   shortDefinition: 'không thể tránh khỏi',  pos: 'adj',  status: 'learning', level: 4, due: 12 },
  { headword: 'maintain',    ipa: 'meɪnˈteɪn',    shortDefinition: 'duy trì, bảo trì',      pos: 'verb', status: 'learning', level: 3, due: 4 },
  { headword: 'negotiate',   ipa: 'nɪˈɡəʊʃieɪt',  shortDefinition: 'đàm phán, thương lượng', pos: 'verb', status: 'learning', level: 2, due: 7 },
  { headword: 'perceive',    ipa: 'pəˈsiːv',      shortDefinition: 'nhận thức, cảm nhận',   pos: 'verb', status: 'learning', level: 1, due: 1 },
  { headword: 'reluctant',   ipa: 'rɪˈlʌktənt',   shortDefinition: 'miễn cưỡng, bất đắc dĩ', pos: 'adj',  status: 'learning', level: 3, due: 16 },

  // ===== learning + CHƯA TỚI HẠN (không vào review, để tab "Đang học" đa dạng) =====
  { headword: 'sufficient',  ipa: 'səˈfɪʃnt',     shortDefinition: 'đủ, đầy đủ',            pos: 'adj',  status: 'learning', level: 3, due: -2 },
  { headword: 'thorough',    ipa: 'ˈθʌrə',        shortDefinition: 'kỹ lưỡng, thấu đáo',    pos: 'adj',  status: 'learning', level: 4, due: -5 },
  { headword: 'versatile',   ipa: 'ˈvɜːsətaɪl',   shortDefinition: 'đa năng, linh hoạt',    pos: 'adj',  status: 'learning', level: 2, due: -1 },
  { headword: 'willingness', ipa: 'ˈwɪlɪŋnəs',    shortDefinition: 'sự sẵn lòng',           pos: 'noun', status: 'learning', level: 1, due: -3 },

  // ===== recent (vừa tra) =====
  { headword: 'curious',     ipa: 'ˈkjʊəriəs',    shortDefinition: 'tò mò, hiếu kỳ',        pos: 'adj',  status: 'recent', level: 0, due: 0 },
  { headword: 'schedule',    ipa: 'ˈʃedjuːl',     shortDefinition: 'lịch trình, thời khóa biểu', pos: 'noun', status: 'recent', level: 0, due: 0 },
  { headword: 'suggest',     ipa: 'səˈdʒest',     shortDefinition: 'đề nghị, gợi ý',        pos: 'verb', status: 'recent', level: 0, due: 0 },

  // ===== saved (đã lưu) =====
  { headword: 'ambitious',   ipa: 'æmˈbɪʃəs',     shortDefinition: 'tham vọng, hoài bão',   pos: 'adj',  status: 'saved', level: 0, due: 0 },
  { headword: 'gratitude',   ipa: 'ˈɡrætɪtjuːd',  shortDefinition: 'lòng biết ơn',          pos: 'noun', status: 'saved', level: 0, due: 0 },
  { headword: 'resilient',   ipa: 'rɪˈzɪliənt',   shortDefinition: 'kiên cường, bền bỉ',    pos: 'adj',  status: 'saved', level: 0, due: 0 },
];

async function findUserByEmail(email) {
  const normalized = String(email || '').trim().toLowerCase();
  let user = await User.findOne({ email: normalized });
  if (user) return user;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({ email: new RegExp(`^${escaped}$`, 'i') });
}

function buildDoc(userId, w) {
  const doc = {
    user: userId,
    headword: w.headword,
    ipa: w.ipa,
    shortDefinition: w.shortDefinition,
    pos: w.pos,
    status: w.status,
    learningLevel: w.level,
  };

  if (w.status === 'learning') {
    // nextReviewDate quá khứ (due>0) = đã đến hạn ôn ("lãng quên").
    doc.nextReviewDate = daysFromNow(-w.due, 9, 0);
    // Lần ôn gần nhất: trước hạn một nhịp (giả lập đã ôn rồi bỏ quên).
    doc.lastReviewedDate = daysFromNow(-w.due - (2 + w.level * 3), 9, 0);
  } else if (w.status === 'recent') {
    doc.nextReviewDate = new Date();
    doc.lastReviewedDate = daysFromNow(0, 8, 0);
  } else {
    // saved: không có lịch ôn
    doc.nextReviewDate = new Date();
    doc.lastReviewedDate = daysFromNow(-1, 8, 0);
  }
  return doc;
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Thiếu MONGO_URI trong .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);

  const user = await findUserByEmail(TARGET_EMAIL);
  if (!user) {
    console.error(`❌ Không tìm thấy user với email: ${TARGET_EMAIL}`);
    await mongoose.connection.close();
    process.exit(1);
  }
  console.log(`👤 User: ${user.fullName || user.username || '(no name)'} <${user.email}>  id=${user._id}\n`);

  const now = new Date();
  let upserted = 0;
  for (const w of WORDS) {
    const doc = buildDoc(user._id, w);
    await Word.findOneAndUpdate(
      { user: user._id, headword: w.headword },
      { $set: doc },
      { upsert: true, new: true }
    );
    upserted += 1;
  }

  // Thống kê kiểm chứng
  const learningTotal = await Word.countDocuments({ user: user._id, status: 'learning' });
  const dueNow = await Word.countDocuments({
    user: user._id,
    status: 'learning',
    nextReviewDate: { $lte: now },
  });
  const recentTotal = await Word.countDocuments({ user: user._id, status: 'recent' });
  const savedTotal = await Word.countDocuments({ user: user._id, status: 'saved' });

  console.log('========== SEED "HỌC TỪ LÃNG QUÊN" ==========');
  console.log(`Upsert:                 ${upserted} từ`);
  console.log(`learning (tổng):        ${learningTotal}`);
  console.log(`⏰ ĐẾN HẠN ÔN (lãng quên): ${dueNow}  ← vào phiên "Ôn tập ngay"`);
  console.log(`recent:                 ${recentTotal}`);
  console.log(`saved:                  ${savedTotal}`);
  console.log('=============================================');
  console.log('App → Từ vựng → FAB "Ôn tập ngay" sẽ hiện các từ đến hạn.');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch(async (e) => {
  console.error('❌ seedForgottenVocab failed:', e);
  try { await mongoose.connection.close(); } catch {}
  process.exit(1);
});
