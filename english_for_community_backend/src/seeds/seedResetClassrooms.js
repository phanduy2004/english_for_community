/**
 * Xóa toàn bộ dữ liệu lớp/đề/bài giao và seed lại demo chỉnh chu.
 *
 * Run: npm run seed:reset-classroom
 */
import 'dotenv/config';
import mongoose from 'mongoose';
import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { purgeClassroomDomain } from './purgeClassroomDomain.js';
import { retireLegacyDemoStudents } from './seedTeacherHoangDongData.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const backendRoot = path.resolve(__dirname, '../..');

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);
  console.log('========== RESET CLASSROOM DOMAIN ==========\n');

  await purgeClassroomDomain();
  await retireLegacyDemoStudents();
  await mongoose.connection.close();
  console.log('\n--- Re-seeding Hoàng Đông + extra teachers ---\n');

  execSync('node src/seeds/seedTeacherHoangDongData.js', {
    cwd: backendRoot,
    stdio: 'inherit',
    env: process.env,
  });
  execSync('node src/seeds/seedExtraTeachers.js', {
    cwd: backendRoot,
    stdio: 'inherit',
    env: process.env,
  });

  console.log('\n✅ seed:reset-classroom finished.');
}

run().catch((e) => {
  console.error('❌ seed:reset-classroom failed:', e);
  process.exit(1);
});
