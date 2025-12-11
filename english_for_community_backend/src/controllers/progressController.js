import mongoose from 'mongoose';
import User from '../models/User.js';
import UserDailyProgress from '../models/UserDailyProgress.js';

// 🔥 IMPORT CÁC MODELS CẦN THIẾT CHO VIỆC LẤY DATA CHI TIẾT
import ReadingProgress from '../models/ReadingProgress.js';
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';
import Word from '../models/Word.js';

// --- Helper Functions ---

/**
 * Lấy 00:00:00 theo múi giờ của user (Không đổi)
 */
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

/**
 * 🔥 SỬA: Tính toán StartDate và EndDate cho Query Mongoose (Dùng cho getStatDetail)
 * EndDate sẽ là cuối ngày hôm nay (23:59:59.999) theo múi giờ của user.
 */
const _calculateDateRange = (range, timezone) => {
  const now = new Date();
  const userTodayStart = _getStartDateInUserTz(now, timezone);

  let startDate = userTodayStart;

  // 1. Xác định StartDate (00:00:00) theo múi giờ User
  if (range === 'week') {
    // Lấy ngày trong tuần (0: CN, 1: T2, ..., 6: T7)
    const dayOfWeek = userTodayStart.getDay();
    // Mặc định tuần bắt đầu từ T2 (dayOfWeek 1)
    const offset = (dayOfWeek === 0) ? 6 : dayOfWeek - 1;
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
  } else if (range === 'month') {
    const dayOfMonth = userTodayStart.getDate();
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
  }

  // 2. Xác định EndDate (Cuối ngày hôm nay 23:59:59.999)
  const userTomorrowStart = new Date(userTodayStart.getTime() + 24 * 60 * 60 * 1000);
  const endDate = new Date(userTomorrowStart.getTime() - 1); // 23:59:59.999

  return { startDate, endDate };
};

/**
 * 🔥 SỬA CHỮA: Cấu hình dải ngày cho biểu đồ (getProgessSummary)
 */
const _getDateRangeConfig = (range, timezone) => {
  const now = new Date();
  const chartLabels = [];
  const queryDateKeys = []; // Mảng chứa các chuỗi "YYYY-MM-DD" để map vào biểu đồ

  const getDayLabel = (date, tz) => {
    // Lấy nhãn ngày (T2, T3, ...) theo múi giờ user
    const labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    const dayOfWeek = new Date(date.toLocaleString('en-US', { timeZone: tz })).getDay();
    // getDay() trả về 0 cho Chủ Nhật
    const index = (dayOfWeek === 0) ? 0 : dayOfWeek;
    return labels[index];
  };

  // Hàm lấy ngày bắt đầu của ngày hôm nay theo múi giờ user
  const userTodayStart = _getStartDateInUserTz(now, timezone);
  let startDate = userTodayStart;
  let dayCount = 0; // Số ngày cần hiển thị trên biểu đồ

  // --- Logic xác định StartDate và Day Count ---
  if (range === 'month') {
    const dayOfMonth = userTodayStart.getDate();
    startDate = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
    dayCount = dayOfMonth; // Biểu đồ chỉ hiển thị từ ngày 1 đến ngày hôm nay
  } else if (range === 'day') {
    // Biểu đồ vẫn hiện 7 ngày gần nhất (từ 6 ngày trước đến hôm nay)
    startDate = new Date(userTodayStart.getTime() - 6 * 24 * 60 * 60 * 1000);
    dayCount = 7;
  } else {
    // Mặc định: Tuần (Từ thứ 2 hoặc CN tùy logic)
    const dayOfWeek = userTodayStart.getDay();
    const offset = (dayOfWeek === 0) ? 6 : dayOfWeek - 1; // 0=CN -> 6 ngày trước, 1=T2 -> 0 ngày trước
    startDate = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
    dayCount = offset + 1; // Từ ngày bắt đầu tuần đến hôm nay
  }

  // --- Tạo nhãn và key cho biểu đồ ---
  for (let i = 0; i < dayCount; i++) {
    const date = new Date(startDate.getTime() + i * 24 * 60 * 60 * 1000);

    // 🔥 FIX Label: Hiển thị ngày/tháng
    if (range === 'month') {
      // Dùng date.getDate() và date.getMonth() trong múi giờ user để lấy ngày/tháng
      const dateStringInTz = date.toLocaleDateString('en-CA', { timeZone: timezone });
      const [year, month, day] = dateStringInTz.split('-').map(Number);
      chartLabels.push(`${day}/${month}`);
    } else {
      // Dùng nhãn T2, T3, ...
      chartLabels.push(getDayLabel(date, timezone));
    }

    // Key để query DB: YYYY-MM-DD
    queryDateKeys.push(date.toLocaleDateString('en-CA', { timeZone: timezone }));
  }

  return { startDate: userTodayStart, chartLabels, queryDateKeys };
};

// --- Controller Functions ---

const getProgressSummary = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const userId = req.user.id;

    // 1. Lấy User info
    const user = await User.findById(userId).select('dailyMinutes timezone').lean();
    const userTimezone = user?.timezone || 'Asia/Ho_Chi_Minh';
    const dailyGoal = user?.dailyMinutes || 0;

    // 2. Lấy cấu hình ngày tháng (Sử dụng hàm helper đã sửa)
    const { startDate: userTodayStart, chartLabels, queryDateKeys } = _getDateRangeConfig(range, userTimezone);

    // StartDate thực tế cho Stats Grid (Khác với StartDate cho Chart khi range='day')
    let startDateForStats;
    if (range === 'day') {
      startDateForStats = userTodayStart;
    } else if (range === 'week') {
      const dayOfWeek = userTodayStart.getDay();
      const offset = (dayOfWeek === 0) ? 6 : dayOfWeek - 1;
      startDateForStats = new Date(userTodayStart.getTime() - offset * 24 * 60 * 60 * 1000);
    } else { // month
      const dayOfMonth = userTodayStart.getDate();
      startDateForStats = new Date(userTodayStart.getTime() - (dayOfMonth - 1) * 24 * 60 * 60 * 1000);
    }

    // Chuyển startDateForStats sang chuỗi YYYY-MM-DD để so sánh với DB
    const startDateString = startDateForStats.toLocaleDateString('en-CA', { timeZone: userTimezone });
    const todayString = userTodayStart.toLocaleDateString('en-CA', { timeZone: userTimezone }); // Ngày hôm nay theo format DB

    // 3. Query dữ liệu từ bảng UserDailyProgress
    let minQueryDate = queryDateKeys[0]; // Ngày sớm nhất cần cho chart

    const records = await UserDailyProgress.find({
      userId: userId,
      date: { $gte: minQueryDate }
    }).lean();

    // Map dữ liệu để truy xuất nhanh: Key = YYYY-MM-DD
    const recordsMap = new Map(records.map(r => [r.date, r]));

    // 4. Tính toán Stats Grid & Study Time
    let totalSecondsInRange = 0;
    let todayMinutes = 0;

    let vocabSum = 0;
    let lessonsSum = 0;

    const aggs = {
      readingAcc: { total: 0, count: 0 },
      dictationAcc: { total: 0, count: 0 },
      speakingScore: { total: 0, count: 0 },
      writingScore: { total: 0, count: 0 },
      readingWpm: { total: 0, count: 0 },
    };

    // Duyệt qua các record để tính Stats Grid
    records.forEach(rec => {
      // QUAN TRỌNG: Chỉ cộng dồn vào Grid nếu ngày nằm trong phạm vi startDateForStats trở đi.
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
          if (rec.stats.writingScore?.count) { aggs.writingScore.total += rec.stats.writingScore.total; aggs.writingScore.count += rec.stats.writingScore.count; }
          if (rec.stats.readingWpm?.count) { aggs.readingWpm.total += rec.stats.readingWpm.total; aggs.readingWpm.count += rec.stats.readingWpm.count; }
        }
      }

      // Tính riêng cho hôm nay để hiển thị vòng tròn
      if (rec.date === todayString) {
        todayMinutes = Math.round((rec.studySeconds || 0) / 60);
      }
    });

    // 5. Tính toán Weekly/Monthly Chart
    const chartMinutes = queryDateKeys.map(dateKey => {
      const rec = recordsMap.get(dateKey);
      return rec ? Math.round(rec.studySeconds / 60) : 0;
    });

    // 6. Tính trung bình cộng
    const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;

    const statsGrid = {
      vocabLearned: vocabSum,
      lessonsCompleted: lessonsSum,
      readingAccuracy: Math.round(calcAvg(aggs.readingAcc) * 100),
      dictationAccuracy: Math.round(calcAvg(aggs.dictationAcc) * 100),
      speakingAccuracy: Math.round(calcAvg(aggs.speakingScore) * 100),
      avgWritingScore: parseFloat(calcAvg(aggs.writingScore).toFixed(1)),
      readingWpm: Math.round(calcAvg(aggs.readingWpm))
    };

    // 7. Trả về Response
    res.status(200).json({
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
    });

  } catch (error) {
    console.error('Error fetching progress summary:', error);
    res.status(500).json({ message: 'Lỗi server.' });
  }
};

/**
 * 🔥 CONTROLLER MỚI: Lấy danh sách chi tiết các hoạt động theo kỹ năng và phạm vi lọc
 * GET /api/progress/detail?statKey=reading&range=week
 */
const getStatDetail = async (req, res) => {
  try {
    const { statKey, range = 'week' } = req.query;
    const userId = req.user.id;

    const user = await User.findById(userId).select('timezone').lean();
    const userTimezone = user?.timezone || 'Asia/Ho_Chi_Minh';
    // ✅ Dùng _calculateDateRange đã sửa, trả về StartDate và EndDate chuẩn Mongoose Query
    const { startDate, endDate } = _calculateDateRange(range, userTimezone);

    let queryResult = [];
    let isLessonMode = (statKey === 'lessons');

    // --- 1. XỬ LÝ LOGIC QUERY ---

    if (isLessonMode) {
      // === CHẾ ĐỘ LESSONS: Tổng hợp tất cả ===

      // a. Reading (Completed)
      const readings = await ReadingProgress.find({
        userId, status: 'completed', lastAttemptedAt: { $gte: startDate, $lte: endDate }
      }).populate('readingId', 'title').select('lastAttemptedAt readingId highScore').lean();

      readings.forEach(r => queryResult.push({
        original: r, type: 'Reading', date: r.lastAttemptedAt,
        title: r.readingId?.title,
        score: r.highScore || 0
      }));

      // b. Writing (Reviewed)
      const writings = await WritingSubmission.find({
        userId, status: 'reviewed', submittedAt: { $gte: startDate, $lte: endDate }
      }).select('generatedPrompt.title submittedAt score').lean();

      writings.forEach(w => queryResult.push({
        original: w, type: 'Writing', date: w.submittedAt,
        title: w.generatedPrompt?.title,
        score: w.score || 0
      }));

      // c. Speaking (Completed)
      const speakings = await SpeakingEnrollment.find({
        userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
      }).populate('speakingSetId', 'title').select('lastAccessedAt speakingSetId averageWer').lean();

      speakings.forEach(s => queryResult.push({
        original: s, type: 'Speaking', date: s.lastAccessedAt,
        title: s.speakingSetId?.title,
        score: Math.round((1 - (s.averageWer || 0)) * 100)
      }));

      // d. Dictation/Listening (Completed)
      const listenings = await Enrollment.find({
        userId, isCompleted: true, lastAccessedAt: { $gte: startDate, $lte: endDate }
      }).populate('listeningId', 'title').select('lastAccessedAt listeningId progress').lean();

      listenings.forEach(l => queryResult.push({
        original: l, type: 'Dictation/Listening', date: l.lastAccessedAt,
        title: l.listeningId?.title,
        score: Math.round((l.progress || 0) * 100)
      }));

      // Sắp xếp mới nhất trước
      queryResult.sort((a, b) => b.date - a.date);

    } else {
      // === CHẾ ĐỘ CHI TIẾT TỪNG KỸ NĂNG ===
      let model, sortField = 'createdAt', dateFilterField = 'createdAt';
      let populateOpts = null, selectOpts = '';

      switch (statKey) {
        case 'reading':
          model = ReadingProgress;
          dateFilterField = 'lastAttemptedAt';
          sortField = 'lastAttemptedAt';
          populateOpts = { path: 'readingId', select: 'title' };
          selectOpts = 'highScore attemptsCount lastAttemptedAt readingId';
          break;

        case 'speaking':
          model = SpeakingEnrollment;
          dateFilterField = 'lastAccessedAt';
          sortField = 'lastAccessedAt';
          populateOpts = { path: 'speakingSetId', select: 'title' };
          selectOpts = 'averageWer speakingSetId isCompleted lastAccessedAt progress';
          break;

        case 'writing':
          model = WritingSubmission;
          dateFilterField = 'submittedAt';
          sortField = 'submittedAt';
          selectOpts = 'generatedPrompt.title score submittedAt durationInSeconds';
          break;

        case 'dictation':
        case 'listening':
          model = Enrollment;
          dateFilterField = 'lastAccessedAt';
          sortField = 'lastAccessedAt';
          populateOpts = { path: 'listeningId', select: 'title' };
          selectOpts = 'progress isCompleted lastAccessedAt listeningId';
          break;

        case 'vocab':
          model = Word;
          dateFilterField = 'lastReviewedDate';
          sortField = 'lastReviewedDate';
          selectOpts = 'headword shortDefinition status learningLevel lastReviewedDate';
          break;

        default:
          return res.status(400).json({ message: 'Kỹ năng không hợp lệ' });
      }

      let q = model.find({ userId, [dateFilterField]: { $gte: startDate, $lte: endDate } });
      if (populateOpts) q = q.populate(populateOpts);
      queryResult = await q.select(selectOpts).sort({ [sortField]: -1 }).lean();
    }

    // --- 2. ĐỊNH DẠNG DỮ LIỆU TRẢ VỀ ---

    const formattedData = queryResult.map(item => {
      const doc = isLessonMode ? item.original : item;

      // Xác định ngày
      const dateVal = isLessonMode ? item.date : (doc.lastAttemptedAt || doc.submittedAt || doc.lastAccessedAt || doc.lastReviewedDate || doc.createdAt);
      const dateStr = dateVal ? new Date(dateVal).toISOString() : new Date().toISOString();

      const base = {
        id: doc._id,
        date: dateStr,
        duration: 0,
      };

      // A. Logic cho 'lessons' (Tổng hợp)
      if (isLessonMode) {
        return {
          ...base,
          title: item.title || 'Bài học',
          type: item.type,
          score: item.score,
        };
      }

      // B. Logic cho 'reading'
      if (statKey === 'reading') {
        return {
          ...base,
          title: doc.readingId?.title || 'Bài đọc',
          score: doc.highScore || 0,
          attempts: doc.attemptsCount || 0,
          wpm: 0
        };
      }

      // C. Logic cho 'speaking'
      if (statKey === 'speaking') {
        return {
          ...base,
          title: doc.speakingSetId?.title || 'Bài nói',
          score: Math.round((1 - (doc.averageWer || 0)) * 100),
          isCompleted: doc.isCompleted || false
        };
      }

      // D. Logic cho 'writing'
      if (statKey === 'writing') {
        return {
          ...base,
          title: doc.generatedPrompt?.title || 'Bài viết',
          score: doc.score || 0,
          duration: Math.round((doc.durationInSeconds || 0) / 60)
        };
      }

      // E. Logic cho 'dictation'
      if (statKey === 'dictation' || statKey === 'listening') {
        return {
          ...base,
          title: doc.listeningId?.title || 'Bài nghe',
          score: Math.round((doc.progress || 0) * 100),
          isCompleted: doc.isCompleted || false
        };
      }

      // F. Logic cho 'vocab'
      if (statKey === 'vocab') {
        return {
          ...base,
          title: doc.headword,
          subtitle: doc.shortDefinition,
          status: doc.status,
          score: 0
        };
      }

      return base;
    });

    res.status(200).json({ data: formattedData, range });

  } catch (error) {
    console.error('Error fetching stat detail:', error);
    res.status(500).json({ message: 'Lỗi server.' });
  }
};


const getLeaderboard = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    // 1. Lấy danh sách tất cả User (chỉ lấy fields cần thiết để nhẹ DB)
    // Sắp xếp giảm dần theo totalPoints
    const allUsers = await User.find({ role: 'user', isBanned: false })
      .select('_id fullName avatarUrl totalPoints')
      .sort({ totalPoints: -1 })
      .lean();

    // 2. Tìm vị trí (index) của User hiện tại
    const myIndex = allUsers.findIndex(u => u._id.toString() === currentUserId);

    // Nếu user không tìm thấy (trường hợp lạ), trả về list rỗng
    if (myIndex === -1) {
      return res.status(200).json({ leaderboard: [], myRank: 0 });
    }

    const totalDocs = allUsers.length;
    const WINDOW_SIZE = 1; // Lấy trước và sau user 2 người

    // 3. Xác định các nhóm cần lấy
    // A. Nhóm Top đầu (Top 3)
    const topList = allUsers.slice(0, 3);

    // B. Nhóm Xung quanh User
    const startWindow = Math.max(0, myIndex - WINDOW_SIZE);
    const endWindow = Math.min(totalDocs, myIndex + WINDOW_SIZE + 1);
    const neighborList = allUsers.slice(startWindow, endWindow);

    // 4. Gộp danh sách và loại bỏ trùng lặp
    const uniqueMap = new Map();

    [...topList, ...neighborList].forEach(user => {
      uniqueMap.set(user._id.toString(), user);
    });

    // Chuyển về mảng và sắp xếp lại theo điểm (đảm bảo thứ tự đúng)
    const mergedList = Array.from(uniqueMap.values()).sort((a, b) => b.totalPoints - a.totalPoints);

    // 5. Tạo danh sách kết quả cuối cùng (có chèn separator)
    const finalLeaderboard = [];

    for (let i = 0; i < mergedList.length; i++) {
      const user = mergedList[i];

      const realRank = allUsers.findIndex(u => u._id.toString() === user._id.toString()) + 1;

      // Kiểm tra để chèn dấu '...' (Separator)
      if (i > 0) {
        const prevUser = mergedList[i-1];
        const prevUserRank = allUsers.findIndex(u => u._id.toString() === prevUser._id.toString()) + 1;

        if (realRank > prevUserRank + 1) {
          finalLeaderboard.push({ isSeparator: true });
        }
      }

      // Đẩy User vào danh sách
      finalLeaderboard.push({
        id: user._id,
        name: user.fullName,
        avatarUrl: user.avatarUrl || '',
        xp: `${user.totalPoints || 0} XP`, // Format hiển thị
        rank: realRank,
        isMe: user._id.toString() === currentUserId,
        isSeparator: false
      });
    }

    // 6. Xử lý trường hợp separator ở cuối nếu list chỉ có top 3 + user ở xa
    const lastItemRank = finalLeaderboard.length > 0 ? finalLeaderboard[finalLeaderboard.length - 1].rank : 0;
    if (lastItemRank < totalDocs && !finalLeaderboard[finalLeaderboard.length - 1].isSeparator) {
      // Kiểm tra xem có người dùng nào nằm giữa rank cuối cùng và tổng docs không
      if (totalDocs > lastItemRank) {
        // Không cần chèn separator, logic này bị dư
      }
    }


    // Trả về kết quả
    res.status(200).json({
      leaderboard: finalLeaderboard,
      myRank: myIndex + 1,
      totalUsers: totalDocs
    });

  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ message: 'Lỗi server khi tải bảng xếp hạng.' });
  }
};

export const progressController = { getProgressSummary, getStatDetail, getLeaderboard };