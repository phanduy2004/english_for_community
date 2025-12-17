import mongoose from 'mongoose';

// --- MODELS CHÍNH ---
import WritingSubmission from '../models/WritingSubmission.js';
import ReadingProgress from '../models/ReadingProgress.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';

// --- MODELS PHỤ ---
import ReadingAttempt from '../models/ReadingAttempt.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';

// --- MODELS POPULATE ---
import '../models/User.js';
import '../models/WritingTopics.js';
import '../models/Reading.js';
import '../models/SpeakingSet.js';
import '../models/Listening.js';
const toVietnamTime = (date) => {
  if (!date) return null;
  return new Date(date).toLocaleString('en-GB', {
    timeZone: 'Asia/Ho_Chi_Minh',
    hour12: false, // Dùng định dạng 24h
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    // second: '2-digit' // Bật lên nếu muốn hiện giây
  }).replace(',', ''); // Xóa dấu phẩy ngăn cách nếu có
};
const getHistory = async (targetUserId, startDate, endDate, filterType) => {
  try {
    // 1. XỬ LÝ TIMEZONE QUERY (Giữ nguyên logic query đã sửa ở bước trước)
    const start = startDate ? new Date(startDate) : new Date();
    const end = endDate ? new Date(endDate) : new Date();

    if (!startDate) start.setDate(start.getDate() - 30);

    // Chuyển về mốc 0h và 23h59 VN đổi sang UTC
    start.setUTCHours(0, 0, 0, 0);
    start.setUTCHours(start.getUTCHours() - 7);

    end.setUTCHours(23, 59, 59, 999);
    end.setUTCHours(end.getUTCHours() - 7);

    const dateQuery = { $gte: start, $lte: end };
    const userFilter = targetUserId ? { userId: targetUserId } : {};

    let rawItems = [];

    // ... (Giữ nguyên phần query DB lấy rawItems: Writing, Reading, Speaking, Listening) ...

    // 2. MAP DỮ LIỆU (Giữ nguyên date gốc để lát nữa sort)
    const processedResults = await Promise.all(rawItems.map(async (item) => {
      // Check User
      const userObj = item.userId ? {
        id: item.userId._id.toString(),
        name: item.userId.fullName,
        avatar: item.userId.avatarUrl,
        email: item.userId.email
      } : { id: 'deleted', name: 'Deleted User', avatar: '', email: '' };

      const base = {
        id: item._id.toString(),
        type: item.type,
        user: userObj,
        // ⚠️ GIỮ DATE GỐC (OBJECT) ĐỂ SORT TRƯỚC
        date: item.time,
        status: item.status || 'completed',
      };

      // --- LOGIC TỪNG LOẠI (Copy lại logic cũ) ---
      const userIdStr = item.userId?._id;

      if (item.type === 'writing') {
        return {
          ...base,
          title: item.generatedPrompt?.title || item.topicId?.name || 'Writing Task',
          score: item.score || 0,
          duration: item.durationInSeconds || 0,
          wordCount: item.wordCount || 0,
          subType: item.generatedPrompt?.taskType || 'Essay',
          feedbackSummary: item.feedback?.overall ? `Band ${item.feedback.overall}` : null
        };
      }

      if (item.type === 'reading') {
        if (!item.readingId) return null;
        let totalDuration = 0;
        if (userIdStr) {
          const timeAgg = await ReadingAttempt.aggregate([
            { $match: { userId: userIdStr, readingId: item.readingId._id } },
            { $group: { _id: null, total: { $sum: "$durationInSeconds" } } }
          ]);
          totalDuration = timeAgg.length > 0 ? timeAgg[0].total : 0;
        }
        return {
          ...base,
          title: item.readingId.title || 'Reading Practice',
          score: item.highScore || 0,
          duration: totalDuration,
          subType: 'Reading',
          totalQuestions: item.readingId.questions?.length || 0,
          correctCount: Math.round(((item.highScore || 0) * (item.readingId.questions?.length || 0)) / 100)
        };
      }

      if (item.type === 'speaking') {
        if (!item.speakingSetId) return null;
        let setId = item.speakingSetId._id || item.speakingSetId;
        if (setId && typeof setId === 'object') setId = setId.toString();

        let totalDuration = 0;
        if (userIdStr && setId) {
          const timeAgg = await SpeakingAttempt.aggregate([
            { $match: { userId: userIdStr, speakingSetId: setId } },
            { $group: { _id: null, total: { $sum: "$audioDurationSeconds" } } }
          ]);
          totalDuration = timeAgg.length > 0 ? timeAgg[0].total : 0;
        }
        const wer = item.averageWer ?? 1;
        return {
          ...base,
          title: item.speakingSetId.title || 'Speaking Set',
          score: Math.max(0, Math.round((1 - wer) * 100)),
          duration: totalDuration,
          subType: item.speakingSetId.mode || 'Speaking',
          totalQuestions: item.speakingSetId.sentences?.length || 0,
          correctCount: item.completedSentenceIds?.length || 0
        };
      }

      if (item.type === 'listening') {
        if (!item.listeningId) return null;
        let totalDuration = 0;
        if (userIdStr) {
          const timeAgg = await DictationAttempt.aggregate([
            { $match: { userId: userIdStr, listeningId: item.listeningId._id } },
            { $group: { _id: null, total: { $sum: "$durationInSeconds" } } }
          ]);
          totalDuration = timeAgg.length > 0 ? timeAgg[0].total : 0;
        }
        return {
          ...base,
          title: item.listeningId.title || 'Listening Practice',
          score: Math.round((item.progress || 0) * 100),
          duration: totalDuration,
          subType: 'Dictation',
          totalQuestions: item.listeningId.cues?.length || 0,
          correctCount: item.completedCueIds?.length || 0
        };
      }

      return null;
    }));

    // 3. LỌC BỎ NULL & SẮP XẾP (Dùng date gốc để sort)
    let sortedList = processedResults
      .filter(item => item !== null)
      .sort((a, b) => new Date(b.date) - new Date(a.date)); // Mới nhất lên đầu

    // 4. BƯỚC CUỐI: FORMAT LẠI DATE THÀNH STRING VIỆT NAM
    // Đây là bước biến field 'date' thành 'dd/MM/yyyy HH:mm' như bạn muốn
    return sortedList.map(item => ({
      ...item,
      date: toVietnamTime(item.date) // Ghi đè field date
    }));

  } catch (error) {
    console.error("[History Service] Error:", error);
    throw error;
  }
};

// ... (Hàm getActivityDetail giữ nguyên)
const getActivityDetail = async (id, type) => {
  // ... code cũ của hàm này không đổi
  // (nhưng bạn cũng nên thêm check null cho các populate trong hàm này tương tự nếu cần)
  // Để tiết kiệm không gian tôi không paste lại hàm này vì lỗi 500 xảy ra ở getHistory
  try {
    let result = null;

    if (type === 'writing') {
      result = await WritingSubmission.findById(id)
        .populate('userId', 'fullName avatarUrl email')
        .populate('topicId', 'name aiConfig')
        .lean();
    }

    if (type === 'reading') {
      const progress = await ReadingProgress.findById(id)
        .populate('userId', 'fullName avatarUrl')
        .populate({ path: 'readingId', select: 'title questions content' })
        .lean();

      if (progress) {
        // Check readingId exist
        if (!progress.readingId) throw new Error("Reading content deleted");

        const attempt = await ReadingAttempt.findOne({
          userId: progress.userId._id,
          readingId: progress.readingId._id
        })
          .sort({ createdAt: -1 })
          .lean();

        result = {
          _id: progress._id,
          ...attempt,
          score: progress.highScore,
          readingId: progress.readingId,
          user: progress.userId
        };
      }
    }

    if (type === 'speaking') {
      const enrollment = await SpeakingEnrollment.findById(id)
        .populate('userId', 'fullName avatarUrl')
        .populate({ path: 'speakingSetId', select: 'title mode sentences' })
        .lean();

      if (enrollment) {
        if (!enrollment.speakingSetId) throw new Error("Speaking content deleted");

        const attempts = await SpeakingAttempt.find({
          userId: enrollment.userId._id,
          speakingSetId: enrollment.speakingSetId._id ? enrollment.speakingSetId._id.toString() : enrollment.speakingSetId
        }).lean();

        const sentencesWithHistory = enrollment.speakingSetId.sentences.map(s => {
          const sentAttempts = attempts.filter(a => a.sentenceId === s.id);
          sentAttempts.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));
          return { ...s, history: sentAttempts };
        });

        result = {
          _id: enrollment._id,
          ...enrollment.speakingSetId,
          sentences: sentencesWithHistory,
          user: enrollment.userId
        };
      }
    }

    if (type === 'listening') {
      const enrollment = await Enrollment.findById(id)
        .populate('userId', 'fullName avatarUrl')
        .populate({ path: 'listeningId', select: 'title cues audioUrl' })
        .lean();

      if (enrollment) {
        if (!enrollment.listeningId) throw new Error("Listening content deleted");

        const attempts = await DictationAttempt.find({
          userId: enrollment.userId._id,
          listeningId: enrollment.listeningId._id
        }).sort({ cueIdx: 1 }).lean();

        result = {
          _id: enrollment._id,
          attemptsDetail: attempts,
          user: enrollment.userId
        };
      }
    }

    if (!result) throw new Error('Activity not found');
    return result;

  } catch (error) {
    console.error("Get Detail Error:", error);
    throw error;
  }
};

export default { getHistory, getActivityDetail };