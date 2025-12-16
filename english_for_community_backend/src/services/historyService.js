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

const getHistory = async (targetUserId, startDate, endDate, filterType) => {
  try {
    const start = startDate ? new Date(startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
    const end = endDate ? new Date(endDate) : new Date();
    start.setHours(0, 0, 0, 0);
    end.setHours(23, 59, 59, 999);

    const dateQuery = { $gte: start, $lte: end };
    const userFilter = targetUserId ? { userId: targetUserId } : {};

    let rawItems = [];

    // --- A. WRITING ---
    if (!filterType || filterType === 'writing') {
      const docs = await WritingSubmission.find({
        submittedAt: dateQuery,
        status: { $in: ['submitted', 'reviewed'] },
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate('topicId', 'name aiConfig')
        .select('userId topicId score submittedAt durationInSeconds status wordCount generatedPrompt feedback')
        .lean();
      rawItems.push(...docs.map(d => ({ ...d, type: 'writing', time: d.submittedAt })));
    }

    // --- B. READING ---
    if (!filterType || filterType === 'reading') {
      const docs = await ReadingProgress.find({
        updatedAt: dateQuery,
        status: 'completed',
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate({ path: 'readingId', select: 'title questions' })
        .lean();
      rawItems.push(...docs.map(d => ({ ...d, type: 'reading', time: d.updatedAt })));
    }

    // --- C. SPEAKING ---
    if (!filterType || filterType === 'speaking') {
      const docs = await SpeakingEnrollment.find({
        updatedAt: dateQuery,
        isCompleted: true,
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate({ path: 'speakingSetId', select: 'title mode sentences' })
        .lean();
      rawItems.push(...docs.map(d => ({ ...d, type: 'speaking', time: d.updatedAt })));
    }

    // --- D. LISTENING ---
    if (!filterType || filterType === 'listening') {
      const docs = await Enrollment.find({
        updatedAt: dateQuery,
        isCompleted: true,
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate({ path: 'listeningId', select: 'title cues' })
        .lean();
      rawItems.push(...docs.map(d => ({ ...d, type: 'listening', time: d.updatedAt })));
    }

    // ======================================================
    // 🔥 FIX: ENRICH DATA VỚI NULL CHECK KỸ LƯỠNG
    // ======================================================

    const finalResults = await Promise.all(rawItems.map(async (item) => {
      // 1. Kiểm tra User (Nếu user bị xóa, item.userId sẽ là null)
      const userObj = item.userId ? {
        id: item.userId._id.toString(),
        name: item.userId.fullName,
        avatar: item.userId.avatarUrl,
        email: item.userId.email
      } : { id: 'deleted', name: 'Deleted User', avatar: '', email: '' };

      // Base object
      const base = {
        id: item._id.toString(),
        type: item.type,
        user: userObj,
        date: item.time,
        status: item.status || 'completed',
      };

      // 🛡️ Guard Clause: Nếu User ID null thì không thể query attempt theo user được
      // Nếu muốn vẫn hiện bài làm của user đã xóa, ta phải bỏ qua bước query aggregate bên dưới
      const userIdStr = item.userId?._id;

      // --- LOGIC 1: WRITING ---
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

      // --- LOGIC 2: READING ---
      if (item.type === 'reading') {
        // 🔥 Fix: Kiểm tra bài đọc còn tồn tại không
        if (!item.readingId) return null;

        let totalDuration = 0;
        if (userIdStr) {
          const timeAgg = await ReadingAttempt.aggregate([
            { $match: { userId: userIdStr, readingId: item.readingId._id } },
            { $group: { _id: null, total: { $sum: "$durationInSeconds" } } }
          ]);
          totalDuration = timeAgg.length > 0 ? timeAgg[0].total : 0;
        }

        const totalQ = item.readingId.questions?.length || 0;
        const score = item.highScore || 0;

        return {
          ...base,
          title: item.readingId.title || 'Reading Practice',
          score: score,
          duration: totalDuration,
          subType: 'Reading',
          totalQuestions: totalQ,
          correctCount: Math.round((score * totalQ) / 100)
        };
      }

      // --- LOGIC 3: SPEAKING ---
      if (item.type === 'speaking') {
        // 🔥 Fix: Kiểm tra speakingSetId có null không (do populate fail)
        if (!item.speakingSetId) return null;

        let setId = item.speakingSetId._id || item.speakingSetId;
        // Fix lỗi 'toString' of null: Kiểm tra setId tồn tại trước
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
        const accuracy = Math.max(0, Math.round((1 - wer) * 100));

        return {
          ...base,
          title: item.speakingSetId.title || 'Speaking Set',
          score: accuracy,
          duration: totalDuration,
          subType: item.speakingSetId.mode || 'Speaking',
          totalQuestions: item.speakingSetId.sentences?.length || 0,
          correctCount: item.completedSentenceIds?.length || 0
        };
      }

      // --- LOGIC 4: LISTENING ---
      if (item.type === 'listening') {
        // 🔥 Fix: Kiểm tra bài nghe còn tồn tại không
        if (!item.listeningId) return null;

        let totalDuration = 0;
        if (userIdStr) {
          const timeAgg = await DictationAttempt.aggregate([
            { $match: { userId: userIdStr, listeningId: item.listeningId._id } },
            { $group: { _id: null, total: { $sum: "$durationInSeconds" } } }
          ]);
          totalDuration = timeAgg.length > 0 ? timeAgg[0].total : 0;
        }

        const scoreVal = Math.round((item.progress || 0) * 100);

        return {
          ...base,
          title: item.listeningId.title || 'Listening Practice',
          score: scoreVal,
          duration: totalDuration,
          subType: 'Dictation',
          totalQuestions: item.listeningId.cues?.length || 0,
          correctCount: item.completedCueIds?.length || 0
        };
      }

      return null; // Fallback
    }));

    // 🔥 Filter bỏ các item bị null (do data bị xóa, populate fail)
    const validResults = finalResults.filter(item => item !== null);

    // Sắp xếp
    return validResults.sort((a, b) => new Date(b.date) - new Date(a.date));

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