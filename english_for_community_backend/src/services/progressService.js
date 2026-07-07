import User from '../models/User.js';
import UserDailyProgress from '../models/UserDailyProgress.js';
import ReadingProgress from '../models/ReadingProgress.js';
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';
import Word from '../models/Word.js';
// 🔥 IMPORT THÊM MODEL MỚI CHO LISTENING COMPREHENSION
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';

// --- Helper Functions ---

const _getStartDateInUserTz = (date, timezone) => {
  const dateStr = date.toLocaleDateString('en-CA', { timeZone: timezone });
  const timeStr = date.toLocaleTimeString('en-GB', { timeZone: timezone, hour: '2-digit', minute: '2-digit', second: '2-digit' });
  const [hour, minute, second] = timeStr.split(':').map(Number);
  const [year, month, day] = dateStr.split('-').map(Number);

  const startOfUtcDay = Date.UTC(year, month - 1, day);
  const nowUtc = Date.UTC(year, month - 1, day, hour, minute, second);
  const nowServer = date.getTime();
  const offsetMs = nowUtc - nowServer;

  return new Date(startOfUtcDay - offsetMs);
}

// Lấy thứ trong tuần (0=CN) và ngày trong tháng THEO timezone user, không phụ thuộc
// TZ của server host. getDay()/getDate() thô đọc theo TZ host → lệch 1 ngày trên host UTC.
const _userWeekdayAndDate = (instant, timezone) => {
  const local = new Date(instant.toLocaleString('en-US', { timeZone: timezone }));
  return { weekday: local.getDay(), dayOfMonth: local.getDate() };
};

const _calculateDateRange = (range, timezone) => {
  const now = new Date();
  const userTodayStart = _getStartDateInUserTz(now, timezone);

  let startDate = userTodayStart;

  // "day" tab chart = 7 ngày — detail log phải khớp (trước đây chỉ hôm nay → list trống dù stats có %).
  if (range === 'day') {
    startDate = new Date(userTodayStart.getTime() - 6 * 24 * 60 * 60 * 1000);
  } else if (range === 'week') {
    const { weekday } = _userWeekdayAndDate(userTodayStart, timezone);
    const offset = (weekday === 0) ? 6 : weekday - 1;
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
  } else if (range === 'month') {
    const { dayOfMonth } = _userWeekdayAndDate(userTodayStart, timezone);
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
  }

  const userTomorrowStart = new Date(userTodayStart.getTime() + 24 * 60 * 60 * 1000);
  const endDate = new Date(userTomorrowStart.getTime() - 1);

  return { startDate, endDate };
};

const _getDateRangeConfig = (range, timezone) => {
  const now = new Date();
  const chartLabels = [];
  const queryDateKeys = [];

  const getDayLabel = (date, tz) => {
    const labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    const dayOfWeek = new Date(date.toLocaleString('en-US', { timeZone: tz })).getDay();
    const index = (dayOfWeek === 0) ? 0 : dayOfWeek;
    return labels[index];
  };

  const userTodayStart = _getStartDateInUserTz(now, timezone);
  let startDate = userTodayStart;
  let dayCount = 0;

  if (range === 'month') {
    const { dayOfMonth } = _userWeekdayAndDate(userTodayStart, timezone);
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
    dayCount = dayOfMonth;
  } else if (range === 'day') {
    startDate = new Date(userTodayStart.getTime() - 6 * 24 * 60 * 60 * 1000);
    dayCount = 7;
  } else {
    const dayOfWeek = new Date(userTodayStart.toLocaleString('en-US', { timeZone: timezone })).getDay();
    const offset = (dayOfWeek === 0) ? 6 : dayOfWeek - 1;
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
    dayCount = offset + 1;
  }

  for (let i = 0; i < dayCount; i++) {
    const date = new Date(startDate.getTime() + i * 24 * 60 * 60 * 1000);
    if (range === 'month') {
      const dateStringInTz = date.toLocaleDateString('en-CA', { timeZone: timezone });
      const [year, month, day] = dateStringInTz.split('-').map(Number);
      chartLabels.push(`${day}/${month}`);
    } else {
      chartLabels.push(getDayLabel(date, timezone));
    }
    queryDateKeys.push(date.toLocaleDateString('en-CA', { timeZone: timezone }));
  }

  return { startDate: userTodayStart, chartLabels, queryDateKeys };
};

// --- Service Methods ---

const getSummaryData = async (userId, range) => {
  const user = await User.findById(userId).select('dailyMinutes timezone').lean();
  const userTimezone = user?.timezone || 'Asia/Ho_Chi_Minh';
  const dailyGoal = user?.dailyMinutes || 0;

  const { startDate: userTodayStart, chartLabels, queryDateKeys } = _getDateRangeConfig(range, userTimezone);

  const todayString = userTodayStart.toLocaleDateString('en-CA', { timeZone: userTimezone });
  // Stats 'day' = chỉ hôm nay; 'week'/'month' = từ đầu range. Dùng queryDateKeys[0]
  // (đã tz-correct từ _getDateRangeConfig) để stats KHỚP với chart, tránh lệch 1 ngày
  // trên host UTC do getDay()/getDate() thô đọc theo TZ server.
  const startDateString = range === 'day' ? todayString : queryDateKeys[0];

  let minQueryDate = queryDateKeys[0];

  const records = await UserDailyProgress.find({
    userId: userId,
    date: { $gte: minQueryDate }
  }).lean();

  const recordsMap = new Map(records.map(r => [r.date, r]));

  let totalSecondsInRange = 0;
  let todayMinutes = 0;
  let vocabSum = 0;
  let lessonsSum = 0;

  const aggs = {
    readingAcc: { total: 0, count: 0 },
    dictationAcc: { total: 0, count: 0 },
    speakingScore: { total: 0, count: 0 },
    speakingFluency: { total: 0, count: 0 },
    writingScore: { total: 0, count: 0 },
    readingWpm: { total: 0, count: 0 },
  };

  records.forEach(rec => {
    if (rec.date >= startDateString) {
      totalSecondsInRange += (rec.studySeconds || 0);
      vocabSum += (rec.vocabLearned || 0);

      lessonsSum += (rec.lessonsCompleted?.listening || 0) +
        (rec.lessonsCompleted?.reading || 0) +
        (rec.lessonsCompleted?.speaking || 0) +
        (rec.lessonsCompleted?.writing || 0);

      if (rec.stats) {
        if (rec.stats.readingAccuracy?.count) { aggs.readingAcc.total += rec.stats.readingAccuracy.total; aggs.readingAcc.count += rec.stats.readingAccuracy.count; }
        if (rec.stats.dictationAccuracy?.count) { aggs.dictationAcc.total += rec.stats.dictationAccuracy.total; aggs.dictationAcc.count += rec.stats.dictationAccuracy.count; }
        if (rec.stats.speakingScore?.count) { aggs.speakingScore.total += rec.stats.speakingScore.total; aggs.speakingScore.count += rec.stats.speakingScore.count; }
        if (rec.stats.speakingFluency?.count) { aggs.speakingFluency.total += rec.stats.speakingFluency.total; aggs.speakingFluency.count += rec.stats.speakingFluency.count; }
        if (rec.stats.writingScore?.count) { aggs.writingScore.total += rec.stats.writingScore.total; aggs.writingScore.count += rec.stats.writingScore.count; }
        if (rec.stats.readingWpm?.count) { aggs.readingWpm.total += rec.stats.readingWpm.total; aggs.readingWpm.count += rec.stats.readingWpm.count; }
      }
    }

    if (rec.date === todayString) {
      todayMinutes = Math.round((rec.studySeconds || 0) / 60);
    }
  });

  const chartMinutes = queryDateKeys.map(dateKey => {
    const rec = recordsMap.get(dateKey);
    return rec ? Math.round(rec.studySeconds / 60) : 0;
  });

  const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;

  const statsGrid = {
    vocabLearned: vocabSum,
    lessonsCompleted: lessonsSum,
    readingAccuracy: Math.round(calcAvg(aggs.readingAcc) * 100),
    dictationAccuracy: Math.round(calcAvg(aggs.dictationAcc) * 100),
    speakingAccuracy: Math.round(calcAvg(aggs.speakingScore) * 100),
    speakingFluency: Math.round(calcAvg(aggs.speakingFluency) * 100),
    avgWritingScore: parseFloat(calcAvg(aggs.writingScore).toFixed(1)),
    readingWpm: Math.round(calcAvg(aggs.readingWpm))
  };

  return {
    studyTime: {
      todayMinutes: todayMinutes,
      totalMinutesInRange: Math.round(totalSecondsInRange / 60),
      goalMinutes: dailyGoal,
      progressPercent: dailyGoal > 0 ? Math.min(1, todayMinutes / dailyGoal) : 0,
    },
    statsGrid,
    weeklyChart: {
      labels: chartLabels,
      minutes: chartMinutes,
    },
    callout: {
      title: todayMinutes >= (dailyGoal || 30) ? 'Great job!' : 'Keep going!',
      message: `You've studied ${todayMinutes} minutes today.`,
    }
  };
};

const getStatDetailData = async (userId, statKey, range) => {
  const user = await User.findById(userId).select('timezone').lean();
  const userTimezone = user?.timezone || 'Asia/Ho_Chi_Minh';
  const { startDate, endDate } = _calculateDateRange(range, userTimezone);

  let queryResult = [];
  let isLessonMode = (statKey === 'lessons');

  if (isLessonMode) {
    const readings = await ReadingProgress.find({
      userId, status: 'completed', lastAttemptedAt: { $gte: startDate, $lte: endDate }
    }).populate('readingId', 'title').select('lastAttemptedAt readingId highScore').lean();
    readings.forEach(r => queryResult.push({ original: r, type: 'Reading', date: r.lastAttemptedAt, title: r.readingId?.title, score: r.highScore || 0 }));

    const writings = await WritingSubmission.find({
      userId, status: 'reviewed', submittedAt: { $gte: startDate, $lte: endDate }
    }).select('generatedPrompt.title submittedAt score').lean();
    writings.forEach(w => queryResult.push({ original: w, type: 'Writing', date: w.submittedAt, title: w.generatedPrompt?.title, score: w.score || 0 }));

    const speakings = await SpeakingEnrollment.find({
      userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
    }).populate('speakingSetId', 'title').select('lastAccessedAt speakingSetId averageWer').lean();
    speakings.forEach(s => queryResult.push({ original: s, type: 'Speaking', date: s.lastAccessedAt, title: s.speakingSetId?.title, score: Math.round((1 - (s.averageWer || 0)) * 100) }));

    // 🔥 1. GỘP CẢ DICTATION VÀ COMPREHENSION VÀO "LISTENING" TRONG CHẾ ĐỘ LESSONS
    const dictations = await Enrollment.find({
      userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('lastAccessedAt listeningId progress').lean();
    dictations.forEach(l => queryResult.push({ original: l, type: 'Dictation', date: l.lastAccessedAt, title: l.listeningId?.title, score: Math.round((l.progress || 0) * 100) }));

    const comprehensions = await ListeningCompAttempt.find({
      userId, createdAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('createdAt listeningId score').lean();
    comprehensions.forEach(c => queryResult.push({ original: c, type: 'Comprehension', date: c.createdAt, title: c.listeningId?.title, score: Math.round(c.score || 0) }));

    queryResult.sort((a, b) => b.date - a.date);

  } else if (statKey === 'dictation' || statKey === 'listening') {
    // 🔥 2. NẾU LỌC RIÊNG MÔN LISTENING -> KẾT HỢP CẢ 2 BẢNG VÀO CHUNG 1 LIST
    const dictations = await Enrollment.find({
      userId, lastAccessedAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('progress isCompleted lastAccessedAt listeningId').lean();

    const comprehensions = await ListeningCompAttempt.find({
      userId, createdAt: { $gte: startDate, $lte: endDate }
    }).populate('listeningId', 'title').select('score isCompleted createdAt listeningId').lean();

    // Dán nhãn _type để lúc format dễ xử lý
    queryResult = [
      ...dictations.map(d => ({ ...d, _type: 'dictation' })),
      ...comprehensions.map(c => ({ ...c, _type: 'comprehension' }))
    ];

    // Sắp xếp gộp 2 loại giảm dần theo thời gian
    queryResult.sort((a, b) => {
      const dateA = a._type === 'dictation' ? a.lastAccessedAt : a.createdAt;
      const dateB = b._type === 'dictation' ? b.lastAccessedAt : b.createdAt;
      return new Date(dateB) - new Date(dateA);
    });

  } else {
    // 3. CÁC MÔN CÒN LẠI (GIỮ NGUYÊN)
    let model, sortField = 'createdAt', dateFilterField = 'createdAt';
    let populateOpts = null, selectOpts = '';

    switch (statKey) {
      case 'reading':
        model = ReadingProgress;
        dateFilterField = 'lastAttemptedAt';
        sortField = 'lastAttemptedAt';
        populateOpts = { path: 'readingId', select: 'title' };
        selectOpts = 'highScore attemptsCount lastAttemptedAt readingId status';
        break;
      case 'speaking':
        model = SpeakingEnrollment; dateFilterField = 'lastAccessedAt'; sortField = 'lastAccessedAt'; populateOpts = { path: 'speakingSetId', select: 'title' }; selectOpts = 'averageWer speakingSetId isCompleted lastAccessedAt progress'; break;
      case 'writing':
        model = WritingSubmission; dateFilterField = 'submittedAt'; sortField = 'submittedAt'; selectOpts = 'generatedPrompt.title score submittedAt durationInSeconds'; break;
      case 'vocab':
        model = Word; dateFilterField = 'lastReviewedDate'; sortField = 'lastReviewedDate'; selectOpts = 'headword shortDefinition status learningLevel lastReviewedDate'; break;
      default:
        const err = new Error('Kỹ năng không hợp lệ');
        err.statusCode = 400;
        throw err;
    }

    const baseFilter = { userId, [dateFilterField]: { $gte: startDate, $lte: endDate } };
    if (statKey === 'reading') {
      baseFilter.status = 'completed';
    }
    if (statKey === 'speaking') {
      baseFilter.isCompleted = true;
    }
    if (statKey === 'writing') {
      baseFilter.status = { $in: ['submitted', 'reviewed'] };
    }

    let q = model.find(baseFilter);
    if (populateOpts) q = q.populate(populateOpts);
    queryResult = await q.select(selectOpts).sort({ [sortField]: -1 }).lean();
  }

  // --- 2. ĐỊNH DẠNG DỮ LIỆU TRẢ VỀ ---

  const formattedData = queryResult.map(item => {
    const doc = isLessonMode ? item.original : item;
    const dateVal = isLessonMode ? item.date : (doc.lastAttemptedAt || doc.submittedAt || doc.lastAccessedAt || doc.lastReviewedDate || doc.createdAt);
    const dateStr = dateVal ? new Date(dateVal).toISOString() : new Date().toISOString();

    const base = { id: doc._id, date: dateStr, duration: 0 };

    if (isLessonMode) return { ...base, title: item.title || 'Bài học', type: item.type, score: item.score };
    if (statKey === 'reading') return { ...base, title: doc.readingId?.title || 'Bài đọc', score: doc.highScore || 0, attempts: doc.attemptsCount || 0, wpm: 0 };
    if (statKey === 'speaking') return { ...base, title: doc.speakingSetId?.title || 'Bài nói', score: Math.round((1 - (doc.averageWer || 0)) * 100), isCompleted: doc.isCompleted || false };
    if (statKey === 'writing') return { ...base, title: doc.generatedPrompt?.title || 'Bài viết', score: doc.score || 0, duration: Math.round((doc.durationInSeconds || 0) / 60) };

    // 🔥 4. FORMAT CHO DICTATION HOẶC COMPREHENSION KHI LỌC 'listening'
    if (statKey === 'dictation' || statKey === 'listening') {
      const isDict = doc._type === 'dictation';
      const actualDate = isDict ? doc.lastAccessedAt : doc.createdAt;
      return {
        ...base,
        date: actualDate ? new Date(actualDate).toISOString() : base.date,
        title: doc.listeningId?.title || 'Bài nghe',
        score: isDict ? Math.round((doc.progress || 0) * 100) : Math.round(doc.score || 0),
        isCompleted: isDict ? (doc.isCompleted || false) : true, // Comprehension mặc định là true vì đã nộp bài
        type: isDict ? 'Dictation' : 'Comprehension' // Đẩy thêm type để UI trên Mobile có thể phân biệt nếu muốn
      };
    }

    if (statKey === 'vocab') return { ...base, title: doc.headword, subtitle: doc.shortDefinition, status: doc.status, score: 0 };

    return base;
  });

  return { data: formattedData, range };
};

const getLeaderboardData = async (currentUserId) => {
  const allUsers = await User.find({ role: 'user', isBanned: false })
    .select('_id fullName avatarUrl totalPoints')
    .sort({ totalPoints: -1 })
    .lean();

  const myIndex = allUsers.findIndex(u => u._id.toString() === currentUserId);

  if (myIndex === -1) {
    return { leaderboard: [], myRank: 0, totalUsers: allUsers.length };
  }

  const totalDocs = allUsers.length;
  const WINDOW_SIZE = 1;

  const topList = allUsers.slice(0, 3);
  const startWindow = Math.max(0, myIndex - WINDOW_SIZE);
  const endWindow = Math.min(totalDocs, myIndex + WINDOW_SIZE + 1);
  const neighborList = allUsers.slice(startWindow, endWindow);

  const uniqueMap = new Map();
  [...topList, ...neighborList].forEach(user => uniqueMap.set(user._id.toString(), user));

  const mergedList = Array.from(uniqueMap.values()).sort((a, b) => b.totalPoints - a.totalPoints);
  const finalLeaderboard = [];

  for (let i = 0; i < mergedList.length; i++) {
    const user = mergedList[i];
    const realRank = allUsers.findIndex(u => u._id.toString() === user._id.toString()) + 1;

    if (i > 0) {
      const prevUser = mergedList[i-1];
      const prevUserRank = allUsers.findIndex(u => u._id.toString() === prevUser._id.toString()) + 1;
      if (realRank > prevUserRank + 1) {
        finalLeaderboard.push({ isSeparator: true });
      }
    }

    finalLeaderboard.push({
      id: user._id,
      name: user.fullName,
      avatarUrl: user.avatarUrl || '',
      xp: `${user.totalPoints || 0} XP`,
      rank: realRank,
      isMe: user._id.toString() === currentUserId,
      isSeparator: false
    });
  }

  return { leaderboard: finalLeaderboard, myRank: myIndex + 1, totalUsers: totalDocs };
};

export const progressService = {
  getSummaryData,
  getStatDetailData,
  getLeaderboardData
};
