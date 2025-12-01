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
import {getIO} from "../socket/socketManager.js"; // Listening Enrollment

const AI_PRICING = {
  PER_WORD_WRITING: 0.0005 / 1000,
  PER_SECOND_AUDIO: 0.0004,
};

// --- HELPER: Timezone VN ---
const getVnDateRange = (range) => {
  const now = new Date();
  // UTC + 7 hours
  const vnOffset = 7 * 60 * 60 * 1000;
  const nowVn = new Date(now.getTime() + vnOffset);

  let startVn = new Date(nowVn);
  let endVn = new Date(nowVn);

  let dateFormat = "%Y-%m-%d";

  // Cuối ngày hôm nay (VN)
  endVn.setUTCHours(23, 59, 59, 999);

  if (range === 'day') {
    // --- SỬA LẠI: Thống kê theo giờ trong ngày hôm nay ---
    startVn.setUTCHours(0, 0, 0, 0);
    dateFormat = "%H:00"; // Group theo giờ (00:00, 01:00...)
  }
  else if (range === 'week') {
    // Tuần: Từ thứ 2
    const day = startVn.getUTCDay();
    const diff = startVn.getUTCDate() - day + (day === 0 ? -6 : 1);
    startVn.setUTCDate(diff);
    startVn.setUTCHours(0, 0, 0, 0);
  }
  else if (range === 'month') {
    // Tháng: 30 ngày trượt
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

// Helper: Generate Labels
const generateChartLabels = (range, startDate, endDate) => {
  const labels = [];
  const vnOffset = 7 * 60 * 60 * 1000;

  let current = new Date(startDate.getTime() + vnOffset);
  const end = new Date(endDate.getTime() + vnOffset);

  if (range === 'day') {
    // --- SỬA LẠI: Loop 24 giờ ---
    for (let i = 0; i < 24; i++) {
      labels.push(`${i.toString().padStart(2, '0')}:00`);
    }
  } else {
    // Loop theo ngày
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

// --- MAIN CONTROLLER ---

const getDashboardStats = async (req, res) => {
  try {
    const { range = 'week' } = req.query;

    const { startDate, endDate, previousStartDate, previousEndDate, dateFormat } = getVnDateRange(range);

    const currentQuery = { $gte: startDate, $lte: endDate };
    const prevQuery = { $gte: previousStartDate, $lte: previousEndDate };

    const matchWriting = { status: { $in: ['submitted', 'reviewed'] } };
    const matchReading = { status: 'completed' };
    const matchSpeaking = { isCompleted: true };
    const matchListening = { isCompleted: true };

    // 1. METRICS
    const [
      curW, curS, curR, curL,
      preW, preS, preR, preL
    ] = await Promise.all([
      WritingSubmission.countDocuments({ ...matchWriting, submittedAt: currentQuery }),
      SpeakingEnrollment.countDocuments({ ...matchSpeaking, updatedAt: currentQuery }),
      ReadingProgress.countDocuments({ ...matchReading, updatedAt: currentQuery }),
      Enrollment.countDocuments({ ...matchListening, updatedAt: currentQuery }),

      WritingSubmission.countDocuments({ ...matchWriting, submittedAt: prevQuery }),
      SpeakingEnrollment.countDocuments({ ...matchSpeaking, updatedAt: prevQuery }),
      ReadingProgress.countDocuments({ ...matchReading, updatedAt: prevQuery }),
      Enrollment.countDocuments({ ...matchListening, updatedAt: prevQuery }),
    ]);

    const totalCurrent = curW + curS + curR + curL;
    const totalPrevious = preW + preS + preR + preL;
    const submissionTrend = calculateTrend(totalCurrent, totalPrevious);

    // 2. AI COST
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

    const todayStartVn = new Date();
    todayStartVn.setUTCHours(todayStartVn.getUTCHours() + 7);
    const todayStr = todayStartVn.toISOString().split('T')[0];

    const activeUsersCount = await User.countDocuments({ lastActivityDate: todayStr });
    const pendingReportsCount = await Report.countDocuments({ status: 'new' });

    // 3. CHART DATA
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

    const [writingRaw, speakingRaw, readingRaw, listeningRaw] = await Promise.all([
      aggregateChart(WritingSubmission, 'submittedAt', matchWriting),
      aggregateChart(SpeakingEnrollment, 'updatedAt', matchSpeaking),
      aggregateChart(ReadingProgress, 'updatedAt', matchReading),
      aggregateChart(Enrollment, 'updatedAt', matchListening),
    ]);

    const fillData = (rawData) => chartLabels.map(label => {
      const found = rawData.find(item => item._id === label);
      return found ? found.count : 0;
    });

    return res.status(200).json({
      metrics: {
        submissions: {
          value: totalCurrent,
          trend: `${submissionTrend > 0 ? '+' : ''}${submissionTrend}%`,
          // --- SỬA LẠI: Label đúng với so sánh hôm qua ---
          trendLabel: range === 'day' ? 'vs yesterday' : 'vs prev period',
          isPositive: submissionTrend >= 0
        },
        aiCost: {
          value: `$${estimatedCost.toFixed(4)}`,
          subLabel: `${totalWords} words • ${Math.round(totalSeconds/60)} mins`
        },
        reports: {
          value: pendingReportsCount,
          status: pendingReportsCount > 0 ? 'Needs Action' : 'All Good'
        },
        activeUsers: {
          value: activeUsersCount,
          subLabel: 'Active today'
        }
      },
      chart: {
        labels: chartLabels,
        writing: fillData(writingRaw),
        speaking: fillData(speakingRaw),
        reading: fillData(readingRaw),
        dictation: fillData(listeningRaw)
      },
      distribution: {
        writing: curW,
        speaking: curS,
        reading: curR,
        dictation: curL
      }
    });

  } catch (error) {
    console.error("Dashboard Stats Error:", error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};
const getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { filter, search } = req.query;

    let query = { role: 'user' };

    // 1. Tìm kiếm
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    // 2. Bộ lọc Tab
    const now = new Date();
    if (filter === 'today') {
      // Logic lấy ngày hôm nay (UTC date string khớp với format lưu trong lastActivityDate nếu lưu string,
      // nhưng model mới lưu Date nên dùng query range)

      // Cách đơn giản nhất cho Date object: Lấy từ đầu ngày hôm nay
      const startOfDay = new Date();
      startOfDay.setHours(0,0,0,0);
      query.lastActivityDate = { $gte: startOfDay };

    } else if (filter === 'online') {
      // --- SỬA LẠI: Query thẳng vào trường isOnline ---
      query.isOnline = true;
    }

    const users = await User.find(query)
      .select('-password -refreshToken')
      .sort({ isOnline: -1, lastActivityDate: -1 }) // Ưu tiên Online lên đầu
      .skip(skip)
      .limit(limit);

    const total = await User.countDocuments(query);

    res.status(200).json({
      users,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
};

const getReports = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;
    const reports = await Report.find(filter).populate('userId', 'fullName email avatar').sort({ createdAt: -1 }).skip(skip).limit(limit);
    const total = await Report.countDocuments(filter);
    res.status(200).json({ reports, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching reports', error: error.message });
  }
};

const updateReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminResponse } = req.body;
    const report = await Report.findByIdAndUpdate(id, { status, adminResponse, updatedAt: new Date() }, { new: true });
    if (!report) return res.status(404).json({ message: 'Report not found' });
    res.status(200).json({ message: 'Report updated successfully', report });
  } catch (error) {
    res.status(500).json({ message: 'Error updating report', error: error.message });
  }
};
const banUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { banType, durationInHours, reason } = req.body;

    let updateData = {};
    let socketMessage = '';

    if (banType === 'unban') {
      updateData = { isBanned: false, banExpiresAt: null, banReason: '' };
    } else {
      // Logic Ban
      updateData = {
        isBanned: true,
        banReason: reason || 'Vi phạm quy định cộng đồng',
        isOnline: false, // Kick offline ngay lập tức
        refreshToken: null // Hủy token
      };

      if (banType === 'permanent') {
        updateData.banExpiresAt = null; // Null là vĩnh viễn
        socketMessage = `Tài khoản của bạn đã bị khóa vĩnh viễn.\nLý do: ${updateData.banReason}`;
      } else {
        // Tính thời gian hết hạn
        const hours = durationInHours || 24; // Mặc định 24h
        const expireDate = new Date();
        expireDate.setHours(expireDate.getHours() + hours);

        updateData.banExpiresAt = expireDate;
        socketMessage = `Tài khoản bị tạm khóa trong ${hours} giờ.\nLý do: ${updateData.banReason}`;
      }
    }

    const user = await User.findByIdAndUpdate(id, updateData, { new: true });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // --- KICK USER VIA SOCKET ---
    if (banType !== 'unban') {
      // Bắn sự kiện force_logout vào room userId
      getIO().to(id).emit('force_logout', { reason: socketMessage });

      // Cập nhật trạng thái offline cho Admin thấy ngay
      getIO().to('admin_room').emit('user_status_change', { userId: id, isOnline: false });
    }

    res.status(200).json({ message: 'User status updated', user });
  } catch (error) {
    res.status(500).json({ message: 'Error updating user status', error: error.message });
  }
};
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    // Soft delete (nên dùng) hoặc Hard delete
    // Ở đây ví dụ Hard delete:
    await User.findByIdAndDelete(id);

    // Nếu đang online thì cũng kick ra luôn
    getIO().to(id).emit('force_logout', { reason: 'Tài khoản đã bị xóa.' });

    res.status(200).json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};
export default {
  getDashboardStats,
  getAllUsers,
  getReports,
  updateReportStatus,
  banUser,
  deleteUser
};