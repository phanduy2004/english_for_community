import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

// Danh sách user test với điểm số (XP), ngày sinh và giới tính đa dạng
const normalUsers = [
  {
    fullName: 'Nguyen Van A',
    username: 'nguyenvana',
    email: 'user1@gmail.com',
    goal: 'IELTS 7.0',
    totalPoints: 1250,
    gender: 'male',
    dateOfBirth: new Date('1998-05-15')
  },
  {
    fullName: 'Tran Thi B',
    username: 'tranthib',
    email: 'user2@gmail.com',
    goal: 'Communication',
    totalPoints: 3400,
    gender: 'female',
    dateOfBirth: new Date('2000-10-20')
  },
  {
    fullName: 'Le Van C',
    username: 'levanc',
    email: 'user3@gmail.com',
    goal: 'TOEIC 800',
    totalPoints: 850,
    gender: 'male',
    dateOfBirth: new Date('1995-03-12')
  },
  {
    fullName: 'Pham Thi D',
    username: 'phamthid',
    email: 'user4@gmail.com',
    goal: 'IELTS 8.0',
    totalPoints: 5100,
    gender: 'female',
    dateOfBirth: new Date('2002-01-30')
  },
  {
    fullName: 'Hoang Van E',
    username: 'hoangvane',
    email: 'user5@gmail.com',
    goal: 'Basic English',
    totalPoints: 150,
    gender: 'male',
    dateOfBirth: new Date('2005-07-07')
  },
  {
    fullName: 'Vu Thi F',
    username: 'vuthif',
    email: 'user6@gmail.com',
    goal: 'Communication',
    totalPoints: 2800,
    gender: 'female',
    dateOfBirth: new Date('1999-12-25')
  },
  {
    fullName: 'Dang Van G',
    username: 'dangvang',
    email: 'user7@gmail.com',
    goal: 'TOEIC 600',
    totalPoints: 2100,
    gender: 'male',
    dateOfBirth: new Date('1990-09-09')
  },
  {
    fullName: 'Bui Thi H',
    username: 'buithih',
    email: 'user8@gmail.com',
    goal: 'IELTS 6.5',
    totalPoints: 4200,
    gender: 'female',
    dateOfBirth: new Date('2001-04-18')
  }
];

/** Tài khoản admin để test console (đăng nhập → redirect /admin). */
const DEFAULT_ADMIN_PASSWORD = process.env.SEED_ADMIN_PASSWORD || 'adminpassword123';
const DEFAULT_USER_PASSWORD = process.env.SEED_USER_PASSWORD || '123456';
const BCRYPT_ROUNDS = 12;

if (!process.env.SEED_ADMIN_PASSWORD) {
  console.warn('⚠️  SEED_ADMIN_PASSWORD not set — using default dev password for admin accounts.');
}

const ADMIN_ACCOUNTS = [
  {
    fullName: 'Super Admin',
    username: 'admin',
    email: 'admin@englishapp.com',
    password: DEFAULT_ADMIN_PASSWORD,
  },
  {
    fullName: 'Test Admin',
    username: 'testuser_admin',
    email: 'testuser@example.com',
    password: process.env.SEED_TEST_ADMIN_PASSWORD || DEFAULT_ADMIN_PASSWORD,
  },
  {
    fullName: 'Test Admin (legacy email)',
    username: 'test_admin',
    email: 'test@example.com',
    password: process.env.SEED_TEST_ADMIN_PASSWORD || DEFAULT_ADMIN_PASSWORD,
  },
];

async function upsertAdminAccount(spec) {
  const hashed = await bcrypt.hash(spec.password, BCRYPT_ROUNDS);
  let user = await User.findOne({ email: spec.email });
  if (!user) {
    user = await User.create({
      fullName: spec.fullName,
      username: spec.username,
      email: spec.email,
      password: hashed,
      role: 'admin',
      isVerified: true,
      goal: 'Manage System',
      totalPoints: 99999,
      gender: 'male',
      dateOfBirth: new Date('1990-01-01'),
    });
    console.log(`✅ Created admin: ${spec.email}`);
    return;
  }
  user.fullName = spec.fullName;
  user.username = spec.username;
  user.password = hashed;
  user.role = 'admin';
  user.isVerified = true;
  user._destroy = false;
  await user.save();
  console.log(`🔄 Updated admin: ${spec.email}`);
}

const mongoUri = getMongoUri();
if (!mongoUri) {
  console.error('❌ Missing MONGO_URI in .env');
  process.exit(1);
}

mongoose.connect(mongoUri)
  .then(async () => {
    console.log(`🔌 Connected to DB (${getMongoUriForLog(mongoUri)})`);

    // --- PHẦN 1: ADMIN (console) ---
    for (const spec of ADMIN_ACCOUNTS) {
      await upsertAdminAccount(spec);
    }

    // --- PHẦN 2: TẠO USER THƯỜNG ---
    console.log('🌱 Starting to seed normal users...');
    const commonPassword = DEFAULT_USER_PASSWORD;

    for (const user of normalUsers) {
      const userExists = await User.findOne({ email: user.email });

      if (!userExists) {
        // TẠO MỚI
        const hashedPassword = await bcrypt.hash(commonPassword, BCRYPT_ROUNDS);

        await User.create({
          fullName: user.fullName,
          username: user.username,
          email: user.email,
          password: hashedPassword,
          role: 'user',
          isVerified: true,
          goal: user.goal,
          totalPoints: user.totalPoints,
          gender: user.gender,           // 🔥 Thêm gender
          dateOfBirth: user.dateOfBirth  // 🔥 Thêm DOB
        });
        console.log(`✅ Created user: ${user.username} (${user.gender}, Born: ${user.dateOfBirth.getFullYear()})`);
      } else {
        const hashedPassword = await bcrypt.hash(commonPassword, BCRYPT_ROUNDS);
        userExists.password = hashedPassword;
        userExists.isVerified = true;
        userExists.totalPoints = user.totalPoints;
        userExists.gender = user.gender;
        userExists.dateOfBirth = user.dateOfBirth;

        await userExists.save();
        console.log(`🔄 Updated info for existing user: ${user.username}`);
      }
    }

    console.log('🎉 Seeding process completed!');
    process.exit();
  })
  .catch(e => {
    console.error('❌ Error seeding data:', e);
    process.exit(1);
  });