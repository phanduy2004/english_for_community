/**
 * Seed teacher Đồ Đàng Hoàng + classrooms + 5 skills exams + assignments + attempts
 * for Schedule & Analytics testing.
 *
 * Run: npm run seed:teacher-hoangdong
 * Requires MONGO_URI in .env
 */
import mongoose from 'mongoose';
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import Exam from '../models/Exam.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import Listening from '../models/Listening.js';
import Reading from '../models/Reading.js';
import SpeakingSet from '../models/SpeakingSet.js';
import { buildIntegratedScores, computeFinal } from '../services/examIntegratedScoring.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const SEED_TAG = '[SEED:HoangDong]';
const TEACHER_EMAIL = process.env.HOANGDONG_TEACHER_EMAIL || 'hoangdong.teacher@e4c.dev';
const TEACHER_PASSWORD = process.env.HOANGDONG_TEACHER_PASSWORD || 'Teacher@123456';
const TEACHER_USERNAME = process.env.HOANGDONG_TEACHER_USERNAME || 'hoangdong_teacher';

const SECTION_IDS = {
  listening: 'sec_listening',
  reading: 'sec_reading',
  writing: 'sec_writing',
  speaking: 'sec_speaking',
};

const CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

async function findUserForSeed(email) {
  const normalized = normalizeEmail(email);
  let user = await User.findOne({ email: normalized });
  if (user) return user;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({ email: new RegExp(`^${escaped}$`, 'i') });
}

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

function daysFromNow(n, hour = 9, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function randomBetween(min, max) {
  return min + Math.random() * (max - min);
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

async function uniqueInviteCode() {
  for (let i = 0; i < 25; i += 1) {
    const bytes = crypto.randomBytes(8);
    let code = '';
    for (let j = 0; j < 6; j += 1) code += CODE_CHARS[bytes[j] % CODE_CHARS.length];
    if (!(await Classroom.findOne({ inviteCode: code }))) return code;
  }
  throw httpError(500, 'Could not generate invite code');
}

function scoreGrammarItem(item, answer) {
  const k = String(item.kind || '');
  if (k === 'mcq_single' || k === 'mcq_multi') {
    const selected = Array.isArray(answer?.selectedIndexes)
      ? answer.selectedIndexes.map(Number).sort((a, b) => a - b)
      : [];
    const correct = Array.isArray(item.correctOptionIndexes)
      ? item.correctOptionIndexes.map(Number).sort((a, b) => a - b)
      : [];
    if (selected.length !== correct.length) return 0;
    for (let i = 0; i < selected.length; i += 1) {
      if (selected[i] !== correct[i]) return 0;
    }
    return Number(item.points ?? 1);
  }
  if (k === 'grammar_cloze' || k === 'grammar_gap') {
    const blanks = answer?.blanks || {};
    let earned = 0;
    const max = Number(item.points ?? 1);
    const defs = item.blanks || [];
    if (defs.length === 0) return 0;
    const per = max / defs.length;
    for (const b of defs) {
      const raw = blanks[b.blankId];
      const norm = String(raw ?? '')
        .trim()
        .toLowerCase();
      const ok = (b.acceptedAnswers || []).some(
        (a) => String(a).trim().toLowerCase() === norm
      );
      if (ok) earned += per;
    }
    return Math.min(max, earned);
  }
  return 0;
}

function grammarItemsPack(count = 3) {
  const items = [
    {
      kind: 'mcq_single',
      itemId: 'g_seed_1',
      order: 0,
      points: 1,
      stem: 'She _____ to school every morning.',
      options: ['go', 'goes', 'going', 'gone'],
      correctOptionIndexes: [1],
    },
    {
      kind: 'mcq_single',
      itemId: 'g_seed_2',
      order: 1,
      points: 1,
      stem: 'They have lived here _____ 2018.',
      options: ['for', 'since', 'from', 'during'],
      correctOptionIndexes: [1],
    },
    {
      kind: 'grammar_cloze',
      itemId: 'g_seed_3',
      order: 2,
      points: 2,
      passage: 'English {{0}} a global language.',
      blanks: [{ blankId: '0', acceptedAnswers: ['is', 'was'] }],
    },
    {
      kind: 'mcq_single',
      itemId: 'g_seed_4',
      order: 3,
      points: 1,
      stem: 'If it rains, we _____ at home.',
      options: ['stay', 'stayed', 'will stay', 'staying'],
      correctOptionIndexes: [2],
    },
    {
      kind: 'mcq_single',
      itemId: 'g_seed_5',
      order: 4,
      points: 1,
      stem: 'Neither Tom nor his brothers _____ ready.',
      options: ['is', 'are', 'was', 'be'],
      correctOptionIndexes: [1],
    },
  ];
  return items.slice(0, count);
}

function grammarAnswersFor(items, accuracy = 0.85) {
  const answers = {};
  for (const it of items) {
    if (Math.random() > accuracy) {
      if (it.kind === 'grammar_cloze') {
        answers[it.itemId] = { blanks: { 0: 'wrong' } };
      } else {
        answers[it.itemId] = { selectedIndexes: [0] };
      }
      continue;
    }
    if (it.kind === 'grammar_cloze') {
      answers[it.itemId] = { blanks: { '0': it.blanks[0].acceptedAnswers[0] } };
    } else {
      answers[it.itemId] = { selectedIndexes: [...it.correctOptionIndexes] };
    }
  }
  return answers;
}

function buildSkillSection(skill, order, resourceId, resourceTitle, extra = {}) {
  return {
    sectionId: SECTION_IDS[skill],
    sectionKind: 'skill_content',
    skill,
    order,
    title: resourceTitle || skill.charAt(0).toUpperCase() + skill.slice(1),
    instructions: `Complete the ${skill} section.`,
    resourceId: resourceId ? String(resourceId) : '',
    resourceTitle: resourceTitle || '',
    items: [],
    ...extra,
  };
}

function inlineListeningAnswers(listeningDoc, accuracy = 0.82) {
  const cues = {};
  const list = listeningDoc?.cues || [];
  for (let i = 0; i < list.length; i += 1) {
    const expected = list[i]?.text != null ? String(list[i].text).trim() : '';
    cues[String(i)] = Math.random() < accuracy ? expected : 'seed wrong';
  }
  return { completed: true, listeningCues: cues };
}

function inlineReadingAnswers(readingDoc, accuracy = 0.78) {
  const ra = {};
  const questions = readingDoc?.questions || [];
  for (let i = 0; i < questions.length; i += 1) {
    const q = questions[i];
    const qid = q._id != null ? String(q._id) : String(i);
    const correct = Number(q.correctAnswerIndex ?? 0);
    ra[qid] = Math.random() < accuracy ? correct : correct === 0 ? 1 : 0;
  }
  return { completed: true, readingAnswers: ra };
}

function examSnapshotFromDoc(exam) {
  return {
    id: exam._id.toString(),
    teacherId: exam.teacherId.toString(),
    title: exam.title,
    description: exam.description,
    status: exam.status,
    contentVersion: exam.contentVersion,
    sections: exam.sections,
    settings: exam.settings,
  };
}

const EXAM_BLUEPRINTS = [
  {
    title: `${SEED_TAG} Kiểm tra Nghe + Đọc + Ngữ pháp`,
    description: 'Dictation listening, reading MCQ, grammar block — good for auto-graded analytics.',
    skills: ['listening', 'reading'],
    grammarCount: 4,
  },
  {
    title: `${SEED_TAG} Luyện Viết + Nói`,
    description: 'Writing essay + speaking — manual grading backlog for analytics.',
    skills: ['writing', 'speaking'],
    grammarCount: 0,
    fixedWritingPrompt: {
      title: 'Opinion essay',
      text: 'Some people believe technology makes life easier. Others think it creates stress. Discuss both views and give your opinion.',
      taskType: 'Essay',
      level: 'B2',
    },
  },
  {
    title: `${SEED_TAG} Giữa kỳ — Nghe Đọc Viết + Grammar`,
    description: 'Four components without speaking.',
    skills: ['listening', 'reading', 'writing'],
    grammarCount: 3,
    fixedWritingPrompt: {
      title: 'Formal letter',
      text: 'Write a letter to your school principal suggesting one improvement to the English program.',
      taskType: 'Letter',
      level: 'B1',
    },
  },
  {
    title: `${SEED_TAG} Đọc hiểu + Viết tóm tắt`,
    description: 'Reading comprehension and short writing only.',
    skills: ['reading', 'writing'],
    grammarCount: 0,
    fixedWritingPrompt: {
      title: 'Summary',
      text: 'Summarize the main idea of the reading passage in 80–120 words.',
      taskType: 'Summary',
      level: 'B1',
    },
  },
  {
    title: `${SEED_TAG} Ôn tập 4 kỹ năng (Nghe Đọc Viết Nói)`,
    description: 'Full skills mix for calendar + score distribution.',
    skills: ['listening', 'reading', 'writing', 'speaking'],
    grammarCount: 2,
    fixedWritingPrompt: {
      title: 'Story',
      text: 'Write a short story (150 words) that includes the words: journey, surprise, friend.',
      taskType: 'Story',
      level: 'A2',
    },
  },
];

/** Assignment windows spread for Schedule calendar + Analytics trends. */
function assignmentPlans(examIndex) {
  const base = [
    {
      label: 'past closed',
      mode: 'self_paced',
      opensAt: daysFromNow(-28, 8),
      dueAt: daysFromNow(-22, 23),
      closesAt: daysFromNow(-21, 23, 59),
    },
    {
      label: 'recent submissions',
      mode: 'scheduled',
      opensAt: daysFromNow(-14, 7),
      dueAt: daysFromNow(-5, 20),
      closesAt: daysFromNow(-4, 22),
    },
    {
      label: 'live now',
      mode: 'scheduled',
      opensAt: daysFromNow(-3, 6),
      dueAt: daysFromNow(4, 18),
      closesAt: daysFromNow(7, 21),
    },
    {
      label: 'opens soon',
      mode: 'self_paced',
      opensAt: daysFromNow(5, 9),
      dueAt: daysFromNow(12, 22),
      closesAt: daysFromNow(14, 23, 59),
    },
    {
      label: 'far future',
      mode: 'self_paced',
      opensAt: daysFromNow(18, 10),
      dueAt: daysFromNow(25, 17),
      closesAt: daysFromNow(27, 23, 59),
    },
  ];
  // Each exam uses 2–3 windows (rotate by index)
  const a = examIndex % base.length;
  const b = (examIndex + 2) % base.length;
  return [base[a], base[(a + 1) % base.length], base[b]];
}

const STUDENT_PROFILES = [
  { fullName: 'Nguyễn Minh An', email: 'seed.hd.student01@e4c.dev', username: 'seed_hd_s01' },
  { fullName: 'Trần Thu Hà', email: 'seed.hd.student02@e4c.dev', username: 'seed_hd_s02' },
  { fullName: 'Lê Quốc Bảo', email: 'seed.hd.student03@e4c.dev', username: 'seed_hd_s03' },
  { fullName: 'Phạm Ngọc Linh', email: 'seed.hd.student04@e4c.dev', username: 'seed_hd_s04' },
  { fullName: 'Hoàng Văn Đức', email: 'seed.hd.student05@e4c.dev', username: 'seed_hd_s05' },
  { fullName: 'Vũ Thị Mai', email: 'seed.hd.student06@e4c.dev', username: 'seed_hd_s06' },
  { fullName: 'Đặng Hữu Phúc', email: 'seed.hd.student07@e4c.dev', username: 'seed_hd_s07' },
  { fullName: 'Bùi Thảo My', email: 'seed.hd.student08@e4c.dev', username: 'seed_hd_s08' },
  { fullName: 'Ngô Kiên Cường', email: 'seed.hd.student09@e4c.dev', username: 'seed_hd_s09' },
  { fullName: 'Dương Lan Chi', email: 'seed.hd.student10@e4c.dev', username: 'seed_hd_s10' },
  { fullName: 'Lý Gia Hân', email: 'seed.hd.student11@e4c.dev', username: 'seed_hd_s11' },
  { fullName: 'Mai Hoàng Nam', email: 'seed.hd.student12@e4c.dev', username: 'seed_hd_s12' },
  { fullName: 'Tôn Nhật Minh', email: 'seed.hd.student13@e4c.dev', username: 'seed_hd_s13' },
  { fullName: 'Chu Bảo Trân', email: 'seed.hd.student14@e4c.dev', username: 'seed_hd_s14' },
  { fullName: 'Phan Đức Anh', email: 'seed.hd.student15@e4c.dev', username: 'seed_hd_s15' },
];

async function upsertTeacher() {
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(TEACHER_PASSWORD, salt);

  const teacherEmail = normalizeEmail(TEACHER_EMAIL);
  let user = await findUserForSeed(teacherEmail);
  if (!user) {
    let username = TEACHER_USERNAME;
    if (await User.findOne({ username })) {
      username = `${TEACHER_USERNAME}_${Date.now().toString(36)}`;
    }
    user = await User.create({
      fullName: 'Đồ Đàng Hoàng',
      username,
      email: teacherEmail,
      password: hashedPassword,
      role: 'teacher',
      goal: 'Giảng dạy tiếng Anh THPT',
      isVerified: true,
      gender: 'male',
      dateOfBirth: new Date('1988-03-15'),
      totalPoints: 0,
    });
    console.log('✅ Created teacher Đồ Đàng Hoàng');
  } else {
    user.email = teacherEmail;
    user.fullName = 'Đồ Đàng Hoàng';
    user.role = 'teacher';
    user.isVerified = true;
    user._destroy = false;
    user.password = hashedPassword;
    await user.save();
    console.log('✅ Updated teacher Đồ Đàng Hoàng');
  }
  return user;
}

async function cleanupTeacherSeedData(teacherId) {
  const exams = await Exam.find({ teacherId, title: { $regex: '^\\[SEED:HoangDong\\]' } }).select('_id');
  const examIds = exams.map((e) => e._id);
  if (examIds.length === 0) return;

  const assignments = await ExamAssignment.find({ examId: { $in: examIds } }).select('_id');
  const assignmentIds = assignments.map((a) => a._id);

  if (assignmentIds.length) {
    const delAttempts = await ExamAttempt.deleteMany({ assignmentId: { $in: assignmentIds } });
    console.log(`🧹 Removed ${delAttempts.deletedCount} seed attempts`);
    const delAssign = await ExamAssignment.deleteMany({ _id: { $in: assignmentIds } });
    console.log(`🧹 Removed ${delAssign.deletedCount} seed assignments`);
  }
  const delExams = await Exam.deleteMany({ _id: { $in: examIds } });
  console.log(`🧹 Removed ${delExams.deletedCount} seed exams`);
}

async function upsertClassrooms(teacherId) {
  const specs = [
    { name: `${SEED_TAG} Lớp 10A — Sáng`, description: 'Khối 10 buổi sáng — seed analytics' },
    { name: `${SEED_TAG} Lớp 11B — Nâng cao`, description: 'Khối 11 luyện thi — seed schedule' },
  ];

  const out = [];
  for (const spec of specs) {
    let room = await Classroom.findOne({ teacherId, name: spec.name });
    if (!room) {
      room = await Classroom.create({
        teacherId,
        name: spec.name,
        description: spec.description,
        inviteCode: await uniqueInviteCode(),
        inviteToken: crypto.randomBytes(24).toString('hex'),
        joinPolicy: 'open',
      });
      console.log(`✅ Classroom: ${spec.name} (code ${room.inviteCode})`);
    } else {
      console.log(`↪ Classroom exists: ${spec.name} (code ${room.inviteCode})`);
    }
    out.push(room);
  }
  return out;
}

async function upsertStudents() {
  const salt = await bcrypt.genSalt(10);
  const defaultHash = await bcrypt.hash('Student@123456', salt);
  const students = [];

  for (const p of STUDENT_PROFILES) {
    const studentEmail = normalizeEmail(p.email);
    let u = await findUserForSeed(studentEmail);
    if (!u) {
      u = await User.create({
        fullName: p.fullName,
        username: p.username,
        email: studentEmail,
        password: defaultHash,
        role: 'user',
        isVerified: true,
        goal: 'IELTS 6.5',
        gender: pick(['male', 'female']),
        dateOfBirth: daysFromNow(-8000 - Math.floor(Math.random() * 2000)),
        totalPoints: Math.floor(Math.random() * 3000),
      });
    } else {
      u.email = studentEmail;
      u.fullName = p.fullName;
      u.username = p.username;
      u.password = defaultHash;
      u.role = 'user';
      u.isVerified = true;
      u._destroy = false;
      await u.save();
    }
    students.push(u);
  }
  console.log(`✅ ${students.length} students ready`);
  return students;
}

async function enrollStudents(classrooms, students) {
  let added = 0;
  for (const room of classrooms) {
    for (const s of students) {
      const exists = await ClassroomMember.findOne({
        classroomId: room._id,
        userId: s._id,
      });
      if (!exists) {
        await ClassroomMember.create({
          classroomId: room._id,
          userId: s._id,
          roleInClass: 'student',
          status: 'active',
        });
        added += 1;
      }
    }
  }
  console.log(`✅ Enrolled students (${added} new memberships)`);
}

async function loadCmsResources() {
  const listening = await Listening.findOne({
    _destroy: { $ne: true },
    'cues.0': { $exists: true },
  })
    .select('title cues')
    .lean();
  const reading = await Reading.findOne({
    _destroy: { $ne: true },
    'questions.0': { $exists: true },
  })
    .select('title questions')
    .lean();

  if (listening) console.log(`📻 Listening CMS: ${listening.title} (${listening.cues?.length ?? 0} cues)`);
  else console.log('⚠️ No Listening in DB — listening sections will be no_content until CMS exists');
  if (reading) console.log(`📖 Reading CMS: ${reading.title} (${reading.questions?.length ?? 0} questions)`);
  else console.log('⚠️ No Reading in DB — reading sections will be no_content');

  const speaking = await SpeakingSet.findOne({
    _destroy: { $ne: true },
    'lessons.0': { $exists: true },
  })
    .select('title lessons')
    .lean();
  if (speaking) console.log(`🎤 Speaking CMS: ${speaking.title}`);
  else console.log('⚠️ No Speaking set in DB — speaking sections need a linked exercise in exam editor');

  return { listening, reading, speaking };
}

function buildExamDoc(teacherId, blueprint, cms) {
  const sections = [];
  let order = 0;
  const skills = blueprint.skills || [];

  for (const skill of skills) {
    const extra = {};
    if (skill === 'writing' && blueprint.fixedWritingPrompt) {
      extra.fixedWritingPrompt = blueprint.fixedWritingPrompt;
    }
    let resourceId = '';
    let resourceTitle = '';
    if (skill === 'listening' && cms.listening) {
      resourceId = cms.listening._id.toString();
      resourceTitle = cms.listening.title;
    }
    if (skill === 'reading' && cms.reading) {
      resourceId = cms.reading._id.toString();
      resourceTitle = cms.reading.title;
    }
    if (skill === 'speaking' && cms.speaking) {
      resourceId = cms.speaking._id.toString();
      resourceTitle = cms.speaking.title;
    }
    sections.push(buildSkillSection(skill, order, resourceId, resourceTitle, extra));
    order += 1;
  }

  const grammarItems = grammarItemsPack(blueprint.grammarCount || 0);

  return {
    teacherId,
    title: blueprint.title,
    description: blueprint.description,
    status: 'published',
    contentVersion: 1,
    sections,
    settings: {
      examFormat: 'skills_exam',
      showResultsPolicy: 'after_submit',
      allowMultipleSubmissions: false,
      allowPartialSubmit: true,
      grammarItems,
    },
  };
}

function buildAttemptAnswers(exam, cms, studentIndex, options = {}) {
  const { listeningAcc = 0.82, readingAcc = 0.78, grammarAcc = 0.85 } = options;
  const answers = {};
  const grammarItems = exam.settings?.grammarItems || [];
  Object.assign(answers, grammarAnswersFor(grammarItems, grammarAcc - (studentIndex % 5) * 0.03));

  for (const sec of exam.sections || []) {
    const sid = sec.sectionId;
    const skill = sec.skill;
    if (skill === 'listening' && cms.listening) {
      answers[sid] = inlineListeningAnswers(cms.listening, listeningAcc);
    } else if (skill === 'reading' && cms.reading) {
      answers[sid] = inlineReadingAnswers(cms.reading, readingAcc);
    } else if (skill === 'writing') {
      answers[sid] = {
        completed: true,
        writingDraft: `Student ${studentIndex + 1} essay draft for seed testing. Technology helps learning when used wisely. (word count ~45)`,
      };
    } else if (skill === 'speaking') {
      answers[sid] = { completed: true, speakingNote: 'Seed speaking placeholder' };
    }
  }
  return answers;
}

function round1(n) {
  return Math.round(n * 10) / 10;
}

async function createAttemptsForAssignment(assignment, exam, students, cms) {
  const snapshot = examSnapshotFromDoc(exam);
  const submitRate = 0.72;
  let created = 0;
  let inProgress = 0;

  const opens = assignment.config?.opensAt ? new Date(assignment.config.opensAt).getTime() : Date.now() - 86400000;
  const closes = assignment.config?.closesAt
    ? new Date(assignment.config.closesAt).getTime()
    : Date.now() + 86400000 * 14;
  const now = Date.now();

  for (let i = 0; i < students.length; i += 1) {
    const student = students[i];
    const roll = Math.random();

    // ~12% in progress (for analytics inProgress KPI)
    if (roll > submitRate && roll < submitRate + 0.12 && now >= opens && now <= closes) {
      const startedAt = new Date(now - Math.floor(randomBetween(1, 48)) * 3600000);
      await ExamAttempt.create({
        assignmentId: assignment._id,
        userId: student._id,
        examSnapshot: snapshot,
        status: 'in_progress',
        startedAt,
        answers: buildAttemptAnswers(exam, cms, i, { grammarAcc: 0.5 }),
        gradingState: 'pending_auto',
        integrity: { riskLevel: pick(['low', 'low', 'medium']) },
      });
      inProgress += 1;
      continue;
    }

    if (roll > submitRate) continue;

    const span = Math.max(closes - opens, 86400000);
    const submittedAt = new Date(opens + Math.floor(Math.random() * span * 0.9));
    if (submittedAt.getTime() > now) {
      submittedAt.setTime(now - Math.floor(randomBetween(1, 72)) * 3600000);
    }
    const startedAt = new Date(submittedAt.getTime() - Math.floor(randomBetween(25, 110)) * 60000);

    const answers = buildAttemptAnswers(exam, cms, i);
    const plainAttempt = {
      userId: student._id,
      startedAt,
      submittedAt,
      answers,
    };

    let scores = await buildIntegratedScores(plainAttempt, exam, scoreGrammarItem);

    // Manual skills + variety
    for (const sec of exam.sections || []) {
      const sid = sec.sectionId;
      if (sec.skill === 'writing' && scores.skillScores?.[sid]) {
        const pending = i % 4 === 0;
        scores.skillScores[sid] = {
          ...scores.skillScores[sid],
          score: pending ? null : round1(randomBetween(4.8, 9.0)),
          status: pending ? 'pending_manual' : 'finalized',
          gradingSource: pending ? null : 'manual',
          wordCount: 120 + i * 3,
          hasDraft: true,
        };
      }
      if (sec.skill === 'speaking' && scores.skillScores?.[sid]) {
        const pending = i % 5 === 1;
        scores.skillScores[sid] = {
          ...scores.skillScores[sid],
          score: pending ? null : round1(randomBetween(5.2, 8.5)),
          status: pending ? 'pending_manual' : 'finalized',
          gradingSource: pending ? null : 'manual',
        };
      }
    }

    const fin = computeFinal(scores.skillScores || {}, scores.grammarScore);
    scores.finalScore = fin.finalScore;
    scores.finalMax = fin.finalMax;
    scores.finalStatus = fin.finalStatus;

    const riskRoll = Math.random();
    const riskLevel = riskRoll < 0.06 ? 'high' : riskRoll < 0.18 ? 'medium' : 'low';

    let gradingState = 'finalized';
    if (scores.finalStatus === 'partial') gradingState = 'pending_manual';
    else if (scores.finalStatus === 'pending') gradingState = 'pending_manual';

    await ExamAttempt.create({
      assignmentId: assignment._id,
      userId: student._id,
      examSnapshot: snapshot,
      status: 'submitted',
      startedAt,
      submittedAt,
      answers,
      scores,
      gradingState,
      resultsReleased: Math.random() > 0.25,
      integrity: {
        riskLevel,
        tabSwitchCount: riskLevel === 'high' ? Math.floor(randomBetween(8, 20)) : Math.floor(randomBetween(0, 3)),
      },
    });
    created += 1;
  }

  return { created, inProgress };
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected to MongoDB (${getMongoUriForLog(uri)})\n`);

  const teacher = await upsertTeacher();
  await cleanupTeacherSeedData(teacher._id);

  const classrooms = await upsertClassrooms(teacher._id);
  const students = await upsertStudents();
  await enrollStudents(classrooms, students);

  const cms = await loadCmsResources();

  const exams = [];
  for (let i = 0; i < EXAM_BLUEPRINTS.length; i += 1) {
    const doc = buildExamDoc(teacher._id, EXAM_BLUEPRINTS[i], cms);
    const exam = await Exam.create(doc);
    exams.push(exam);
    console.log(`📝 Exam: ${exam.title}`);
  }

  let totalAssignments = 0;
  let totalSubmitted = 0;
  let totalInProgress = 0;

  for (let ei = 0; ei < exams.length; ei += 1) {
    const exam = exams[ei];
    const plans = assignmentPlans(ei);
    const classroom = classrooms[ei % classrooms.length];
    const altClassroom = classrooms[(ei + 1) % classrooms.length];

    const targets = [
      { classroom, plans: plans.slice(0, 2) },
      { classroom: altClassroom, plans: [plans[2]].filter(Boolean) },
    ];

    for (const { classroom: room, plans: roomPlans } of targets) {
      for (const plan of roomPlans) {
        const assignment = await ExamAssignment.create({
          examId: exam._id,
          teacherId: teacher._id,
          audience: 'classroom',
          classroomId: room._id,
          mode: plan.mode,
          config: {
            opensAt: plan.opensAt.toISOString(),
            dueAt: plan.dueAt.toISOString(),
            closesAt: plan.closesAt.toISOString(),
            timeLimitSeconds: plan.mode === 'scheduled' ? 3600 : null,
          },
          status: plan.closesAt.getTime() < Date.now() ? 'closed' : 'active',
        });
        totalAssignments += 1;

        const { created, inProgress } = await createAttemptsForAssignment(
          assignment,
          exam,
          students,
          cms
        );
        totalSubmitted += created;
        totalInProgress += inProgress;
        console.log(
          `   📌 ${plan.label} → ${room.name}: ${created} submitted, ${inProgress} in progress`
        );
      }
    }
  }

  console.log('\n========== SEED SUMMARY ==========');
  console.log(`Teacher:     ${teacher.fullName}`);
  console.log(`Email:       ${TEACHER_EMAIL}`);
  console.log(`Password:    ${TEACHER_PASSWORD}`);
  console.log(`Classrooms:  ${classrooms.length}`);
  for (const c of classrooms) {
    console.log(`  - ${c.name} | invite: ${c.inviteCode}`);
  }
  console.log(`Students:    ${students.length} (password Student@123456)`);
  console.log(`Exams:       ${exams.length}`);
  console.log(`Assignments: ${totalAssignments}`);
  console.log(`Attempts:    ${totalSubmitted} submitted, ${totalInProgress} in progress`);
  console.log('==================================\n');
  console.log('Login as teacher → open Schedule & Analytics in sidebar.');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ seedTeacherHoangDongData failed:', e);
  process.exit(1);
});
