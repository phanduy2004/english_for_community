import mongoose from 'mongoose';
import UserDailyProgress from '../models/UserDailyProgress.js';
import Word from '../models/Word.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import WritingSubmission from '../models/WritingSubmission.js';
import DictationAttempt from '../models/DictationAttempt.js';

// Helper: Format số liệu phần trăm (VD: 0.85 -> 85%)
const formatPercent = (val) => {
  if (val === null || val === undefined || isNaN(val)) return "N/A";
  return (val * 100).toFixed(0) + '%';
};

export const toolImplementations = {

  // =================================================================
  // 1. TỔNG QUAN (Lấy từ UserDailyProgress - Nguồn duy nhất đã chuẩn hóa)
  // =================================================================
  get_learning_history: async (userId, args) => {
    const { startDate, endDate } = args;
    console.log(`🛠️ Tool: get_learning_history (${startDate} -> ${endDate})`);

    // Query trực tiếp bảng thống kê hàng ngày
    const records = await UserDailyProgress.find({
      userId,
      date: { $gte: startDate, $lte: endDate }
    }).sort({ date: 1 }).lean();

    if (!records.length) return "Không có dữ liệu tổng hợp nào trong khoảng thời gian này.";

    return records.map(r => {
      const stats = r.stats || {};

      // Helper tính trung bình từ object { total, count } của file Migrate
      const calcAvg = (obj) => (obj && obj.count > 0) ? (obj.total / obj.count) : 0;

      return {
        date: r.date,
        minutes: Math.round((r.studySeconds || 0) / 60),
        new_words: r.vocabLearned || 0,
        skills: {
          // Chỉ hiện số liệu nếu ngày hôm đó có học (count > 0)
          reading: stats.readingAccuracy?.count > 0 ? formatPercent(calcAvg(stats.readingAccuracy)) : "-",
          speaking: stats.speakingScore?.count > 0 ? formatPercent(calcAvg(stats.speakingScore)) : "-", // SpeakingScore trong migrate là (1-WER)
          listening: stats.dictationAccuracy?.count > 0 ? formatPercent(calcAvg(stats.dictationAccuracy)) : "-",
          writing: stats.writingScore?.count > 0 ? calcAvg(stats.writingScore).toFixed(1) : "-"
        }
      };
    });
  },

  // =================================================================
  // 2. CHI TIẾT SPEAKING (Giống logic Migrate + Lấy thêm Transcript)
  // =================================================================
  get_speaking_details: async (userId, args) => {
    const limit = args.limit || 5;
    console.log(`🛠️ Tool: get_speaking_details (limit ${limit})`);

    const attempts = await SpeakingAttempt.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      // Logic 1: Ưu tiên lấy ngày nộp, nếu lỗi thì lấy ngày tạo (Sync với Migrate)
      { $addFields: { realDate: { $ifNull: ["$submittedAt", "$createdAt"] } } },
      { $match: { realDate: { $ne: null } } },
      { $sort: { realDate: -1 } },
      { $limit: limit },
      // Logic 2: Join lấy tên bài học
      {
        $lookup: {
          from: 'speakingsets', // Collection name trong DB
          localField: 'speakingSetId',
          foreignField: '_id',
          as: 'setInfo'
        }
      },
      {
        $project: {
          date: { $dateToString: { format: "%Y-%m-%d %H:%M", date: "$realDate", timezone: "Asia/Ho_Chi_Minh" } },
          topic: { $ifNull: [{ $arrayElemAt: ["$setInfo.title", 0] }, "Bài nói tự do"] },
          transcript: { $ifNull: ['$userTranscript', 'Không có nội dung'] },
          // Logic 3: Tính điểm chính xác như Migrate: Max(0, 1 - WER)
          accuracyRaw: { $max: [0, { $subtract: [1, { $ifNull: ['$score.wer', 1] }] }] }
        }
      }
    ]);

    if (!attempts.length) return "Bạn chưa thực hành bài Nói nào.";

    return attempts.map(a => ({
      date: a.date,
      topic: a.topic,
      score: formatPercent(a.accuracyRaw),
      details: a.transcript.substring(0, 50) + "..." // Cắt ngắn transcript để đỡ tốn token
    }));
  },

  // =================================================================
  // 3. CHI TIẾT READING (Giống logic Migrate + Normalized Score)
  // =================================================================
  get_reading_details: async (userId, args) => {
    const limit = args.limit || 5;
    console.log(`🛠️ Tool: get_reading_details (limit ${limit})`);

    const attempts = await ReadingAttempt.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), createdAt: { $ne: null } } },
      { $sort: { createdAt: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'readings',
          localField: 'readingId',
          foreignField: '_id',
          as: 'readingInfo'
        }
      },
      {
        $project: {
          date: { $dateToString: { format: "%Y-%m-%d %H:%M", date: "$createdAt", timezone: "Asia/Ho_Chi_Minh" } },
          title: { $ifNull: [{ $arrayElemAt: ["$readingInfo.title", 0] }, "Bài đọc"] },
          correctCount: 1,
          totalQuestions: 1,
          // Logic tính điểm: Correct / Total (Tránh chia cho 0)
          normalizedScore: {
            $cond: {
              if: { $gt: [{ $ifNull: ["$totalQuestions", 0] }, 0] },
              then: { $divide: ["$correctCount", "$totalQuestions"] },
              else: 0
            }
          }
        }
      }
    ]);

    if (!attempts.length) return "Bạn chưa làm bài Đọc nào.";

    return attempts.map(a => ({
      date: a.date,
      title: a.title,
      score: formatPercent(a.normalizedScore),
      result: `${a.correctCount}/${a.totalQuestions} câu đúng`
    }));
  },

  // =================================================================
  // 4. CHI TIẾT WRITING (Logic mở rộng: Lấy cả bài ĐANG CHỜ)
  // =================================================================
  get_writing_details: async (userId, args) => {
    const limit = args.limit || 5;
    console.log(`🛠️ Tool: get_writing_details (limit ${limit})`);

    const submissions = await WritingSubmission.aggregate([
      { $match: {
          userId: new mongoose.Types.ObjectId(userId),
          // 🔥 QUAN TRỌNG: Lấy cả 'submitted' (chưa chấm) để AI biết mà báo cáo
          status: { $in: ['reviewed', 'submitted'] },
          submittedAt: { $ne: null }
        }},
      { $sort: { submittedAt: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'writingtopics',
          localField: 'topicId',
          foreignField: '_id',
          as: 'topicInfo'
        }
      },
      {
        $project: {
          date: { $dateToString: { format: "%Y-%m-%d %H:%M", date: "$submittedAt", timezone: "Asia/Ho_Chi_Minh" } },
          topic: { $ifNull: [{ $arrayElemAt: ["$topicInfo.name", 0] }, "Bài viết"] },
          score: { $ifNull: ['$score', 0] },
          status: '$status', // Trả về status để AI phân biệt
          feedback: { $ifNull: ['$feedback.generalComment', ''] }
        }
      }
    ]);

    if (!submissions.length) return "Bạn chưa nộp bài Viết nào.";

    // Format lại dữ liệu cho AI dễ hiểu
    return submissions.map(s => {
      const isPending = s.status === 'submitted';
      return {
        date: s.date,
        topic: s.topic,
        score: isPending ? "Đang chấm" : s.score, // Nếu chưa chấm thì báo rõ
        feedback: isPending ? "Chưa có" : (s.feedback || "Không có nhận xét"),
        status: isPending ? "⏳ Đợi giáo viên" : "✅ Đã chấm"
      };
    });
  },

  // =================================================================
  // 5. CHI TIẾT LISTENING (Dùng DictationAttempt - Logic giống Migrate)
  // =================================================================
  get_listening_details: async (userId, args) => {
    const limit = args.limit || 5;
    console.log(`🛠️ Tool: get_listening_details (limit ${limit})`);

    const attempts = await DictationAttempt.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      { $addFields: { realDate: { $ifNull: ["$submittedAt", "$createdAt"] } } },
      { $match: { realDate: { $ne: null } } },
      { $sort: { realDate: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'listenings',
          localField: 'listeningId',
          foreignField: '_id',
          as: 'info'
        }
      },
      {
        $project: {
          date: { $dateToString: { format: "%Y-%m-%d %H:%M", date: "$realDate", timezone: "Asia/Ho_Chi_Minh" } },
          title: { $ifNull: [{ $arrayElemAt: ["$info.title", 0] }, "Bài nghe"] },
          // Logic điểm: Max(0, 1 - WER)
          accuracyRaw: { $max: [0, { $subtract: [1, { $ifNull: ['$score.wer', 1] }] }] }
        }
      }
    ]);

    if (!attempts.length) return "Bạn chưa làm bài Nghe nào.";

    return attempts.map(a => ({
      date: a.date,
      title: a.title,
      score: formatPercent(a.accuracyRaw)
    }));
  },

  // =================================================================
  // 6. TỪ VỰNG (Giữ nguyên logic đơn giản)
  // =================================================================
  get_vocab_list: async (userId, args) => {
    const status = args.status || 'learning';
    const limit = args.limit || 10;

    const words = await Word.find({ user: userId, status: status })
      .sort({ updatedAt: -1 })
      .limit(limit)
      .select('headword shortDefinition learningLevel')
      .lean();

    if (!words.length) return `Không có từ vựng nào trạng thái '${status}'.`;
    return words.map(w => `${w.headword} (Lv.${w.learningLevel}): ${w.shortDefinition}`);
  }
};