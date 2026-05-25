/**
 * Sửa tài khoản seed không đăng nhập được: isVerified + reset mật khẩu chuẩn.
 *
 *   node src/scripts/repairSeedLogins.js
 */
import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import User from '../models/User.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

const REPAIRS = [
  { pattern: /^seed\.hd\.student\d+@e4c\.dev$/i, password: 'Student@123456' },
  { pattern: /^hoangdong\.teacher@e4c\.dev$/i, password: 'Teacher@123456' },
  { pattern: /^user[1-8]@gmail\.com$/i, password: '123456' },
  { pattern: /^test@example\.com$/i, password: 'Test@1234', role: 'admin' },
  { pattern: /^testuser@example\.com$/i, password: 'Test@1234', role: 'admin' },
  { pattern: /^admin@englishapp\.com$/i, password: 'adminpassword123', role: 'admin' },
];

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }
  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);

  const users = await User.find({ _destroy: { $ne: true } }).select('email isVerified password role');
  const salt = await bcrypt.genSalt(10);
  let fixed = 0;

  for (const u of users) {
    const email = (u.email || '').trim();
    const rule = REPAIRS.find((r) => r.pattern.test(email));
    if (!rule) continue;

    const hash = await bcrypt.hash(rule.password, salt);
    let changed = false;
    if (!u.isVerified) {
      u.isVerified = true;
      changed = true;
    }
    const match = await bcrypt.compare(rule.password, u.password);
    if (!match) {
      u.password = hash;
      changed = true;
    }
    if (rule.role && u.role !== rule.role) {
      u.role = rule.role;
      changed = true;
    }
    if (u._destroy) {
      u._destroy = false;
      changed = true;
    }
    const normalized = email.toLowerCase();
    if (u.email !== normalized) {
      u.email = normalized;
      changed = true;
    }
    if (changed) {
      await u.save();
      console.log(`✅ ${email} → verified, password synced (${rule.password})`);
      fixed += 1;
    } else {
      console.log(`↪ ${email} OK`);
    }
  }

  console.log(`\n🎉 Done. Updated ${fixed} account(s).`);
  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
