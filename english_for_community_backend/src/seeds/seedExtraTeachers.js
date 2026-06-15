/**
 * Seed thêm giáo viên phụ trợ (profile giống dữ liệu thật) + lớp học riêng.
 * Dùng để test co-teacher, search username, nhiều lớp trên dashboard.
 *
 * Run: npm run seed:extra-teachers
 * Requires MONGO_URI in .env
 */
import mongoose from 'mongoose';
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import User from '../models/User.js';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

const TEACHER_PASSWORD = process.env.EXTRA_TEACHER_PASSWORD || 'Teacher@123456';

const CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

const HOANGDONG_EMAIL = process.env.HOANGDONG_TEACHER_EMAIL || 'hoangdong.teacher@e4c.dev';

/** Giáo viên bổ sung — tên, bio, lớp giống dữ liệu trường học thật. */
const EXTRA_TEACHERS = [
  {
    fullName: 'Trần Ngọc Lan',
    username: 'trannl_teacher',
    email: 'seed.teacher.trannl@e4c.dev',
    gender: 'female',
    dateOfBirth: '1992-07-22',
    phone: '0903123456',
    goal: 'Giúp học sinh THCS tự tin giao tiếp tiếng Anh',
    bio: 'Giáo viên tiếng Anh THCS. 8 năm kinh nghiệm Listening & Speaking, chuyên phát âm và hội thoại hàng ngày.',
    classroom: {
      name: 'Lớp 9/3 — Giao tiếp hàng ngày',
      description: 'Khối 9 buổi chiều — trọng tâm phát âm, mẫu câu giao tiếp và luyện nghe cơ bản.',
    },
  },
  {
    fullName: 'Phạm Minh Tuấn',
    username: 'phammt_teacher',
    email: 'seed.teacher.phammt@e4c.dev',
    gender: 'male',
    dateOfBirth: '1989-11-08',
    phone: '0918234567',
    goal: 'Luyện thi IELTS và kỹ năng Academic English',
    bio: 'Thạc sĩ Ngôn ngữ Anh — giảng dạy IELTS Reading/Writing. Học viên trung bình đạt 6.5+ sau 3 tháng.',
    classroom: {
      name: 'IELTS Foundation — Khóa T5/2026',
      description: 'Lớp nền tảng IELTS 5.0–6.0. 2 buổi/tuần: Reading + Writing task 1/2.',
    },
  },
  {
    fullName: 'Lê Thị Hương',
    username: 'lethi_huong',
    email: 'seed.teacher.lethi@e4c.dev',
    gender: 'female',
    dateOfBirth: '1990-04-15',
    phone: '0935345678',
    goal: 'Ôn thi THPT Quốc gia môn Tiếng Anh',
    bio: 'Giáo viên khối 12 — chuyên đề trắc nghiệm, điền từ và đọc hiểu theo cấu trúc đề thi mới.',
    classroom: {
      name: 'Lớp 12A1 — Luyện đề THPTQG',
      description: 'Khối 12 chuyên — 3 buổi mock test/tháng, phân tích điểm yếu từng kỹ năng.',
    },
  },
  {
    fullName: 'Võ Quốc Khánh',
    username: 'voqk_teacher',
    email: 'seed.teacher.voqk@e4c.dev',
    gender: 'male',
    dateOfBirth: '1987-09-03',
    phone: '0976456789',
    goal: 'Phát triển English Club và học tập theo dự án',
    bio: 'Phụ trách CLB Tiếng Anh trường THPT. Tổ chức debate, presentation và học qua video/podcast.',
    classroom: {
      name: 'English Club — THPT Chuyên',
      description: 'CLB ngoại khóa — speaking debate, presentation và media project mỗi học kỳ.',
    },
  },
  {
    fullName: 'Nguyễn Bích Thảo',
    username: 'nguyenbt_teacher',
    email: 'seed.teacher.nguyenbt@e4c.dev',
    gender: 'female',
    dateOfBirth: '1994-01-28',
    phone: '0987567890',
    goal: 'Tiếng Anh thiếu nhi — vui, tự nhiên, bền vững',
    bio: 'Giáo viên tiểu học & THCS cấp 1. Phương pháp game-based learning, story-telling và phonics.',
    classroom: {
      name: 'Starter English — Khối 6',
      description: 'Lớp mới bắt đầu khối 6 — bảng chữ cái, từ vựng chủ đề và câu mẫu đơn giản.',
    },
  },
];

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

async function findUserForSeed(email) {
  const normalized = normalizeEmail(email);
  let user = await User.findOne({ email: normalized });
  if (user) return user;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({ email: new RegExp(`^${escaped}$`, 'i') });
}

async function uniqueInviteCode() {
  for (let i = 0; i < 25; i += 1) {
    const bytes = crypto.randomBytes(8);
    let code = '';
    for (let j = 0; j < 6; j += 1) code += CODE_CHARS[bytes[j] % CODE_CHARS.length];
    if (!(await Classroom.findOne({ inviteCode: code }))) return code;
  }
  throw new Error('Could not generate invite code');
}

async function upsertTeacher(spec, hashedPassword) {
  const email = normalizeEmail(spec.email);
  let user = await findUserForSeed(email);

  if (!user) {
    const usernameTaken = await User.findOne({ username: spec.username });
    const username = usernameTaken ? `${spec.username}_${Date.now().toString(36)}` : spec.username;
    user = await User.create({
      fullName: spec.fullName,
      username,
      email,
      password: hashedPassword,
      role: 'teacher',
      goal: spec.goal,
      bio: spec.bio,
      isVerified: true,
      gender: spec.gender,
      dateOfBirth: new Date(spec.dateOfBirth),
      phone: spec.phone,
      language: 'vi',
      timezone: 'Asia/Ho_Chi_Minh',
      totalPoints: 0,
    });
    console.log(`✅ Created teacher: ${spec.fullName} (@${username})`);
  } else {
    user.fullName = spec.fullName;
    user.role = 'teacher';
    user.isVerified = true;
    user._destroy = false;
    user.password = hashedPassword;
    user.goal = spec.goal;
    user.bio = spec.bio;
    user.gender = spec.gender;
    user.dateOfBirth = new Date(spec.dateOfBirth);
    if (spec.phone) user.phone = spec.phone;
    user.language = 'vi';
    user.timezone = 'Asia/Ho_Chi_Minh';
    await user.save();
    console.log(`↪ Updated teacher: ${spec.fullName} (@${user.username})`);
  }
  return user;
}

async function upsertClassroom(teacherId, spec) {
  const name = spec.classroom.name;
  let room = await Classroom.findOne({ teacherId, name });
  if (!room) {
    room = await Classroom.create({
      teacherId,
      name,
      description: spec.classroom.description,
      inviteCode: await uniqueInviteCode(),
      inviteToken: crypto.randomBytes(24).toString('hex'),
      joinPolicy: 'open',
    });
    console.log(`   ✅ Classroom: ${name} (invite ${room.inviteCode})`);
  } else {
    if (room.name !== name) room.name = name;
    room.description = spec.classroom.description;
    await room.save();
    console.log(`   ↪ Classroom exists: ${name} (invite ${room.inviteCode})`);
  }
  return room;
}

/** Gắn Lê Thị Hương làm co-teacher lớp 10A của Hoàng Đông (nếu đã seed hoangdong). */
async function linkSampleCoTeacher(coTeacherUser) {
  const owner = await findUserForSeed(HOANGDONG_EMAIL);
  if (!owner) {
    console.log('↪ Skip co-teacher demo: Hoàng Đông teacher not found (run seed:teacher-hoangdong first)');
    return;
  }
  const room = await Classroom.findOne({
    teacherId: owner._id,
    name: { $regex: /^10A1 — Ca sáng/i },
    archived: false,
  });
  if (!room) {
    console.log('↪ Skip co-teacher demo: classroom 10A1 — Ca sáng · HK2 not found');
    return;
  }

  let member = await ClassroomMember.findOne({ classroomId: room._id, userId: coTeacherUser._id });
  if (member?.status === 'active' && member.roleInClass === 'co_teacher') {
    console.log(`↪ Co-teacher already linked: ${coTeacherUser.fullName} → ${room.name}`);
    return;
  }

  if (!member) {
    member = await ClassroomMember.create({
      classroomId: room._id,
      userId: coTeacherUser._id,
      roleInClass: 'co_teacher',
      status: 'active',
      joinedAt: new Date(),
    });
  } else {
    member.roleInClass = 'co_teacher';
    member.status = 'active';
    member.leftAt = null;
    member.joinedAt = new Date();
    await member.save();
  }
  console.log(`✅ Co-teacher linked: ${coTeacherUser.fullName} (@${coTeacherUser.username}) → ${room.name}`);
}

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

  const created = [];
  for (const spec of EXTRA_TEACHERS) {
    console.log(`\n--- ${spec.fullName} ---`);
    const teacher = await upsertTeacher(spec, hashedPassword);
    const classroom = await upsertClassroom(teacher._id, spec);
    created.push({ teacher, classroom, spec });
  }

  const huong = created.find((x) => x.spec.username === 'lethi_huong');
  if (huong) {
    console.log('\n--- Co-teacher demo ---');
    await linkSampleCoTeacher(huong.teacher);
  }

  console.log('\n========== EXTRA TEACHERS SEED ==========');
  console.log(`Password (all): ${TEACHER_PASSWORD}`);
  console.log('');
  for (const { teacher, classroom, spec } of created) {
    console.log(`${spec.fullName}`);
    console.log(`  Email:     ${spec.email}`);
    console.log(`  Username:  ${teacher.username}`);
    console.log(`  Classroom: ${classroom.name}`);
    console.log(`  Invite:    ${classroom.inviteCode}`);
    console.log('');
  }
  console.log('Co-teacher test: login Hoàng Đông → 10A1 — Ca sáng · HK2 → Settings → Teaching team');
  console.log('Add co-teacher test: search username e.g. phammt_teacher, trannl_teacher');
  console.log('=========================================\n');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ seedExtraTeachers failed:', e);
  process.exit(1);
});
