import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

const TEACHER_EMAIL = process.env.TEACHER_SEED_EMAIL || 'teacher@englishapp.com';
const TEACHER_PASSWORD = process.env.TEACHER_SEED_PASSWORD || 'Teacher@123456';
const TEACHER_USERNAME = process.env.TEACHER_SEED_USERNAME || 'teacher_e4c_seed';

/**
 * Tạo hoặc cập nhật một user role `teacher` để dev / QA đăng nhập app + khu vực Teacher hub.
 * Cần MONGO_URI trong .env (giống seedAdmin.js).
 */
async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})`);

  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(TEACHER_PASSWORD, salt);

  let user = await User.findOne({ email: TEACHER_EMAIL });
  let username = TEACHER_USERNAME;
  if (!user) {
    const clash = await User.findOne({ username });
    if (clash) {
      username = `${TEACHER_USERNAME}_${Date.now().toString(36)}`;
      console.log(`⚠️ Username taken, using: ${username}`);
    }
    user = await User.create({
      fullName: 'Seed Teacher',
      username,
      email: TEACHER_EMAIL,
      password: hashedPassword,
      role: 'teacher',
      goal: 'Teaching',
      isVerified: true,
      gender: 'male',
      dateOfBirth: new Date('1990-01-01'),
      totalPoints: 0,
    });
    console.log('✅ Teacher user created');
  } else {
    user.role = 'teacher';
    user.isVerified = true;
    user.password = hashedPassword;
    if (!user.fullName) user.fullName = 'Seed Teacher';
    await user.save();
    console.log('✅ Existing user updated to teacher (password reset to seed value)');
  }

  console.log('');
  console.log('--- Login (Flutter / API) ---');
  console.log(`Email:    ${TEACHER_EMAIL}`);
  console.log(`Password: ${TEACHER_PASSWORD}`);
  console.log('');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ seedTeacher failed:', e);
  process.exit(1);
});
