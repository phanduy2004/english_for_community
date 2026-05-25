/**
 * Kiểm tra tài khoản seed HoangDong có đăng nhập được không (DB + bcrypt).
 *   node src/scripts/checkSeedLogin.js [email]
 */
import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import User from '../models/User.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

const CHECKS = [
  { email: 'hoangdong.teacher@e4c.dev', password: 'Teacher@123456', label: 'Teacher' },
  { email: 'seed.hd.student01@e4c.dev', password: 'Student@123456', label: 'Student 01' },
  { email: 'seed.hd.student15@e4c.dev', password: 'Student@123456', label: 'Student 15' },
];

async function checkOne(email, password, label) {
  const normalized = String(email).trim().toLowerCase();
  let user = await User.findOne({ email: normalized, _destroy: { $ne: true } });
  if (!user) {
    const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    user = await User.findOne({
      email: new RegExp(`^${escaped}$`, 'i'),
      _destroy: { $ne: true },
    });
  }
  if (!user) {
    console.log(`❌ ${label} (${email}): NOT IN DATABASE`);
    return;
  }
  const hashOk = /^\$2[aby]\$\d{2}\$/.test(user.password || '');
  const pwdOk = hashOk && (await bcrypt.compare(password, user.password));
  const issues = [];
  if (user._destroy) issues.push('_destroy=true');
  if (!user.isVerified) issues.push('isVerified=false');
  if (!hashOk) issues.push('password not bcrypt (Google?)');
  if (hashOk && !pwdOk) issues.push('password mismatch');
  if (user.isBanned) issues.push('banned');

  const status = issues.length === 0 ? '✅ OK' : `⚠️ ${issues.join(', ')}`;
  console.log(`${status} ${label}`);
  console.log(`   stored email: ${user.email} | role: ${user.role} | id: ${user._id}`);
  if (issues.length) {
    console.log(`   → run: npm run repair:seed-logins`);
    console.log(`   → then: npm run seed:teacher-hoangdong`);
  }
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }
  console.log(`🔌 Database: ${getMongoUriForLog(uri)}\n`);

  await mongoose.connect(uri);

  const arg = process.argv[2];
  if (arg) {
    await checkOne(arg, process.env.SEED_CHECK_PASSWORD || 'Student@123456', 'Custom');
  } else {
    for (const c of CHECKS) {
      await checkOne(c.email, c.password, c.label);
    }
  }

  const dupes = await User.aggregate([
    { $match: { email: /seed\.hd\.student/i } },
    { $group: { _id: { $toLower: '$email' }, count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
  ]);
  if (dupes.length) {
    console.log('\n⚠️ Duplicate student emails (case variants):');
    dupes.forEach((d) => console.log(`   ${d._id} × ${d.count}`));
  }

  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
