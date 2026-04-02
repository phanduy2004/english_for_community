import User from '../models/User.js';
import Report from '../models/Report.js';

// --- MODELS CHO VIỆC TÍNH AI COST (USAGE) ---
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';

// --- MODELS CHO VIỆC TÍNH BÀI HOÀN THÀNH (COMPLETION) ---
import ReadingProgress from '../models/ReadingProgress.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';

import historyService from "./historyService.js";
import ListeningCompAttempt from "../models/ListeningCompAttempt.js";

const AI_PRICING = {
  PER_WORD_WRITING: 0.0005 / 1000,
  PER_SECOND_AUDIO: 0.0004,
};

// --- HELPER FUNCTIONS ---
const getVnDateRange = (range) => {
  const now = new Date();
  const vnOffset = 7 * 60 * 60 * 1000;
  const nowVn = new Date(now.getTime() + vnOffset);

  let startVn = new Date(nowVn);
  let endVn = new Date(nowVn);

  let dateFormat = "%Y-%m-%d";

  endVn.setUTCHours(23, 59, 59, 999);

  if (range === 'day') {
    startVn.setUTCHours(0, 0, 0, 0);
    dateFormat = "%H:00";
  } else if (range === 'week') {
    const day = startVn.getUTCDay();
    const diff = startVn.getUTCDate() - day + (day === 0 ? -6 : 1);
    startVn.setUTCDate(diff);
    startVn.setUTCHours(0, 0, 0, 0);
  } else if (range === 'month') {
    startVn.setUTCDate(startVn.getUTCDate() - 29);
    startVn.setUTCHours(0, 0, 0, 0);
  }

  const startDate = new Date(startVn.getTime() - vnOffset);
  const endDate = new Date(endVn.getTime() - vnOffset);

  const duration = endDate.getTime() - startDate.getTime();
  const previousEndDate = new Date(startDate.getTime() - 1);
  const previousStartDate = new Date(previousEndDate.getTime() - duration);

  return { startDate, endDate, previousStartDate, previousEndDate, dateFormat };
};

const generateChartLabels = (range, startDate, endDate) => {
  const labels = [];
  const vnOffset = 7 * 60 * 60 * 1000;

  let current = new Date(startDate.getTime() + vnOffset);
  const end = new Date(endDate.getTime() + vnOffset);

  if (range === 'day') {
    for (let i = 0; i < 24; i++) {
      labels.push(`${i.toString().padStart(2, '0')}:00`);
    }
  } else {
    current.setUTCHours(0, 0, 0, 0);
    end.setUTCHours(23, 59, 59, 999);

    while (current <= end) {
      const y = current.getUTCFullYear();
      const m = String(current.getUTCMonth() + 1).padStart(2, '0');
      const d = String(current.getUTCDate()).padStart(2, '0');
      labels.push(`${y}-${m}-${d}`);
      current.setUTCDate(current.getUTCDate() + 1);
    }
  }
  return labels;
};

const calculateTrend = (current, previous) => {
  if (previous === 0) return current > 0 ? 100 : 0;
  return Math.round(((current - previous) / previous) * 100);
};

// --- SERVICE METHODS ---

const getDashboardStats = async (range) => {
  const { startDate, endDate, previousStartDate, previousEndDate, dateFormat } = getVnDateRange(range);

  const currentQuery = { $gte: startDate, $lte: endDate };
  const prevQuery = { $gte: previousStartDate, $lte: previousEndDate };

  const matchWriting = { status: { $in: ['submitted', 'reviewed'] } };
  const matchReading = { status: 'completed' };
  const matchSpeaking = { isCompleted: true };
  const matchListening = { isCompleted: true };

  // 🔥 1. METRICS (SUBMISSIONS) - CỘNG THÊM COMPREHENSION
  const [
    curW, curS, curR, curDict, curComp,
    preW, preS, preR, preDict, preComp
  ] = await Promise.all([
    WritingSubmission.countDocuments({ ...matchWriting, submittedAt: currentQuery }),
    SpeakingEnrollment.countDocuments({ ...matchSpeaking, updatedAt: currentQuery }),
    ReadingProgress.countDocuments({ ...matchReading, updatedAt: currentQuery }),
    Enrollment.countDocuments({ ...matchListening, updatedAt: currentQuery }),
    ListeningCompAttempt.countDocuments({ createdAt: currentQuery }), // <-- THÊM MỚI

    WritingSubmission.countDocuments({ ...matchWriting, submittedAt: prevQuery }),
    SpeakingEnrollment.countDocuments({ ...matchSpeaking, updatedAt: prevQuery }),
    ReadingProgress.countDocuments({ ...matchReading, updatedAt: prevQuery }),
    Enrollment.countDocuments({ ...matchListening, updatedAt: prevQuery }),
    ListeningCompAttempt.countDocuments({ createdAt: prevQuery }), // <-- THÊM MỚI
  ]);

  // Gộp Dictation và Comprehension thành tổng môn Listening
  const curL = curDict + curComp;
  const preL = preDict + preComp;

  const totalCurrent = curW + curS + curR + curL;
  const totalPrevious = preW + preS + preR + preL;
  const submissionTrend = calculateTrend(totalCurrent, totalPrevious);

  // 2. AI COST (Giữ nguyên vì Comprehension hiện tại không tốn phí AI generate như Dictation/Speaking)
  const [writingCostAgg, speakingCostAgg, dictationCostAgg] = await Promise.all([
    WritingSubmission.aggregate([
      { $match: { ...matchWriting, createdAt: currentQuery } },
      { $group: { _id: null, totalWords: { $sum: "$wordCount" } } }
    ]),
    SpeakingAttempt.aggregate([
      { $match: { submittedAt: currentQuery } },
      { $group: { _id: null, totalSeconds: { $sum: "$audioDurationSeconds" } } }
    ]),
    DictationAttempt.aggregate([
      { $match: { submittedAt: currentQuery } },
      { $group: { _id: null, totalSeconds: { $sum: "$durationInSeconds" } } }
    ])
  ]);

  const totalWords = writingCostAgg[0]?.totalWords || 0;
  const totalSeconds = (speakingCostAgg[0]?.totalSeconds || 0) + (dictationCostAgg[0]?.totalSeconds || 0);
  const estimatedCost = (totalWords * AI_PRICING.PER_WORD_WRITING) + (totalSeconds * AI_PRICING.PER_SECOND_AUDIO);

  // 3. ACTIVE USERS & REPORTS
  const [activeUsersCount, reportsCount] = await Promise.all([
    User.countDocuments({ lastActivityDate: currentQuery, role: 'user' }),
    Report.countDocuments({ createdAt: currentQuery, status: 'pending' })
  ]);

  // 🔥 4. CHART DATA - GỘP BIỂU ĐỒ DICTATION & COMPREHENSION
  const chartLabels = generateChartLabels(range, startDate, endDate);

  const aggregateChart = async (Model, dateField, extraMatch = {}) => {
    return await Model.aggregate([
      { $match: { [dateField]: currentQuery, ...extraMatch } },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: `$${dateField}`, timezone: "+07:00" } },
          count: { $sum: 1 }
        }
      }
    ]);
  };

  const [writingRaw, speakingRaw, readingRaw, dictationRaw, compreRaw] = await Promise.all([
    aggregateChart(WritingSubmission, 'submittedAt', matchWriting),
    aggregateChart(SpeakingEnrollment, 'updatedAt', matchSpeaking),
    aggregateChart(ReadingProgress, 'updatedAt', matchReading),
    aggregateChart(Enrollment, 'updatedAt', matchListening),
    aggregateChart(ListeningCompAttempt, 'createdAt', {}), // <-- THÊM MỚI
  ]);

  const fillData = (rawData) => chartLabels.map(label => {
    const found = rawData.find(item => item._id === label);
    return found ? found.count : 0;
  });

  // Hàm gộp 2 mảng raw data cho môn Listening
  const fillCombinedData = (raw1, raw2) => chartLabels.map(label => {
    const found1 = raw1.find(item => item._id === label);
    const found2 = raw2.find(item => item._id === label);
    return (found1 ? found1.count : 0) + (found2 ? found2.count : 0);
  });

  return {
    metrics: {
      submissions: {
        value: totalCurrent,
        trend: `${submissionTrend > 0 ? '+' : ''}${submissionTrend}%`,
        trendLabel: range === 'day' ? 'vs yesterday' : 'vs prev period',
        isPositive: submissionTrend >= 0
      },
      aiCost: {
        value: `$${estimatedCost.toFixed(4)}`,
        subLabel: `${totalWords} words • ${Math.round(totalSeconds/60)} mins`
      },
      reports: {
        value: reportsCount,
        status: reportsCount > 0 ? 'New Issues' : 'All Good'
      },
      activeUsers: {
        value: activeUsersCount,
        subLabel: range === 'day' ? 'Active today' : 'Active in period'
      }
    },
    chart: {
      labels: chartLabels,
      writing: fillData(writingRaw),
      speaking: fillData(speakingRaw),
      reading: fillData(readingRaw),
      dictation: fillCombinedData(dictationRaw, compreRaw) // 🔥 Truyền gộp cả 2 mảng vào biểu đồ Listening
    },
    distribution: {
      writing: curW,
      speaking: curS,
      reading: curR,
      dictation: curL // Tổng cả Dictation và Comprehension
    }
  };
};

const getAllUsers = async (page = 1, limit = 20, filter, search) => {
  const skip = (page - 1) * limit;
  let query = { role: 'user' };

  if (search) {
    query.$or = [
      { fullName: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } }
    ];
  }

  if (filter === 'today') {
    const now = new Date();
    const vnTime = new Date(now.getTime() + (7 * 60 * 60 * 1000));
    vnTime.setUTCHours(0, 0, 0, 0);
    const startOfVnDayInUtc = new Date(vnTime.getTime() - (7 * 60 * 60 * 1000));

    query.lastActivityDate = { $gte: startOfVnDayInUtc };
  } else if (filter === 'online') {
    query.isOnline = true;
  }

  const users = await User.find(query)
    .select('-password -refreshToken')
    .sort({ isOnline: -1, lastActivityDate: -1 })
    .skip(skip)
    .limit(limit)
    .lean(); // Dùng lean() để tối ưu object mongoose -> plain JS

  const total = await User.countDocuments(query);

  return {
    users,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
  };
};

const getReports = async (page = 1, limit = 20, status) => {
  const skip = (page - 1) * limit;
  const filter = {};
  if (status) filter.status = status;

  const reports = await Report.find(filter)
    .populate('userId', 'fullName email avatar')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

  const total = await Report.countDocuments(filter);

  return {
    reports,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
  };
};

const updateReportStatus = async (id, status, adminResponse) => {
  const report = await Report.findByIdAndUpdate(
    id,
    { status, adminResponse, updatedAt: new Date() },
    { new: true }
  ).lean();

  if (!report) throw new Error('Report not found');
  return report;
};

const updateUserBanStatus = async (id, banType, durationInHours, reason) => {
  let updateData = {};
  let socketMessage = '';

  if (banType === 'unban') {
    updateData = { isBanned: false, banExpiresAt: null, banReason: '' };
  } else {
    updateData = {
      isBanned: true,
      banReason: reason || 'Vi phạm quy định cộng đồng',
      isOnline: false,
      refreshToken: null
    };

    if (banType === 'permanent') {
      updateData.banExpiresAt = null;
      socketMessage = `Tài khoản của bạn đã bị khóa vĩnh viễn.\nLý do: ${updateData.banReason}`;
    } else {
      const hours = durationInHours || 24;
      const expireDate = new Date();
      expireDate.setHours(expireDate.getHours() + hours);

      updateData.banExpiresAt = expireDate;
      socketMessage = `Tài khoản bị tạm khóa trong ${hours} giờ.\nLý do: ${updateData.banReason}`;
    }
  }

  const user = await User.findByIdAndUpdate(id, updateData, { new: true }).lean();
  if (!user) throw new Error('User not found');

  return { user, socketMessage, banType };
};

const deleteUser = async (id) => {
  const user = await User.findByIdAndDelete(id);
  if (!user) throw new Error('User not found');
  return true;
};

// Uỷ quyền trực tiếp qua historyService
const getActivities = async (userId, startDate, endDate, type) => {
  return await historyService.getHistory(userId, startDate, endDate, type);
};

const getActivityDetail = async (id, type) => {
  return await historyService.getActivityDetail(id, type);
};

export const adminService = {
  getDashboardStats,
  getAllUsers,
  getReports,
  updateReportStatus,
  updateUserBanStatus,
  deleteUser,
  getActivities,
  getActivityDetail
};