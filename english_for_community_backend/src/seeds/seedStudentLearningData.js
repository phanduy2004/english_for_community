/**
 * Seed learning activity for students (app Home/Progress/History + Admin activity views).
 *
 * Prerequisites (recommended order):
 *   npm run seed:admin
 *   npm run seed:teacher-hoangdong   # 15 students + classroom/exams
 *   npm run seed:student-app         # this script
 *
 * Run: npm run seed:student-app
 * Requires MONGO_URI in .env
 */
import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import Listening from '../models/Listening.js';
import Reading from '../models/Reading.js';
import SpeakingSet from '../models/SpeakingSet.js';
import ListeningComprehension from '../models/ListeningComprehension.js';
import WritingTopic from '../models/WritingTopics.js';
import UserDailyProgress from '../models/UserDailyProgress.js';
import DictationAttempt from '../models/DictationAttempt.js';
import Enrollment from '../models/Enrollment.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import ReadingProgress from '../models/ReadingProgress.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import WritingSubmission from '../models/WritingSubmission.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import Word from '../models/Word.js';
import Notification from '../models/Notification.js';
import Report from '../models/Report.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

const SEED_TAG = '[SEED:StudentApp]';
const STUDENT_PASSWORD = process.env.SEED_STUDENT_PASSWORD || 'Student@123456';

const HOANGDONG_STUDENT_EMAILS = [
  'seed.hd.student01@e4c.dev',
  'seed.hd.student02@e4c.dev',
  'seed.hd.student03@e4c.dev',
  'seed.hd.student04@e4c.dev',
  'seed.hd.student05@e4c.dev',
  'seed.hd.student06@e4c.dev',
  'seed.hd.student07@e4c.dev',
  'seed.hd.student08@e4c.dev',
  'seed.hd.student09@e4c.dev',
  'seed.hd.student10@e4c.dev',
  'seed.hd.student11@e4c.dev',
  'seed.hd.student12@e4c.dev',
  'seed.hd.student13@e4c.dev',
  'seed.hd.student14@e4c.dev',
  'seed.hd.student15@e4c.dev',
];

const DEMO_STUDENTS = [
  { fullName: 'Demo Học sinh 01', email: 'seed.demo.student01@e4c.dev', username: 'seed_demo_s01' },
  { fullName: 'Demo Học sinh 02', email: 'seed.demo.student02@e4c.dev', username: 'seed_demo_s02' },
  { fullName: 'Demo Học sinh 03', email: 'seed.demo.student03@e4c.dev', username: 'seed_demo_s03' },
];

const VOCAB_WORDS = [
  { headword: 'achieve', ipa: '/əˈtʃiːv/', shortDefinition: 'đạt được', pos: 'verb', status: 'learning' },
  { headword: 'benefit', ipa: '/ˈbenɪfɪt/', shortDefinition: 'lợi ích', pos: 'noun', status: 'saved' },
  { headword: 'challenge', ipa: '/ˈtʃælɪndʒ/', shortDefinition: 'thử thách', pos: 'noun', status: 'learning' },
  { headword: 'confident', ipa: '/ˈkɒnfɪdənt/', shortDefinition: 'tự tin', pos: 'adj', status: 'saved' },
  { headword: 'develop', ipa: '/dɪˈveləp/', shortDefinition: 'phát triển', pos: 'verb', status: 'recent' },
  { headword: 'efficient', ipa: '/ɪˈfɪʃnt/', shortDefinition: 'hiệu quả', pos: 'adj', status: 'learning' },
  { headword: 'fluent', ipa: '/ˈfluːənt/', shortDefinition: 'trôi chảy', pos: 'adj', status: 'saved' },
  { headword: 'grammar', ipa: '/ˈɡræmə(r)/', shortDefinition: 'ngữ pháp', pos: 'noun', status: 'learning' },
  { headword: 'improve', ipa: '/ɪmˈpruːv/', shortDefinition: 'cải thiện', pos: 'verb', status: 'saved' },
  { headword: 'journey', ipa: '/ˈdʒɜːni/', shortDefinition: 'hành trình', pos: 'noun', status: 'recent' },
  { headword: 'motivation', ipa: '/ˌməʊtɪˈveɪʃn/', shortDefinition: 'động lực', pos: 'noun', status: 'learning' },
  { headword: 'practice', ipa: '/ˈpræktɪs/', shortDefinition: 'luyện tập', pos: 'noun', status: 'saved' },
  { headword: 'pronunciation', ipa: '/prəˌnʌnsiˈeɪʃn/', shortDefinition: 'phát âm', pos: 'noun', status: 'learning' },
  { headword: 'review', ipa: '/rɪˈvjuː/', shortDefinition: 'ôn tập', pos: 'verb', status: 'recent' },
  { headword: 'vocabulary', ipa: '/vəˈkæbjələri/', shortDefinition: 'từ vựng', pos: 'noun', status: 'saved' },
  { headword: 'accurate', ipa: '/ˈækjərət/', shortDefinition: 'chính xác', pos: 'adj', status: 'learning' },
  { headword: 'deadline', ipa: '/ˈdedlaɪn/', shortDefinition: 'hạn chót', pos: 'noun', status: 'recent' },
  { headword: 'feedback', ipa: '/ˈfiːdbæk/', shortDefinition: 'phản hồi', pos: 'noun', status: 'saved' },
  { headword: 'habit', ipa: '/ˈhæbɪt/', shortDefinition: 'thói quen', pos: 'noun', status: 'learning' },
  { headword: 'progress', ipa: '/ˈprəʊɡres/', shortDefinition: 'tiến bộ', pos: 'noun', status: 'saved' },
];

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function ymdOffset(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().slice(0, 10);
}

function dateAtDaysAgo(daysAgo, hour = 10, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, 0, 0);
  return d;
}

/** Thời điểm bài làm — luôn trong 0–5 ngày (app Lịch sử mặc định lọc 7 ngày). */
function recentActivityDate(dayOffset = 1, hour = 14, minute = 0) {
  return dateAtDaysAgo(clamp(dayOffset, 0, 5), hour, minute);
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

async function findUserByEmail(email) {
  const normalized = normalizeEmail(email);
  let user = await User.findOne({ email: normalized });
  if (user) return user;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({ email: new RegExp(`^${escaped}$`, 'i') });
}

async function resolveStudents() {
  const found = [];
  for (const email of HOANGDONG_STUDENT_EMAILS) {
    const u = await findUserByEmail(email);
    if (u) found.push(u);
  }
  if (found.length > 0) {
    console.log(`✅ Found ${found.length} HoangDong seed students`);
    return found;
  }

  console.log('⚠️ No HoangDong students — creating demo student accounts...');
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash(STUDENT_PASSWORD, salt);
  const created = [];
  for (const spec of DEMO_STUDENTS) {
    const email = normalizeEmail(spec.email);
    let u = await findUserByEmail(email);
    if (!u) {
      u = await User.create({
        fullName: spec.fullName,
        username: spec.username,
        email,
        password: hash,
        role: 'user',
        isVerified: true,
        goal: 'IELTS 6.5',
        gender: pick(['male', 'female']),
        cefr: 'B1',
        dateOfBirth: dateAtDaysAgo(6000),
      });
      console.log(`   + Created ${email}`);
    } else {
      u.password = hash;
      u.role = 'user';
      u.isVerified = true;
      u._destroy = false;
      await u.save();
    }
    created.push(u);
  }
  return created;
}

async function ensureMinimalCms() {
  const out = {};

  let listening = await Listening.findOne({
    _destroy: { $ne: true },
    'cues.0': { $exists: true },
  }).sort({ createdAt: -1 });

  if (!listening) {
    listening = await Listening.create({
      code: 'seed_student_app_listening',
      title: `${SEED_TAG} Morning routine dialogue`,
      audioUrl: 'https://res.cloudinary.com/demo/audio/upload/sample.mp3',
      difficulty: 'easy',
      tags: ['seed', 'daily-life'],
      transcript: 'A: Wake up. B: Five more minutes.',
      cues: [
        { startMs: 0, endMs: 3000, spk: 'A', text: 'Wake up, it is time for school.', textNorm: 'wake up it is time for school' },
        { startMs: 3000, endMs: 7000, spk: 'B', text: 'I am so tired. Let me sleep.', textNorm: 'i am so tired let me sleep' },
        { startMs: 7000, endMs: 11000, spk: 'A', text: 'You have to get up now.', textNorm: 'you have to get up now' },
        { startMs: 11000, endMs: 15000, spk: 'B', text: 'Okay, I will get ready.', textNorm: 'okay i will get ready' },
      ],
    });
    console.log(`📻 Created minimal Listening: ${listening.title}`);
  } else {
    console.log(`📻 Using Listening: ${listening.title}`);
  }
  out.listening = listening;

  let reading = await Reading.findOne({
    _destroy: { $ne: true },
    'questions.0': { $exists: true },
  }).sort({ createdAt: -1 });

  if (!reading) {
    reading = await Reading.create({
      title: `${SEED_TAG} Healthy habits passage`,
      summary: 'Short passage about daily habits for seed testing.',
      content:
        'Many students improve their English by practising a little every day. ' +
        'Reading, listening, and speaking together build confidence faster than cramming before exams.',
      difficulty: 'easy',
      minutesToRead: 4,
      questions: [
        {
          questionText: 'What helps students improve faster?',
          options: ['Cramming once a week', 'Daily practice across skills', 'Only grammar drills', 'Avoiding speaking'],
          correctAnswerIndex: 1,
        },
        {
          questionText: 'The passage suggests confidence comes from:',
          options: ['Luck', 'Combined skills practice', 'Skipping homework', 'Memorizing lists only'],
          correctAnswerIndex: 1,
        },
        {
          questionText: '“Cramming” means:',
          options: ['Studying intensely in a short time', 'Sleeping early', 'Travelling abroad', 'Playing sports'],
          correctAnswerIndex: 0,
        },
      ],
    });
    console.log(`📖 Created minimal Reading: ${reading.title}`);
  } else {
    console.log(`📖 Using Reading: ${reading.title}`);
  }
  out.reading = reading;

  let speakingSet = await SpeakingSet.findOne({
    _destroy: { $ne: true },
    'sentences.0': { $exists: true },
    mode: 'readAloud',
  }).sort({ createdAt: -1 });

  if (!speakingSet) {
    speakingSet = await SpeakingSet.create({
      title: `${SEED_TAG} Greetings — Read aloud`,
      description: 'Basic greetings for pronunciation practice.',
      level: 'Beginner',
      mode: 'readAloud',
      sentences: [
        {
          id: 'seed_sent_1',
          order: 1,
          speaker: 'A',
          script: 'Hello, how are you today?',
          phonetic_script: 'həˈloʊ haʊ ɑːr juː təˈdeɪ',
        },
        {
          id: 'seed_sent_2',
          order: 2,
          speaker: 'B',
          script: 'I am fine, thank you.',
          phonetic_script: 'aɪ æm faɪn θæŋk juː',
        },
        {
          id: 'seed_sent_3',
          order: 3,
          speaker: 'A',
          script: 'Let us practice English together.',
          phonetic_script: 'let ʌs ˈpræktɪs ˈɪŋɡlɪʃ təˈɡeðər',
        },
      ],
    });
    console.log(`🗣️ Created minimal SpeakingSet: ${speakingSet.title}`);
  } else {
    console.log(`🗣️ Using SpeakingSet: ${speakingSet.title}`);
  }
  out.speakingSet = speakingSet;

  let listeningComp = await ListeningComprehension.findOne({
    _destroy: { $ne: true },
    'questions.0': { $exists: true },
  }).sort({ createdAt: -1 });

  if (!listeningComp) {
    listeningComp = await ListeningComprehension.create({
      title: `${SEED_TAG} Short announcement`,
      audioUrl: 'https://res.cloudinary.com/demo/audio/upload/sample.mp3',
      transcript: 'Good morning. The library opens at eight AM. Please bring your student ID.',
      difficulty: 'easy',
      questions: [
        {
          questionText: 'The library opens at:',
          options: ['7 AM', '8 AM', '9 AM', '10 AM'],
          correctAnswerIndex: 1,
        },
        {
          questionText: 'Students should bring:',
          options: ['A towel', 'Student ID', 'Sports shoes', 'Lunch box only'],
          correctAnswerIndex: 1,
        },
      ],
    });
    console.log(`🎧 Created minimal ListeningComprehension: ${listeningComp.title}`);
  } else {
    console.log(`🎧 Using ListeningComprehension: ${listeningComp.title}`);
  }
  out.listeningComp = listeningComp;

  let writingTopic = await WritingTopic.findOne({ isActive: true, approvalStatus: 'published' }).sort({ createdAt: -1 });
  if (!writingTopic) {
    writingTopic = await WritingTopic.findOne({ isActive: true }).sort({ createdAt: -1 });
  }
  if (!writingTopic) {
    writingTopic = await WritingTopic.create({
      name: `${SEED_TAG} Technology & Education`,
      isActive: true,
      approvalStatus: 'published',
      aiConfig: {
        language: 'vi-VN',
        taskTypes: ['Discussion', 'Opinion'],
        defaultTaskType: 'Discussion',
        level: 'Intermediate',
        targetWordCount: '250–320',
      },
      stats: { submissionsCount: 0, avgScore: null },
    });
    console.log(`✍️ Created minimal WritingTopic: ${writingTopic.name}`);
  } else {
    console.log(`✍️ Using WritingTopic: ${writingTopic.name}`);
  }
  out.writingTopic = writingTopic;

  return out;
}

async function cleanupLearningData(userIds) {
  const ids = userIds.map((id) => id);
  const del = async (label, promise) => {
    const r = await promise;
    if (r.deletedCount > 0) console.log(`🧹 ${label}: ${r.deletedCount}`);
  };

  await del('UserDailyProgress', UserDailyProgress.deleteMany({ userId: { $in: ids } }));
  await del('DictationAttempt', DictationAttempt.deleteMany({ userId: { $in: ids } }));
  await del('Enrollment', Enrollment.deleteMany({ userId: { $in: ids } }));
  await del('ReadingAttempt', ReadingAttempt.deleteMany({ userId: { $in: ids } }));
  await del('ReadingProgress', ReadingProgress.deleteMany({ userId: { $in: ids } }));
  await del('SpeakingAttempt', SpeakingAttempt.deleteMany({ userId: { $in: ids } }));
  await del('SpeakingEnrollment', SpeakingEnrollment.deleteMany({ userId: { $in: ids } }));
  await del('ListeningCompAttempt', ListeningCompAttempt.deleteMany({ userId: { $in: ids } }));
  await del('Word', Word.deleteMany({ user: { $in: ids } }));
  await del(
    'WritingSubmission (seed)',
    WritingSubmission.deleteMany({ userId: { $in: ids }, 'generatedPrompt.title': { $regex: SEED_TAG } })
  );
  await del(
    'Notifications (seed)',
    Notification.deleteMany({ recipientId: { $in: ids }, title: { $regex: SEED_TAG } })
  );
  await del('Reports (seed)', Report.deleteMany({ title: { $regex: SEED_TAG } }));
}

async function updateUserGamification(user, profile) {
  const { streak, level, points, dailyGoalDone } = profile;
  user.currentStreak = streak;
  user.level = level;
  user.totalPoints = points;
  user.cefr = user.cefr || 'B1';
  user.dailyLessonGoal = 5;
  user.dailyActivityProgress = dailyGoalDone ? clamp(dailyGoalDone, 0, 5) : 0;
  user.dailyProgressDate = ymdOffset(0);
  user.lastActivityDate = dateAtDaysAgo(0, 18, 30);
  await user.save();
}

async function seedDailyProgress(userId, days, intensity = 1) {
  let created = 0;
  for (let d = 0; d < days; d += 1) {
    const date = ymdOffset(d);
    const factor = intensity * (0.6 + (d % 7) * 0.08);
    const studySeconds = Math.floor(900 * factor + (d % 3) * 300);
    const lessons = {
      listening: d % 2 === 0 ? 1 : 0,
      reading: d % 3 === 0 ? 1 : 0,
      speaking: d % 4 === 0 ? 1 : 0,
      writing: d % 5 === 0 ? 1 : 0,
    };
    await UserDailyProgress.findOneAndUpdate(
      { userId, date },
      {
        userId,
        date,
        studySeconds,
        vocabLearned: d % 2 === 0 ? 3 : 1,
        lessonsCompleted: lessons,
        stats: {
          readingAccuracy: { total: 0.72 + (d % 5) * 0.04, count: lessons.reading ? 1 : 0 },
          dictationAccuracy: { total: 0.78 + (d % 4) * 0.03, count: lessons.listening ? 1 : 0 },
          speakingScore: { total: 0.81 + (d % 6) * 0.02, count: lessons.speaking ? 1 : 0 },
          writingScore: { total: 6.5 + (d % 3) * 0.4, count: lessons.writing ? 1 : 0 },
          readingWpm: { total: 110 + d, count: lessons.reading ? 1 : 0 },
        },
      },
      { upsert: true, new: true }
    );
    created += 1;
  }
  return created;
}

async function seedListeningForUser(user, listening, intensity, anchorToday = false) {
  const cues = listening.cues || [];
  const maxCues = clamp(Math.ceil(cues.length * (intensity >= 1 ? 0.8 : 0.4)), 1, cues.length);
  const completedCueIds = [];
  let attempts = 0;

  for (let i = 0; i < maxCues; i += 1) {
    const cue = cues[i];
    const wer = clamp(0.08 + (i % 4) * 0.06 + (user._id.toString().charCodeAt(0) % 10) * 0.01, 0.05, 0.45);
    const passed = wer < 0.25;
    const submittedAt = anchorToday && i === 0
      ? new Date()
      : recentActivityDate(1 + (i % 4), 9 + (i % 4), 15);
    await DictationAttempt.findOneAndUpdate(
      { userId: user._id, listeningId: listening._id, cueIdx: i },
      {
        userId: user._id,
        listeningId: listening._id,
        cueIdx: i,
        userText: passed ? cue.text : 'seed typo answer',
        userTextNorm: passed ? cue.textNorm || cue.text : 'seed typo answer',
        score: {
          wer,
          cer: wer * 0.9,
          correctWords: passed ? 8 : 4,
          totalWords: 10,
          passed,
          thresholdWer: 0.25,
        },
        attemptsCount: 1 + (i % 2),
        durationInSeconds: 45 + i * 8,
        submittedAt,
      },
      { upsert: true }
    );
    attempts += 1;
    if (cue._id) completedCueIds.push(cue._id);
  }

  const progress = maxCues / Math.max(cues.length, 1);
  const activityAt = anchorToday ? new Date() : recentActivityDate(1, 10, 30);
  await Enrollment.findOneAndUpdate(
    { userId: user._id, listeningId: listening._id },
    {
      $set: {
        userId: user._id,
        listeningId: listening._id,
        completedCueIds,
        progress: round2(progress),
        isCompleted: true,
        lastAccessedAt: activityAt,
        updatedAt: activityAt,
      },
    },
    { upsert: true, timestamps: false }
  );

  return attempts;
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

async function seedReadingForUser(user, reading, intensity, anchorToday = false) {
  const questions = reading.questions || [];
  if (questions.length === 0) return 0;

  const answers = questions.map((q, idx) => {
    const correct = Number(q.correctAnswerIndex ?? 0);
    const chosen = intensity >= 1 || idx % 2 === 0 ? correct : correct === 0 ? 1 : 0;
    return {
      questionId: q._id,
      chosenIndex: chosen,
      isCorrect: chosen === correct,
    };
  });
  const correctCount = answers.filter((a) => a.isCorrect).length;
  const score = Math.round((correctCount / questions.length) * 100);
  const submittedAt = anchorToday ? new Date() : recentActivityDate(2, 14, 20);

  await ReadingAttempt.create({
    userId: user._id,
    readingId: reading._id,
    answers,
    score,
    correctCount,
    totalQuestions: questions.length,
    durationInSeconds: 320 + (user._id.toString().length % 40),
    createdAt: submittedAt,
    updatedAt: submittedAt,
  });

  await ReadingProgress.findOneAndUpdate(
    { userId: user._id, readingId: reading._id },
    {
      $set: {
        userId: user._id,
        readingId: reading._id,
        status: 'completed',
        highScore: score,
        attemptsCount: 1,
        lastAttemptedAt: submittedAt,
        updatedAt: submittedAt,
      },
    },
    { upsert: true, timestamps: false }
  );

  return 1;
}

async function seedSpeakingForUser(user, speakingSet, intensity, anchorToday = false) {
  const setId = speakingSet._id;
  const sentences = speakingSet.sentences || [];
  if (sentences.length === 0) return 0;

  const count = clamp(Math.ceil(sentences.length * (intensity >= 1 ? 1 : 0.5)), 1, sentences.length);
  const completedIds = [];

  for (let i = 0; i < count; i += 1) {
    const sent = sentences[i];
    const wer = clamp(0.1 + i * 0.04, 0.08, 0.35);
    await SpeakingAttempt.create({
      userId: user._id,
      speakingSetId: setId,
      sentenceId: sent.id,
      userTranscript: sent.script,
      score: { wer, confidence: 0.92 - wer },
      audioDurationSeconds: 12 + i * 3,
      submittedAt: anchorToday && i === 0
        ? new Date()
        : recentActivityDate(1 + (i % 3), 16, i * 5),
    });
    completedIds.push(sent.id);
  }

  const avgWer =
    completedIds.length > 0
      ? completedIds.reduce((s, _, idx) => s + 0.1 + idx * 0.04, 0) / completedIds.length
      : 0.15;

  const speakAt = anchorToday ? new Date() : recentActivityDate(1, 16, 0);
  await SpeakingEnrollment.findOneAndUpdate(
    { userId: user._id, speakingSetId: setId },
    {
      $set: {
        userId: user._id,
        speakingSetId: setId,
        completedSentenceIds: completedIds,
        progress: round2(count / sentences.length),
        averageWer: round2(avgWer),
        isCompleted: true,
        lastAccessedAt: speakAt,
        updatedAt: speakAt,
      },
    },
    { upsert: true, timestamps: false }
  );

  return count;
}

async function seedWritingForUser(user, writingTopic, intensity, anchorToday = false) {
  const reviewed = intensity >= 1;
  const overall = reviewed ? round2(6.0 + (user._id.toString().charCodeAt(2) % 20) / 10) : null;
  const submittedAt = anchorToday ? new Date() : recentActivityDate(1, 20, 10);

  await WritingSubmission.create({
    userId: user._id,
    topicId: writingTopic._id,
    generatedPrompt: {
      title: `${SEED_TAG} Technology in classrooms`,
      text:
        'Some educators believe technology improves learning outcomes. Others worry it distracts students. ' +
        'Discuss both views and give your own opinion.',
      taskType: 'Discussion',
      level: 'Intermediate',
    },
    content:
      `${SEED_TAG} Essay by ${user.fullName}: Technology can support personalised practice when teachers guide usage. ` +
      'However, screens alone do not replace speaking practice with peers. I believe blended learning works best.',
    wordCount: 68,
    durationInSeconds: 1680,
    status: reviewed ? 'reviewed' : 'submitted',
    submittedAt,
    score: overall,
    feedback: reviewed
      ? {
          overall,
          tr: overall,
          cc: round2(overall - 0.3),
          lr: round2(overall + 0.2),
          gra: round2(overall - 0.1),
          trBullets: ['Clear position in introduction'],
          ccBullets: ['Logical paragraphing'],
          lrBullets: ['Good range of topic vocabulary'],
          graBullets: ['Minor article errors'],
          taskType: 'Discussion',
          evaluatedAt: submittedAt,
        }
      : undefined,
    reviewedAt: reviewed ? submittedAt : undefined,
  });

  return 1;
}

async function seedListeningCompForUser(user, listeningComp, intensity, anchorToday = false) {
  const questions = listeningComp.questions || [];
  if (questions.length === 0) return 0;

  const answers = questions.map((q, idx) => {
    const correct = Number(q.correctAnswerIndex ?? 0);
    const chosen = intensity >= 1 || idx === 0 ? correct : 0;
    return {
      questionId: q._id,
      chosenIndex: chosen,
      isCorrect: chosen === correct,
    };
  });
  const correctCount = answers.filter((a) => a.isCorrect).length;
  const score = Math.round((correctCount / questions.length) * 100);

  await ListeningCompAttempt.create({
    userId: user._id,
    listeningId: listeningComp._id,
    answers,
    score,
    correctCount,
    totalQuestions: questions.length,
    durationInSeconds: 540,
    createdAt: anchorToday ? new Date() : recentActivityDate(3, 11, 0),
    updatedAt: anchorToday ? new Date() : recentActivityDate(3, 11, 0),
  });

  return 1;
}

async function seedVocabularyForUser(user, wordCount) {
  let n = 0;
  for (let i = 0; i < Math.min(wordCount, VOCAB_WORDS.length); i += 1) {
    const w = VOCAB_WORDS[i];
    const reviewOffset = (i % 5) - 2;
    const nextReview = new Date();
    nextReview.setDate(nextReview.getDate() + reviewOffset);
    await Word.findOneAndUpdate(
      { user: user._id, headword: w.headword },
      {
        user: user._id,
        headword: w.headword,
        ipa: w.ipa,
        shortDefinition: w.shortDefinition,
        pos: w.pos,
        status: w.status,
        learningLevel: i % 4,
        nextReviewDate: nextReview,
        lastReviewedDate: dateAtDaysAgo(i % 7),
      },
      { upsert: true }
    );
    n += 1;
  }
  return n;
}

async function seedNotificationsForUser(user, cms) {
  const items = [
    {
      type: 'DAILY_REMINDER',
      title: `${SEED_TAG} Nhắc học hôm nay`,
      message: 'Bạn còn 2 bài trong mục tiêu ngày — hoàn thành để giữ streak!',
      isRead: false,
    },
    {
      type: 'EXAM_ASSIGNED',
      title: `${SEED_TAG} Bài kiểm tra mới`,
      message: 'Giáo viên vừa giao bài trong lớp. Mở mục Lớp học để xem.',
      data: { skill: 'exam' },
      isRead: false,
    },
    {
      type: 'EXAM_RESULTS_RELEASED',
      title: `${SEED_TAG} Đã có điểm bài thi`,
      message: 'Kết quả bài kiểm tra gần nhất đã được phát hành.',
      isRead: true,
    },
    {
      type: 'SYSTEM_ANNOUNCEMENT',
      title: `${SEED_TAG} Chào mừng bạn đến E4C`,
      message: 'Dữ liệu demo đã sẵn sàng — thử Nghe, Đọc, Viết và Tiến độ.',
      isRead: true,
    },
  ];

  let n = 0;
  for (const it of items) {
    const exists = await Notification.findOne({
      recipientId: user._id,
      title: it.title,
    });
    if (exists) continue;
    await Notification.create({
      recipientId: user._id,
      senderId: null,
      type: it.type,
      title: it.title,
      message: it.message,
      data: it.data || {},
      isRead: it.isRead,
      createdAt: dateAtDaysAgo(n % 5, 8 + n, 0),
    });
    n += 1;
  }
  return n;
}

async function seedReportsForAdmin(students) {
  const reporter = students[0];
  if (!reporter) return 0;

  const specs = [
    {
      type: 'bug',
      title: `${SEED_TAG} Audio không phát trên Android 12`,
      description: 'Khi mở bài nghe, nút play đôi khi không phản hồi lần đầu.',
      status: 'pending',
    },
    {
      type: 'improvement',
      title: `${SEED_TAG} Gợi ý thêm filter lịch sử bài tập`,
      description: 'Muốn lọc theo kỹ năng trong màn Lịch sử.',
      status: 'reviewed',
      adminResponse: 'Đã ghi nhận cho sprint sau.',
    },
    {
      type: 'feature',
      title: `${SEED_TAG} Dark mode cho màn đọc`,
      description: 'Đọc ban đêm cần theme tối.',
      status: 'pending',
    },
  ];

  let n = 0;
  for (const s of specs) {
    const exists = await Report.findOne({ title: s.title });
    if (exists) continue;
    await Report.create({
      user: reporter._id,
      type: s.type,
      title: s.title,
      description: s.description,
      status: s.status,
      adminResponse: s.adminResponse,
      deviceInfo: { platform: 'Android', version: '12', device: 'Seed Device' },
      createdAt: dateAtDaysAgo(n + 1, 12, 0),
    });
    n += 1;
  }
  return n;
}

async function seedUserBundle(user, cms, options) {
  const { intensity, progressDays, vocabCount, notify, anchorToday = false } = options;
  const gamification = options.gamification || {
    streak: 7,
    level: 4,
    points: 1800,
    dailyGoalDone: 3,
  };

  await updateUserGamification(user, gamification);
  const dailyRows = await seedDailyProgress(user._id, progressDays, intensity);
  const listeningAttempts = await seedListeningForUser(user, cms.listening, intensity, anchorToday);
  const readingAttempts = await seedReadingForUser(user, cms.reading, intensity, anchorToday);
  const speakingAttempts = await seedSpeakingForUser(user, cms.speakingSet, intensity, anchorToday);
  const writingSubmissions = await seedWritingForUser(user, cms.writingTopic, intensity, anchorToday);
  const compAttempts = await seedListeningCompForUser(user, cms.listeningComp, intensity, anchorToday);
  const vocabWords = await seedVocabularyForUser(user, vocabCount);
  let notifications = 0;
  if (notify) notifications = await seedNotificationsForUser(user, cms);

  return {
    dailyRows,
    listeningAttempts,
    readingAttempts,
    speakingAttempts,
    writingSubmissions,
    compAttempts,
    vocabWords,
    notifications,
  };
}

async function run() {
  const uri = getMongoUri();
  if (!uri) {
    console.error('❌ Missing MONGO_URI in .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log(`🔌 Connected (${getMongoUriForLog(uri)})\n`);

  const students = await resolveStudents();
  const cms = await ensureMinimalCms();
  const userIds = students.map((s) => s._id);

  await cleanupLearningData(userIds);

  const primary = students[0];
  let totals = {
    dailyRows: 0,
    listeningAttempts: 0,
    readingAttempts: 0,
    speakingAttempts: 0,
    writingSubmissions: 0,
    compAttempts: 0,
    vocabWords: 0,
    notifications: 0,
  };

  if (primary) {
    const rich = await seedUserBundle(primary, cms, {
      intensity: 1.2,
      progressDays: 30,
      vocabCount: 20,
      notify: true,
      anchorToday: true,
      gamification: { streak: 14, level: 9, points: 4850, dailyGoalDone: 4 },
    });
    Object.keys(totals).forEach((k) => {
      totals[k] += rich[k] || 0;
    });
    console.log(`⭐ Primary student: ${primary.email} (rich dataset)`);
  }

  for (let i = 1; i < students.length; i += 1) {
    const u = students[i];
    const bundle = await seedUserBundle(u, cms, {
      intensity: 0.7,
      progressDays: 14,
      vocabCount: 10,
      notify: false,
      gamification: {
        streak: 3 + (i % 8),
        level: 2 + (i % 6),
        points: 600 + i * 180,
        dailyGoalDone: 1 + (i % 3),
      },
    });
    Object.keys(totals).forEach((k) => {
      totals[k] += bundle[k] || 0;
    });
  }

  const reports = await seedReportsForAdmin(students);

  console.log('\n========== STUDENT APP SEED SUMMARY ==========');
  console.log(`Tag:              ${SEED_TAG}`);
  console.log(`Students seeded:  ${students.length}`);
  console.log(`Password:         ${STUDENT_PASSWORD}`);
  console.log(`Primary login:    ${primary?.email || '(none)'}`);
  console.log('--- Per skill (approx totals) ---');
  console.log(`Daily progress:   ${totals.dailyRows} rows`);
  console.log(`Dictation cues:   ${totals.listeningAttempts}`);
  console.log(`Reading attempts: ${totals.readingAttempts}`);
  console.log(`Speaking attempts:${totals.speakingAttempts}`);
  console.log(`Writing subs:     ${totals.writingSubmissions}`);
  console.log(`Listening comp:   ${totals.compAttempts}`);
  console.log(`Vocab words:      ${totals.vocabWords}`);
  console.log(`Notifications:    ${totals.notifications} (primary only)`);
  console.log(`Reports (admin):  ${reports}`);
  console.log('\nAdmin console → Activity history / Submissions / Reports');
  console.log('Student app   → Home, Progress chart, Skills history, Vocab, Notifications');
  console.log('==============================================\n');
  console.log('Tip: run `npm run seed:teacher-hoangdong` first for classroom + exam data.');

  await mongoose.connection.close();
  process.exit(0);
}

run().catch((e) => {
  console.error('❌ seedStudentLearningData failed:', e);
  process.exit(1);
});
