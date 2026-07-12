import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { progressService } from './progressService.js';
import User from '../models/User.js';
import UserDailyProgress from '../models/UserDailyProgress.js';
import Word from '../models/Word.js';
import ReadingProgress from '../models/ReadingProgress.js';
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import SpeakingConversation from '../models/SpeakingConversation.js';
import Enrollment from '../models/Enrollment.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';

// Test end-to-end getSummaryData / getStatDetailData với model Mongoose được MOCK
// (không cần DB) — phủ F2 (vocab distinct), F5 (progressPercent theo range), fix
// vocab-detail (`user` thay vì `userId`) và F6 (card "Bài học" == số dòng danh sách,
// dùng chung _fetchCompletedLessons). `t.mock.method` auto-restore sau mỗi test.

// Chain giả cho .find().populate().select().sort().lean() theo mọi thứ tự.
const leanChain = (rows) => {
  const c = { populate: () => c, select: () => c, sort: () => c, lean: async () => rows };
  return c;
};

// Mock 5 model nguồn "bài học" (_fetchCompletedLessons). Mặc định rỗng.
const mockLessons = (t, { readings = [], writings = [], speakings = [], freeSpeakings = [], dictations = [], comps = [] } = {}) => {
  t.mock.method(ReadingProgress, 'find', () => leanChain(readings));
  t.mock.method(WritingSubmission, 'find', () => leanChain(writings));
  t.mock.method(SpeakingEnrollment, 'find', () => leanChain(speakings));
  t.mock.method(SpeakingConversation, 'find', () => leanChain(freeSpeakings));
  t.mock.method(Enrollment, 'find', () => leanChain(dictations));
  t.mock.method(ListeningCompAttempt, 'find', () => leanChain(comps));
};

const TZ = 'Asia/Ho_Chi_Minh';
const todayKey = () => new Date().toLocaleDateString('en-CA', { timeZone: TZ });
// Số ngày đã trôi trong tuần theo tz (Mon=1 … Sun=7) — khớp _getDateRangeConfig backend.
const weekElapsed = () => {
  const dow = new Date(new Date().toLocaleString('en-US', { timeZone: TZ })).getDay();
  return dow === 0 ? 7 : dow;
};

const mockUser = (t, dailyMinutes) =>
  t.mock.method(User, 'findById', () => ({
    select: () => ({ lean: async () => ({ dailyMinutes, timezone: TZ }) }),
  }));

const mockRecords = (t, records) =>
  t.mock.method(UserDailyProgress, 'find', () => ({ lean: async () => records }));

describe('getSummaryData — F2 vocab distinct + F5 progressPercent (mock models)', () => {
  it('F2: vocabLearned lấy từ Word.countDocuments (distinct), filter dùng `user`+status learning', async (t) => {
    mockUser(t, 30);
    // vocabLearned:99 trong record = reps CŨ — phải bị override bởi countDocuments.
    mockRecords(t, [
      { date: todayKey(), studySeconds: 900, vocabLearned: 99, stats: {} },
    ]);
    let captured = null;
    t.mock.method(Word, 'countDocuments', async (filter) => {
      captured = filter;
      return 5;
    });
    mockLessons(t);

    const res = await progressService.getSummaryData('u1', 'day');

    assert.equal(res.statsGrid.vocabLearned, 5); // distinct, KHÔNG phải 99 reps
    assert.equal(captured.user, 'u1'); // field `user`
    assert.equal(captured.userId, undefined); // KHÔNG dùng userId
    assert.equal(captured.status, 'learning');
  });

  it("F5: 'day' → progressPercent = todayMinutes / dailyGoal", async (t) => {
    mockUser(t, 30);
    mockRecords(t, [{ date: todayKey(), studySeconds: 900, vocabLearned: 0, stats: {} }]); // 15 phút
    t.mock.method(Word, 'countDocuments', async () => 0);
    mockLessons(t);

    const res = await progressService.getSummaryData('u1', 'day');
    assert.equal(res.studyTime.todayMinutes, 15);
    assert.equal(res.studyTime.progressPercent, 0.5); // 15 / (30 × 1)
  });

  it("F5: 'week' → chia cho dailyGoal × số ngày đã trôi (mẫu số ≥ 'day')", async (t) => {
    mockUser(t, 30);
    // chỉ có dữ liệu hôm nay (15 phút) trong tuần
    mockRecords(t, [{ date: todayKey(), studySeconds: 900, vocabLearned: 0, stats: {} }]);
    t.mock.method(Word, 'countDocuments', async () => 0);
    mockLessons(t);

    const res = await progressService.getSummaryData('u1', 'week');
    const expected = Math.min(1, 15 / (30 * weekElapsed()));
    assert.ok(
      Math.abs(res.studyTime.progressPercent - expected) < 1e-9,
      `progressPercent=${res.studyTime.progressPercent} kỳ vọng=${expected}`,
    );
    // Mẫu số tuần ≥ ngày ⇒ % tuần ≤ % ngày (0.5)
    assert.ok(res.studyTime.progressPercent <= 0.5 + 1e-9);
  });
});

describe('getStatDetailData — vocab detail dùng field `user` (fix list rỗng)', () => {
  it('filter vocab: `user` (không userId) + status learning', async (t) => {
    t.mock.method(User, 'findById', () => ({
      select: () => ({ lean: async () => ({ timezone: TZ }) }),
    }));
    let captured = null;
    t.mock.method(Word, 'find', (filter) => {
      captured = filter;
      return { select: () => ({ sort: () => ({ lean: async () => [] }) }) };
    });

    const res = await progressService.getStatDetailData('u1', 'vocab', 'week');

    assert.equal(captured.user, 'u1');
    assert.equal(captured.userId, undefined);
    assert.equal(captured.status, 'learning');
    assert.deepEqual(res.data, []);
  });
});

describe('F6 — card "Bài học hoàn thành" == số dòng danh sách (dùng chung nguồn)', () => {
  const D = () => new Date();
  const lessonsFixture = {
    readings: [{ _id: 'r1', lastAttemptedAt: D(), readingId: { title: 'R1' }, highScore: 80 }],
    writings: [{ _id: 'w1', submittedAt: D(), generatedPrompt: { title: 'W1' }, score: 7 }],
    comps: [{ _id: 'c1', createdAt: D(), listeningId: { title: 'C1' }, score: 90 }],
  };

  it('card lessonsCompleted = số doc bài học thật (KHÔNG dùng counter reps)', async (t) => {
    mockUser(t, 30);
    // counter reps = 99×4 = 396 trong record — PHẢI bị override bởi _fetchCompletedLessons.
    mockRecords(t, [{
      date: todayKey(), studySeconds: 0, vocabLearned: 0,
      lessonsCompleted: { listening: 99, reading: 99, speaking: 99, writing: 99 }, stats: {},
    }]);
    t.mock.method(Word, 'countDocuments', async () => 0);
    mockLessons(t, lessonsFixture); // 1 reading + 1 writing + 1 comprehension = 3

    const res = await progressService.getSummaryData('u1', 'week');
    assert.equal(res.statsGrid.lessonsCompleted, 3); // = số dòng list, KHÔNG phải 396
  });

  it('getStatDetailData(lessons) trả đúng số dòng = con số card', async (t) => {
    t.mock.method(User, 'findById', () => ({
      select: () => ({ lean: async () => ({ timezone: TZ }) }),
    }));
    mockLessons(t, lessonsFixture);

    const res = await progressService.getStatDetailData('u1', 'lessons', 'week');
    assert.equal(res.data.length, 3); // khớp card ở test trên (cùng _fetchCompletedLessons)
  });
});
