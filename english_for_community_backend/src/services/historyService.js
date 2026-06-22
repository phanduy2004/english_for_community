import mongoose from 'mongoose';

import User from '../models/User.js';
import {
  isPlainYmd,
  utcRangeForCalendarDate,
  addCalendarDays,
} from '../utils/localDayBounds.js';

// --- MODELS CHÍNH ---
import WritingSubmission from '../models/WritingSubmission.js';
import ReadingProgress from '../models/ReadingProgress.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
import Enrollment from '../models/Enrollment.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js'; // 🔥 THÊM MỚI CHỖ NÀY

// --- MODELS PHỤ ---
import ReadingAttempt from '../models/ReadingAttempt.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';

// --- MODELS POPULATE ---
import '../models/WritingTopics.js';
import '../models/Reading.js';
import '../models/SpeakingSet.js';
import '../models/Listening.js';
import '../models/ListeningComprehension.js'; // 🔥 THÊM MỚI CHỖ NÀY

const getHistory = async (targetUserId, startDate, endDate, filterType) => {
  try {
    let tz = 'Asia/Ho_Chi_Minh';
    if (targetUserId) {
      const u = await User.findById(targetUserId).select('timezone').lean();
      if (u?.timezone) tz = u.timezone;
    }

    let start;
    let end;

    if (isPlainYmd(startDate) && isPlainYmd(endDate)) {
      const r0 = utcRangeForCalendarDate(startDate, tz);
      const r1 = utcRangeForCalendarDate(endDate, tz);
      if (!r0 || !r1) {
        throw new Error('Invalid startDate or endDate (expected YYYY-MM-DD)');
      }
      start = r0.start;
      end = r1.end;
    } else if (!startDate && !endDate) {
      const todayYmd = new Date().toLocaleDateString('en-CA', { timeZone: tz });
      const fromYmd = addCalendarDays(todayYmd, -29);
      start = utcRangeForCalendarDate(fromYmd, tz).start;
      end = utcRangeForCalendarDate(todayYmd, tz).end;
    } else {
      const s = startDate ? new Date(startDate) : new Date();
      const e = endDate ? new Date(endDate) : new Date();
      if (!startDate) {
        s.setDate(s.getDate() - 30);
      }
      start = s;
      end = e;
      start.setUTCHours(0, 0, 0, 0);
      start.setUTCHours(start.getUTCHours() - 7);
      end.setUTCHours(23, 59, 59, 999);
      end.setUTCHours(end.getUTCHours() - 7);
    }

    if (start > end) {
      const t = start;
      start = end;
      end = t;
    }

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

    // --- D. LISTENING (Bao gồm Dictation & Comprehension) ---
    if (!filterType || filterType === 'listening') {
      // 1. Lấy Dictation
      const dictationDocs = await Enrollment.find({
        updatedAt: dateQuery,
        isCompleted: true,
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate({ path: 'listeningId', select: 'title cues' })
        .lean();
      rawItems.push(...dictationDocs.map(d => ({ ...d, type: 'dictation', time: d.updatedAt })));

      // 2. Lấy Comprehension (🔥 THÊM LOGIC NÀY)
      const compDocs = await ListeningCompAttempt.find({
        createdAt: dateQuery,
        ...userFilter
      })
        .populate('userId', 'fullName avatarUrl email')
        .populate({ path: 'listeningId', select: 'title questions' })
        .lean();
      rawItems.push(...compDocs.map(c => ({ ...c, type: 'comprehension', time: c.createdAt })));
    }

    // ======================================================
    // ENRICH DATA — batch duration lookups (avoid N+1 aggregations)
    // ======================================================

    const readingKeys = new Map();
    const speakingKeys = new Map();
    const dictationKeys = new Map();

    for (const item of rawItems) {
      const userIdStr = item.userId?._id;
      if (!userIdStr) continue;
      if (item.type === 'reading' && item.readingId?._id) {
        const key = `${userIdStr}-${item.readingId._id}`;
        readingKeys.set(key, { userId: userIdStr, readingId: item.readingId._id });
      }
      if (item.type === 'speaking' && item.speakingSetId) {
        let setId = item.speakingSetId._id || item.speakingSetId;
        if (setId && typeof setId === 'object') setId = setId.toString();
        if (setId) {
          const key = `${userIdStr}-${setId}`;
          speakingKeys.set(key, { userId: userIdStr, speakingSetId: setId });
        }
      }
      if (item.type === 'dictation' && item.listeningId?._id) {
        const key = `${userIdStr}-${item.listeningId._id}`;
        dictationKeys.set(key, { userId: userIdStr, listeningId: item.listeningId._id });
      }
    }

    const readingDurationMap = new Map();
    if (readingKeys.size > 0) {
      const or = [...readingKeys.values()].map((p) => ({
        userId: p.userId,
        readingId: p.readingId,
      }));
      const rows = await ReadingAttempt.aggregate([
        { $match: { $or: or } },
        {
          $group: {
            _id: { userId: '$userId', readingId: '$readingId' },
            total: { $sum: '$durationInSeconds' },
          },
        },
      ]);
      for (const row of rows) {
        readingDurationMap.set(
          `${row._id.userId}-${row._id.readingId}`,
          row.total,
        );
      }
    }

    const speakingDurationMap = new Map();
    if (speakingKeys.size > 0) {
      const or = [...speakingKeys.values()].map((p) => ({
        userId: p.userId,
        speakingSetId: p.speakingSetId,
      }));
      const rows = await SpeakingAttempt.aggregate([
        { $match: { $or: or } },
        {
          $group: {
            _id: { userId: '$userId', speakingSetId: '$speakingSetId' },
            total: { $sum: '$audioDurationSeconds' },
          },
        },
      ]);
      for (const row of rows) {
        speakingDurationMap.set(
          `${row._id.userId}-${row._id.speakingSetId}`,
          row.total,
        );
      }
    }

    const dictationDurationMap = new Map();
    if (dictationKeys.size > 0) {
      const or = [...dictationKeys.values()].map((p) => ({
        userId: p.userId,
        listeningId: p.listeningId,
      }));
      const rows = await DictationAttempt.aggregate([
        { $match: { $or: or } },
        {
          $group: {
            _id: { userId: '$userId', listeningId: '$listeningId' },
            total: { $sum: '$durationInSeconds' },
          },
        },
      ]);
      for (const row of rows) {
        dictationDurationMap.set(
          `${row._id.userId}-${row._id.listeningId}`,
          row.total,
        );
      }
    }

    const finalResults = await Promise.all(rawItems.map(async (item) => {
      const userObj = item.userId ? {
        id: item.userId._id.toString(),
        name: item.userId.fullName,
        avatar: item.userId.avatarUrl,
        email: item.userId.email
      } : { id: 'deleted', name: 'Deleted User', avatar: '', email: '' };

      const base = {
        id: item._id.toString(),
        type: item.type === 'dictation' || item.type === 'comprehension' ? 'listening' : item.type, // Ép về type gốc cho giao diện
        user: userObj,
        date: item.time,
        status: item.status || 'completed',
      };

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
        if (!item.readingId) return null;

        let totalDuration = 0;
        if (userIdStr) {
          totalDuration =
            readingDurationMap.get(`${userIdStr}-${item.readingId._id}`) || 0;
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
        if (!item.speakingSetId) return null;

        let setId = item.speakingSetId._id || item.speakingSetId;
        if (setId && typeof setId === 'object') setId = setId.toString();

        let totalDuration = 0;
        if (userIdStr && setId) {
          totalDuration =
            speakingDurationMap.get(`${userIdStr}-${setId}`) || 0;
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

      // --- LOGIC 4: LISTENING - DICTATION ---
      if (item.type === 'dictation') {
        if (!item.listeningId) return null;

        let totalDuration = 0;
        if (userIdStr) {
          totalDuration =
            dictationDurationMap.get(`${userIdStr}-${item.listeningId._id}`) || 0;
        }

        const scoreVal = Math.round((item.progress || 0) * 100);

        return {
          ...base,
          title: item.listeningId.title || 'Dictation Practice',
          score: scoreVal,
          duration: totalDuration,
          subType: 'Dictation',
          totalQuestions: item.listeningId.cues?.length || 0,
          correctCount: item.completedCueIds?.length || 0
        };
      }

      // --- LOGIC 5: LISTENING - COMPREHENSION (🔥 THÊM MỚI NÀY) ---
      if (item.type === 'comprehension') {
        if (!item.listeningId) return null;

        return {
          ...base,
          title: item.listeningId.title || 'Comprehension Practice',
          score: Math.round(item.score || 0),
          duration: item.durationInSeconds || 0,
          subType: 'Comprehension',
          totalQuestions: item.totalQuestions || 0,
          correctCount: item.correctCount || 0
        };
      }

      return null;
    }));

    const validResults = finalResults.filter(item => item !== null);
    return validResults.sort((a, b) => new Date(b.date) - new Date(a.date));

  } catch (error) {
    console.error("[History Service] Error:", error);
    throw error;
  }
};

const getActivityDetail = async (id, type, subType) => {
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
        if (!progress.readingId) throw new Error("Reading content deleted");

        const attempt = await ReadingAttempt.findOne({
          userId: progress.userId._id,
          readingId: progress.readingId._id
        }).sort({ createdAt: -1 }).lean();

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

    // --- LISTENING XỬ LÝ 2 LOẠI (DICTATION & COMPREHENSION) ---
    if (type === 'listening') {
      // 1. Xử lý Comprehension
      if (subType === 'Comprehension') {
        const attempt = await ListeningCompAttempt.findById(id)
          .populate('userId', 'fullName avatarUrl')
          .populate({ path: 'listeningId', select: 'title questions audioUrl' })
          .lean();

        if (attempt) {
          if (!attempt.listeningId) throw new Error("Comprehension content deleted");

          result = {
            _id: attempt._id,
            score: attempt.score,
            correctCount: attempt.correctCount,
            totalQuestions: attempt.totalQuestions,
            durationInSeconds: attempt.durationInSeconds,
            answersDetail: attempt.answers, // Mảng chi tiết đúng sai từng câu
            listeningId: attempt.listeningId, // Gói luôn bài nghe vào đây
            user: attempt.userId
          };
        }
      }
      // 2. Xử lý Dictation (Như cũ)
      else {
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
    }

    if (!result) throw new Error('Activity not found');
    return result;

  } catch (error) {
    console.error("Get Detail Error:", error);
    throw error;
  }
};

/**
 * Danh sách lịch sử có phân trang (slice sau khi merge + sort).
 * Chỉ dùng khi đã có targetUserId (luồng user xem chính mình).
 */
const getHistoryPaginated = async (
  targetUserId,
  startDate,
  endDate,
  filterType,
  options = {},
) => {
  if (!targetUserId) {
    throw new Error('targetUserId is required for paginated history');
  }

  const page = Math.max(1, parseInt(options.page, 10) || 1);
  const limit = Math.min(Math.max(1, parseInt(options.limit, 10) || 20), 100);
  const sort = options.sort === 'asc' ? 'asc' : 'desc';

  const all = await getHistory(targetUserId, startDate, endDate, filterType);
  const total = all.length;

  let ordered = [...all];
  if (sort === 'asc') ordered.reverse();

  const startIdx = (page - 1) * limit;
  const slice = ordered.slice(startIdx, startIdx + limit);
  const hasMore = startIdx + slice.length < total;

  return {
    data: slice,
    total,
    page,
    limit,
    hasMore,
  };
};

const assertActivityOwnedByUser = async (activityId, type, subType, requestUserId) => {
  const uid = requestUserId.toString();

  if (type === 'writing') {
    const doc = await WritingSubmission.findById(activityId).select('userId').lean();
    if (!doc) throw new Error('Activity not found');
    if (doc.userId.toString() !== uid) throw new Error('Forbidden');
    return;
  }

  if (type === 'reading') {
    const doc = await ReadingProgress.findById(activityId).select('userId').lean();
    if (!doc) throw new Error('Activity not found');
    if (doc.userId.toString() !== uid) throw new Error('Forbidden');
    return;
  }

  if (type === 'speaking') {
    const doc = await SpeakingEnrollment.findById(activityId).select('userId').lean();
    if (!doc) throw new Error('Activity not found');
    if (doc.userId.toString() !== uid) throw new Error('Forbidden');
    return;
  }

  if (type === 'listening') {
    if (subType === 'Comprehension') {
      const doc = await ListeningCompAttempt.findById(activityId).select('userId').lean();
      if (!doc) throw new Error('Activity not found');
      if (doc.userId.toString() !== uid) throw new Error('Forbidden');
      return;
    }
    const doc = await Enrollment.findById(activityId).select('userId').lean();
    if (!doc) throw new Error('Activity not found');
    if (doc.userId.toString() !== uid) throw new Error('Forbidden');
    return;
  }

  throw new Error('Invalid activity type');
};

/**
 * Chi tiết bài làm chỉ khi bản ghi thuộc về requestUserId.
 */
const getActivityDetailForUser = async (activityId, type, subType, requestUserId) => {
  await assertActivityOwnedByUser(activityId, type, subType, requestUserId);
  return getActivityDetail(activityId, type, subType);
};

const MAX_HISTORY_RANGE_DAYS = 90;

/** Chuẩn hoá phần tử list cho API GET /users/me/activities */
export function normalizeActivityListItem(item) {
  const dateVal = item.date;
  return {
    ...item,
    durationSeconds: item.duration ?? 0,
    tags: Array.isArray(item.tags) ? item.tags : [],
    date:
      dateVal instanceof Date
        ? dateVal.toISOString()
        : dateVal,
  };
}

/**
 * Khoảng ngày không vượt quá MAX_HISTORY_RANGE_DAYS.
 * Trả về {} nếu hợp lệ không cần chỉnh; { error: string } nếu sai.
 */
export function validateActivityDateRange(startDateStr, endDateStr) {
  if (!startDateStr && !endDateStr) {
    return {};
  }

  const end = endDateStr ? new Date(endDateStr) : new Date();
  let start;
  if (startDateStr) {
    start = new Date(startDateStr);
  } else {
    start = new Date(end);
    start.setDate(start.getDate() - 30);
  }

  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    return { error: 'Invalid startDate or endDate' };
  }
  if (end < start) {
    return { error: 'endDate must be on or after startDate' };
  }

  const diffDays = (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24);
  if (diffDays > MAX_HISTORY_RANGE_DAYS) {
    return {
      error: `Date range cannot exceed ${MAX_HISTORY_RANGE_DAYS} days`,
    };
  }

  return {};
}

export default {
  getHistory,
  getActivityDetail,
  getHistoryPaginated,
  getActivityDetailForUser,
  normalizeActivityListItem,
  validateActivityDateRange,
};