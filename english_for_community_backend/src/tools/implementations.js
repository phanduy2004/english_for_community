import mongoose from 'mongoose';
import UserDailyProgress from '../models/UserDailyProgress.js';
import Word from '../models/Word.js';
import ReadingProgress from '../models/ReadingProgress.js';
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';
import Reading from '../models/Reading.js';
import Listening from '../models/Listening.js';
import SpeakingSet from '../models/SpeakingSet.js';
import User from '../models/User.js';
import { toSpeakingSetObjectId } from '../lib/speakingSetId.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import historyService from '../services/historyService.js';
import {
  isPlainYmd,
  utcRangeForCalendarDate,
  addCalendarDays,
} from '../utils/localDayBounds.js';

// ========================================
// HELPER FUNCTIONS
// ========================================
const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;
const formatScore = (val) => (val === undefined || val === null) ? 'N/A' : val;
const formatPercent = (val) => Math.round(val * 100) + '%';
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id); // 🔥 NEW: Validate ID

/** Thứ Hai = 0 … Chủ nhật = 6 (theo lịch trong timezone user). */
const mondayOffsetFromYmd = (ymd, tz) => {
  const r = utcRangeForCalendarDate(ymd, tz);
  if (!r) return 0;
  const t = r.start.getTime() + 12 * 3600000;
  const short = new Intl.DateTimeFormat('en-US', { timeZone: tz, weekday: 'short' }).format(new Date(t));
  const map = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5, Sun: 6 };
  const key = short.slice(0, 3);
  return map[key] !== undefined ? map[key] : 0;
};

/** Thứ Hai–Chủ nhật của tuần dương lịch liền trước tuần hiện tại (không gồm hôm nay / tuần này). */
const lastFullCalendarWeekYmd = (todayYmd, tz) => {
  const off = mondayOffsetFromYmd(todayYmd, tz);
  const mondayThisWeek = addCalendarDays(todayYmd, -off);
  const mondayLastWeek = addCalendarDays(mondayThisWeek, -7);
  const sundayLastWeek = addCalendarDays(mondayLastWeek, 6);
  return { startDate: mondayLastWeek, endDate: sundayLastWeek };
};

/** Khoảng YYYY-MM-DD theo timezone user (không dùng giờ máy chủ). */
const resolveZonedRangeYmd = async (userId, range) => {
  const user = await User.findById(userId).select('timezone').lean();
  const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
  const todayYmd = new Date().toLocaleDateString('en-CA', { timeZone: tz });

  if (range === 'day') {
    return { startDate: todayYmd, endDate: todayYmd, timezone: tz, todayYmd };
  }
  if (range === 'week') {
    return {
      startDate: addCalendarDays(todayYmd, -6),
      endDate: todayYmd,
      timezone: tz,
      todayYmd,
    };
  }
  if (range === 'last_week') {
    const { startDate, endDate } = lastFullCalendarWeekYmd(todayYmd, tz);
    return { startDate, endDate, timezone: tz, todayYmd };
  }
  if (range === 'month') {
    return {
      startDate: `${todayYmd.slice(0, 7)}-01`,
      endDate: todayYmd,
      timezone: tz,
      todayYmd,
    };
  }
  return {
    startDate: addCalendarDays(todayYmd, -6),
    endDate: todayYmd,
    timezone: tz,
    todayYmd,
  };
};

const normalizePeriodArg = (range) => {
  if (range === 'today') return 'day';
  if (range === 'last_week') return 'last_week';
  if (range === 'day' || range === 'week' || range === 'month') return range;
  return 'week';
};

export const toolImplementations = {

  // ========================================
  // 1. LỊCH SỬ HỌC TẬP TỔNG QUAN
  // ========================================
  get_learning_history: async (userId, args) => {
    const { startDate, endDate } = args;
    console.log(`🛠️ Tool: get_learning_history (${startDate} -> ${endDate})`);

    if (!isPlainYmd(startDate) || !isPlainYmd(endDate)) {
      return {
        error:
          'startDate và endDate bắt buộc dạng YYYY-MM-DD. Với "hôm nay/tuần này/tháng này" hãy dùng get_daily_activity hoặc get_learning_history_period để server tự lấy ngày đúng theo múi giờ user.',
      };
    }

    const records = await UserDailyProgress.find({
      userId,
      date: { $gte: startDate, $lte: endDate }
    }).lean();

    if (!records.length) return "Không có dữ liệu học tập nào trong khoảng thời gian này.";

    let totalSeconds = 0;
    let totalVocab = 0;
    let totalLessons = 0;

    const aggs = {
      readingAcc: { total: 0, count: 0 },
      dictationAcc: { total: 0, count: 0 },
      speakingScore: { total: 0, count: 0 },
      writingScore: { total: 0, count: 0 },
    };

    records.forEach(rec => {
      totalSeconds += (rec.studySeconds || 0);
      totalVocab += (rec.vocabLearned || 0);

      if (rec.lessonsCompleted) {
        totalLessons += (rec.lessonsCompleted.listening || 0) +
          (rec.lessonsCompleted.reading || 0) +
          (rec.lessonsCompleted.speaking || 0) +
          (rec.lessonsCompleted.writing || 0);
      }

      if (rec.stats) {
        if (rec.stats.readingAccuracy?.count) { aggs.readingAcc.total += rec.stats.readingAccuracy.total; aggs.readingAcc.count += rec.stats.readingAccuracy.count; }
        if (rec.stats.dictationAccuracy?.count) { aggs.dictationAcc.total += rec.stats.dictationAccuracy.total; aggs.dictationAcc.count += rec.stats.dictationAccuracy.count; }
        if (rec.stats.speakingScore?.count) { aggs.speakingScore.total += rec.stats.speakingScore.total; aggs.speakingScore.count += rec.stats.speakingScore.count; }
        if (rec.stats.writingScore?.count) { aggs.writingScore.total += rec.stats.writingScore.total; aggs.writingScore.count += rec.stats.writingScore.count; }
      }
    });

    return {
      period: `${startDate} đến ${endDate}`,
      summary: {
        total_minutes: Math.round(totalSeconds / 60),
        total_lessons_completed: totalLessons,
        total_vocab_learned: totalVocab,
      },
      average_scores: {
        reading_accuracy: Math.round(calcAvg(aggs.readingAcc) * 100) + '%',
        listening_accuracy: Math.round(calcAvg(aggs.dictationAcc) * 100) + '%',
        speaking_accuracy: Math.round(calcAvg(aggs.speakingScore) * 100) + '%',
        writing_score: parseFloat(calcAvg(aggs.writingScore).toFixed(1))
      },
    };
  },

  /**
   * Tổng quan UserDailyProgress theo today/week/month — không cần model tự đoán ngày.
   */
  get_learning_history_period: async (userId, args) => {
    const range = normalizePeriodArg(args.range || 'week');
    const { startDate, endDate, timezone } = await resolveZonedRangeYmd(userId, range);
    console.log(`🛠️ Tool: get_learning_history_period (${range} → ${startDate}..${endDate}, ${timezone})`);
    return toolImplementations.get_learning_history(userId, { startDate, endDate });
  },

  /**
   * Danh sách bài đã làm trong MỘT ngày dương lịch (theo timezone user), khớp màn Progress app.
   */
  get_daily_activity: async (userId, args) => {
    const user = await User.findById(userId).select('timezone').lean();
    const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
    const ymd =
      args.date && isPlainYmd(args.date)
        ? args.date
        : new Date().toLocaleDateString('en-CA', { timeZone: tz });
    console.log(`🛠️ Tool: get_daily_activity (${ymd}, tz=${tz})`);

    const rec = await UserDailyProgress.findOne({ userId, date: ymd }).lean();
    const activities = await historyService.getHistory(userId.toString(), ymd, ymd, null);

    const lc = rec?.lessonsCompleted;
    const lessonsSum = lc
      ? (lc.listening || 0) + (lc.reading || 0) + (lc.speaking || 0) + (lc.writing || 0)
      : 0;

    return {
      date: ymd,
      timezone_used: tz,
      user_daily_progress: rec
        ? {
            study_minutes: Math.round((rec.studySeconds || 0) / 60),
            vocab_learned: rec.vocabLearned || 0,
            lessons_completed_by_skill: {
              listening: lc?.listening || 0,
              reading: lc?.reading || 0,
              speaking: lc?.speaking || 0,
              writing: lc?.writing || 0,
            },
            lessons_completed_sum: lessonsSum,
          }
        : null,
      activity_count: activities.length,
      activities: activities.map((a) => ({
        type: a.type,
        sub_type: a.subType,
        title: a.title,
        score: a.score,
        completed_at: a.date,
      })),
      note:
        'activity_count là số hoạt động trong ngày (mỗi reading/speaking/writing/listening là một dòng). lessons_completed_sum đếm theo log ngày (có thể khác nếu một bài được cập nhật nhiều lần).',
    };
  },

  // ========================================
  // 2. CHI TIẾT SPEAKING
  // ========================================
  get_speaking_details: async (userId, args) => {
    const limit = args.limit || 5;
    const mode = args.mode;
    console.log(`🛠️ Tool: get_speaking_details (limit ${limit}, mode: ${mode})`);

    const query = { userId: userId, isCompleted: true };

    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      const user = await User.findById(userId).select('timezone').lean();
      const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
      const a = utcRangeForCalendarDate(args.startDate, tz);
      const b = utcRangeForCalendarDate(args.endDate, tz);
      if (a && b) {
        const rStart = a.start < b.start ? a.start : b.start;
        const rEnd = a.end > b.end ? a.end : b.end;
        query.lastAccessedAt = { $gte: rStart, $lte: rEnd };
      }
    }

    const fetchCap =
      isPlainYmd(args.startDate) && isPlainYmd(args.endDate) ? 80 : limit;

    const items = await SpeakingEnrollment.find(query)
      .populate('speakingSetId', 'title mode level')
      .sort({ lastAccessedAt: -1 })
      .limit(fetchCap)
      .lean();

    if (!items.length) return "Bạn chưa hoàn thành bài Nói nào.";

    let filtered = mode && mode !== 'all'
      ? items.filter(item => item.speakingSetId?.mode === mode)
      : items;

    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      filtered = filtered.slice(0, limit);
    }

    return {
      total: filtered.length,
      exercises: filtered.map(item => ({
        date: item.lastAccessedAt ? new Date(item.lastAccessedAt).toLocaleDateString('vi-VN') : 'N/A',
        topic: item.speakingSetId?.title || "Bài nói",
        mode: item.speakingSetId?.mode || "N/A",
        level: item.speakingSetId?.level || "N/A",
        accuracy: formatPercent(1 - (item.averageWer || 0)), // Điểm Accuracy
      }))
    };
  },

  // ========================================
  // 3. CHI TIẾT READING
  // ========================================
  get_reading_details: async (userId, args) => {
    const limit = args.limit || 5;
    const difficulty = args.difficulty;
    console.log(`🛠️ Tool: get_reading_details (limit ${limit})`);

    const q = { userId: userId, status: 'completed' };
    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      const user = await User.findById(userId).select('timezone').lean();
      const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
      const a = utcRangeForCalendarDate(args.startDate, tz);
      const b = utcRangeForCalendarDate(args.endDate, tz);
      if (a && b) {
        const rStart = a.start < b.start ? a.start : b.start;
        const rEnd = a.end > b.end ? a.end : b.end;
        q.lastAttemptedAt = { $gte: rStart, $lte: rEnd };
      }
    }

    const items = await ReadingProgress.find(q)
      .populate('readingId', 'title difficulty')
      .sort({ lastAttemptedAt: -1 })
      .limit(isPlainYmd(args.startDate) && isPlainYmd(args.endDate) ? 80 : limit)
      .lean();

    if (!items.length) return "Bạn chưa hoàn thành bài Đọc nào.";

    let filtered = difficulty && difficulty !== 'all'
      ? items.filter(item => item.readingId?.difficulty === difficulty)
      : items;

    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      filtered = filtered.slice(0, limit);
    }

    return {
      total: filtered.length,
      exercises: filtered.map(item => ({
        date: item.lastAttemptedAt ? new Date(item.lastAttemptedAt).toLocaleDateString('vi-VN') : 'N/A',
        title: item.readingId?.title || "Bài đọc",
        difficulty: item.readingId?.difficulty || "N/A",
        // highScore trong DB là 0-100, giữ nguyên
        score: formatScore(item.highScore) + '%',
        attempts: item.attemptsCount || 1
      }))
    };
  },

  // ========================================
  // 4. CHI TIẾT WRITING (FIX: Bỏ chi tiết Feedback)
  // ========================================
  get_writing_details: async (userId, args) => {
    const limit = args.limit || 5;
    const topicId = args.topicId;
    console.log(`🛠️ Tool: get_writing_details (limit ${limit})`);

    const query = { userId: userId, status: { $in: ['submitted', 'reviewed'] } };
    if (topicId && isValidObjectId(topicId)) { // Validate topicId
      query.topicId = topicId;
    }

    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      const user = await User.findById(userId).select('timezone').lean();
      const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
      const a = utcRangeForCalendarDate(args.startDate, tz);
      const b = utcRangeForCalendarDate(args.endDate, tz);
      if (a && b) {
        const rStart = a.start < b.start ? a.start : b.start;
        const rEnd = a.end > b.end ? a.end : b.end;
        query.submittedAt = { $gte: rStart, $lte: rEnd };
      }
    }

    const items = await WritingSubmission.find(query)
      // CHỈ LẤY CÁC FIELD CẦN THIẾT
      .select('generatedPrompt.title generatedPrompt.taskType submittedAt score durationInSeconds wordCount feedback.generalComment')
      .sort({ submittedAt: -1 })
      .limit(isPlainYmd(args.startDate) && isPlainYmd(args.endDate) ? 80 : limit)
      .lean();

    if (!items.length) return "Bạn chưa nộp bài Viết nào.";

    const capped = isPlainYmd(args.startDate) && isPlainYmd(args.endDate)
      ? items.slice(0, limit)
      : items;

    return {
      total: capped.length,
      exercises: capped.map(item => {
        const isReviewed = item.score !== undefined && item.score !== null;
        return {
          date: item.submittedAt ? new Date(item.submittedAt).toLocaleDateString('vi-VN') : 'N/A',
          topic: item.generatedPrompt?.title || "Bài viết tự do",
          task_type: item.generatedPrompt?.taskType || "N/A",
          word_count: item.wordCount || 0,
          duration_minutes: item.durationInSeconds ? Math.round(item.durationInSeconds / 60) : 0,
          score: isReviewed ? item.score : "Đang chấm",
          feedback_summary: isReviewed ? (item.feedback?.generalComment || "Không có nhận xét") : "Chưa có",
        };
      })
    };
  },

  // ========================================
  // 5. CHI TIẾT LISTENING/DICTATION
  // ========================================
  get_listening_details: async (userId, args) => {
    const limit = args.limit || 5;
    console.log(`🛠️ Tool: get_listening_details (limit ${limit})`);

    const q = { userId: userId, isCompleted: true };
    if (isPlainYmd(args.startDate) && isPlainYmd(args.endDate)) {
      const user = await User.findById(userId).select('timezone').lean();
      const tz = user?.timezone || 'Asia/Ho_Chi_Minh';
      const a = utcRangeForCalendarDate(args.startDate, tz);
      const b = utcRangeForCalendarDate(args.endDate, tz);
      if (a && b) {
        const rStart = a.start < b.start ? a.start : b.start;
        const rEnd = a.end > b.end ? a.end : b.end;
        q.lastAccessedAt = { $gte: rStart, $lte: rEnd };
      }
    }

    const items = await Enrollment.find(q)
      .populate('listeningId', 'title difficulty')
      .sort({ lastAccessedAt: -1 })
      .limit(isPlainYmd(args.startDate) && isPlainYmd(args.endDate) ? 80 : limit)
      .lean();

    if (!items.length) return "Bạn chưa hoàn thành bài Nghe nào.";

    const capped = isPlainYmd(args.startDate) && isPlainYmd(args.endDate)
      ? items.slice(0, limit)
      : items;

    return {
      total: capped.length,
      exercises: capped.map(item => ({
        date: item.lastAccessedAt ? new Date(item.lastAccessedAt).toLocaleDateString('vi-VN') : 'N/A',
        title: item.listeningId?.title || "Bài nghe",
        difficulty: item.listeningId?.difficulty || "N/A",
        accuracy: formatPercent(item.progress || 0)
      }))
    };
  },

  // ========================================
  // 6 & 7 (Vocab - Giữ nguyên logic)
  // ========================================
  get_vocab_list: async (userId, args) => {
    const status = args.status || 'learning';
    const limit = args.limit || 10;

    const words = await Word.find({ user: userId, status: status })
      .sort({ updatedAt: -1 })
      .limit(limit)
      .select('headword shortDefinition learningLevel pos')
      .lean();

    if (!words.length) return `Không có từ vựng nào có trạng thái '${status}'.`;

    return {
      count: words.length,
      list: words.map(w => ({
        word: w.headword, meaning: w.shortDefinition, level: w.learningLevel, part_of_speech: w.pos || "N/A"
      }))
    };
  },
  get_vocab_review: async (userId, args) => {
    const limit = args.limit || 20;
    console.log(`🛠️ Tool: get_vocab_review (limit ${limit})`);

    const words = await Word.find({
      user: userId, status: 'learning', nextReviewDate: { $lte: new Date() }
    })
      .sort({ nextReviewDate: 1 })
      .limit(limit)
      .select('headword shortDefinition learningLevel pos')
      .lean();

    if (!words.length) return "Bạn không có từ nào cần ôn tập hôm nay. Tuyệt vời!";

    return {
      count: words.length,
      message: `Bạn có ${words.length} từ cần ôn tập hôm nay`,
      list: words.map(w => ({
        word: w.headword, meaning: w.shortDefinition, level: w.learningLevel, part_of_speech: w.pos || "N/A"
      }))
    };
  },

  // ========================================
  // 8. THỐNG KÊ THEO KỸ NĂNG (Giữ nguyên logic)
  // ========================================
  get_skill_statistics: async (userId, args) => {
    const { skill, range = 'week' } = args;
    const period = normalizePeriodArg(range);
    console.log(`🛠️ Tool: get_skill_statistics (${skill}, ${period})`);

    const { startDate, endDate, timezone } = await resolveZonedRangeYmd(userId, period);

    const records = await UserDailyProgress.find({ userId, date: { $gte: startDate, $lte: endDate } }).lean();

    if (!records.length) return `Không có dữ liệu cho kỹ năng ${skill} trong khoảng thời gian này.`;

    let stats = {
      skill: skill,
      period: `${startDate} đến ${endDate}`,
      timezone_used: timezone,
      total_sessions: 0, average_score: 0, lessons_completed: 0
    };

    const scoreAgg = { total: 0, count: 0 };
    records.forEach(rec => {
      // ... (rest of aggregation logic remains the same)
      const skillKey = skill === 'vocab' ? 'vocabulary' : skill;
      if (rec.lessonsCompleted && rec.lessonsCompleted[skillKey]) {
        stats.lessons_completed += rec.lessonsCompleted[skillKey];
      }

      if (rec.stats) {
        let skillStat = null;
        if (skill === 'reading' && rec.stats.readingAccuracy) { skillStat = rec.stats.readingAccuracy; }
        else if (skill === 'listening' && rec.stats.dictationAccuracy) { skillStat = rec.stats.dictationAccuracy; }
        else if (skill === 'speaking' && rec.stats.speakingScore) { skillStat = rec.stats.speakingScore; }
        else if (skill === 'writing' && rec.stats.writingScore) { skillStat = rec.stats.writingScore; }

        if (skillStat && skillStat.count) {
          scoreAgg.total += skillStat.total;
          scoreAgg.count += skillStat.count;
          stats.total_sessions += skillStat.count;
        }
      }
    });

    stats.average_score = scoreAgg.count > 0
      ? (skill === 'writing' ? parseFloat((scoreAgg.total / scoreAgg.count).toFixed(1)) : Math.round((scoreAgg.total / scoreAgg.count) * 100) + '%')
      : 'N/A';

    return stats;
  },

  // ========================================
  // 9 & 10 (Leaderboard / Exercises - Giữ nguyên logic)
  // ========================================
  get_leaderboard: async (userId, args) => {
    console.log(`🛠️ Tool: get_leaderboard`);

    const allUsers = await User.find({ role: 'user', isBanned: false })
      .select('_id fullName avatarUrl totalPoints')
      .sort({ totalPoints: -1 })
      .limit(10)
      .lean();

    const myIndex = allUsers.findIndex(u => u._id.toString() === userId);
    const myRank = myIndex + 1;

    return {
      my_rank: myRank > 0 ? myRank : 'Chưa có trong top 10',
      top_users: allUsers.map((user, index) => ({
        rank: index + 1, name: user.fullName, points: user.totalPoints || 0, is_me: user._id.toString() === userId
      }))
    };
  },
  get_exercises_by_difficulty: async (userId, args) => {
    const { skill, difficulty, limit = 5 } = args;
    console.log(`🛠️ Tool: get_exercises_by_difficulty (${skill}, ${difficulty})`);

    let Model, progressModel, query;
    if (skill === 'reading') { Model = Reading; progressModel = ReadingProgress; query = { difficulty: difficulty }; }
    else if (skill === 'listening') { Model = Listening; progressModel = Enrollment; query = { difficulty: difficulty }; }
    else if (skill === 'speaking') { Model = SpeakingSet; progressModel = SpeakingEnrollment; query = { level: difficulty }; }
    else { return "Kỹ năng không hợp lệ"; }

    const allExercises = await Model.find(query).select('_id title').limit(limit * 2).lean();

    const completedIds = await progressModel.find({ userId, isCompleted: true })
      .select(skill === 'reading' ? 'readingId' : skill === 'listening' ? 'listeningId' : 'speakingSetId').lean();

    const completedSet = new Set(
      completedIds.map(p => (p.readingId || p.listeningId || p.speakingSetId).toString())
    );

    const recommended = allExercises
      .filter(ex => !completedSet.has(ex._id.toString()))
      .slice(0, limit);

    if (!recommended.length) {
      return `Bạn đã hoàn thành tất cả bài ${skill} ở độ khó ${difficulty}. Tuyệt vời!`;
    }

    return {
      skill: skill, difficulty: difficulty, count: recommended.length,
      exercises: recommended.map(ex => ({ id: ex._id.toString(), title: ex.title }))
    };
  },

  // ========================================
  // 11. PHÂN TÍCH ĐIỂM YẾU (Giữ nguyên logic)
  // ========================================
  analyze_weaknesses: async (userId, args) => {
    const { range = 'week' } = args;
    const period = normalizePeriodArg(range);
    console.log(`🛠️ Tool: analyze_weaknesses (${period})`);

    const user = await User.findById(userId).select('timezone dailyMinutes').lean();
    const { startDate, endDate, timezone } = await resolveZonedRangeYmd(userId, period);

    const records = await UserDailyProgress.find({ userId, date: { $gte: startDate, $lte: endDate } }).lean();

    if (!records.length) return "Không đủ dữ liệu để phân tích điểm yếu.";

    // ... (rest of calculation logic remains the same)
    const skills = {
      reading: { total: 0, count: 0, lessons: 0 },
      listening: { total: 0, count: 0, lessons: 0 },
      speaking: { total: 0, count: 0, lessons: 0 },
      writing: { total: 0, count: 0, lessons: 0 }
    };

    records.forEach(rec => {
      // ... (aggregation logic remains the same)
      if (rec.stats) {
        if (rec.stats.readingAccuracy?.count) { skills.reading.total += rec.stats.readingAccuracy.total; skills.reading.count += rec.stats.readingAccuracy.count; }
        if (rec.stats.dictationAccuracy?.count) { skills.listening.total += rec.stats.dictationAccuracy.total; skills.listening.count += rec.stats.dictationAccuracy.count; }
        if (rec.stats.speakingScore?.count) { skills.speaking.total += rec.stats.speakingScore.total; skills.speaking.count += rec.stats.speakingScore.count; }
        if (rec.stats.writingScore?.count) { skills.writing.total += rec.stats.writingScore.total; skills.writing.count += rec.stats.writingScore.count; }
      }

      if (rec.lessonsCompleted) {
        skills.reading.lessons += rec.lessonsCompleted.reading || 0;
        skills.listening.lessons += rec.lessonsCompleted.listening || 0;
        skills.speaking.lessons += rec.lessonsCompleted.speaking || 0;
        skills.writing.lessons += rec.lessonsCompleted.writing || 0;
      }
    });

    const analysis = [];

    Object.entries(skills).forEach(([skill, data]) => {
      const avgScore = data.count > 0 ? (data.total / data.count) : null;
      const isWeak = avgScore !== null && avgScore < 0.7;
      const isNeglected = data.lessons === 0;

      if (isWeak || isNeglected) {
        analysis.push({
          skill: skill,
          issue: isNeglected ? 'Chưa luyện tập' : 'Điểm số thấp',
          average_score: avgScore !== null ? Math.round(avgScore * 100) + '%' : 'N/A',
          lessons_done: data.lessons,
          recommendation: isNeglected ? `Bạn nên bắt đầu luyện tập ${skill}` : `Điểm ${skill} của bạn còn thấp, cần tập trung cải thiện`
        });
      }
    });

    if (analysis.length === 0) { return "Bạn đang học tập rất tốt, không có điểm yếu nào đáng kể!"; }

    return { period: `${startDate} đến ${endDate}`, timezone_used: timezone, weaknesses: analysis };
  },

  // ========================================
  // 12. CHI TIẾT MỘT BÀI HỌC CỤ THỂ (FIX: Validate ID)
  // ========================================
  get_lesson_detail: async (userId, args) => {
    const { lessonType, lessonId } = args;
    console.log(`🛠️ Tool: get_lesson_detail (${lessonType}, ${lessonId})`);

    // 🔥 FIX 3: Validate ID để tránh lỗi CastError
    if (!isValidObjectId(lessonId)) {
      return { error: `ID bài học (${lessonId}) không hợp lệ (Không phải ObjectId).` };
    }

    let lesson, attempts;
    if (lessonType === 'reading') {
      lesson = await Reading.findById(lessonId).select('title difficulty questions').lean();
      attempts = await ReadingAttempt.find({ userId, readingId: lessonId })
        .sort({ createdAt: -1 }).limit(5).lean();

      if (!lesson) return "Không tìm thấy bài đọc này.";

      return {
        title: lesson.title, difficulty: lesson.difficulty, total_questions: lesson.questions?.length || 0,
        attempts: attempts.map(att => ({
          date: new Date(att.createdAt).toLocaleDateString('vi-VN'),
          score: att.score + '%',
          correct: att.correctCount,
          total: att.totalQuestions,
          duration_minutes: Math.round(att.durationInSeconds / 60)
        }))
      };

    } else if (lessonType === 'listening') {
      // ... (rest of listening logic remains the same)
      lesson = await Listening.findById(lessonId).select('title difficulty totalCues').lean();
      if (!lesson) return "Không tìm thấy bài nghe này.";
      const enrollment = await Enrollment.findOne({ userId, listeningId: lessonId }).lean();
      return {
        title: lesson.title, difficulty: lesson.difficulty, total_cues: lesson.totalCues || 0,
        progress: enrollment ? formatPercent(enrollment.progress || 0) : '0%',
        is_completed: enrollment?.isCompleted || false
      };

    } else if (lessonType === 'speaking') {
      // ... (rest of speaking logic remains the same)
      lesson = await SpeakingSet.findById(lessonId).select('title mode level sentences').lean();
      if (!lesson) return "Không tìm thấy bài nói này.";
      const enrollment = await SpeakingEnrollment.findOne({
        userId,
        speakingSetId: toSpeakingSetObjectId(lessonId),
      }).lean();
      return {
        title: lesson.title, mode: lesson.mode, level: lesson.level, total_sentences: lesson.sentences?.length || 0,
        progress: enrollment ? formatPercent(enrollment.progress || 0) : '0%',
        is_completed: enrollment?.isCompleted || false,
        average_wer: enrollment ? formatPercent(enrollment.averageWer || 0) : 'N/A'
      };
    }

    return "Loại bài học không hợp lệ.";
  }
};