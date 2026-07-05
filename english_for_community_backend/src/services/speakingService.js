// lib/services/speakingService.js
import SpeakingSet from '../models/SpeakingSet.js';
import mongoose from 'mongoose';
import SpeakingAttempt from "../models/SpeakingAttempt.js";
import SpeakingEnrollment from "../models/SpeakingEnrollment.js";
import SpeakingConversation from '../models/SpeakingConversation.js';
import SpeakingScenario from '../models/SpeakingScenario.js';
import User from '../models/User.js';
import {updateGamificationStats} from "./gamificationService.js";
import { toSpeakingSetObjectId } from '../lib/speakingSetId.js';
import { aiService } from './aiService.js';
import { trackUserProgress } from '../utils/progressTracker.js';
import { z } from 'zod';

export const MIN_TURNS_FOR_FEEDBACK = 3;
export const MIN_DURATION_SEC_FOR_FEEDBACK = 30;

const cleanConversationTurns = (turns = []) => {
  if (!Array.isArray(turns)) return [];
  return turns
    .map((turn) => ({
      role: turn?.role === 'ai' ? 'ai' : turn?.role === 'user' ? 'user' : null,
      text: `${turn?.text ?? ''}`.trim(),
      ts: Number.isFinite(Number(turn?.ts)) ? Number(turn.ts) : undefined,
    }))
    .filter((turn) => turn.role && turn.text.length > 0);
};

export const computeStats = (turns = [], durationSeconds = 0) => {
  const userTexts = cleanConversationTurns(turns)
    .filter((turn) => turn.role === 'user')
    .map((turn) => turn.text);
  const joined = userTexts.join(' ');
  const words = joined.match(/[A-Za-z]+(?:'[A-Za-z]+)?/g) || [];
  const fillerMatches = joined.match(/\b(um+|uh+|er+|like|you know|kind of|sort of|actually|basically)\b/gi) || [];
  const questionMatches = joined.match(/\?/g) || [];
  const durationSec = Math.max(0, Math.round(Number(durationSeconds) || 0));
  const wpm = durationSec > 0 ? Math.round((words.length / (durationSec / 60)) * 10) / 10 : 0;

  return {
    words: words.length,
    durationSec,
    wpm,
    fillerCount: fillerMatches.length,
    questionCount: questionMatches.length,
    turnCount: userTexts.length,
  };
};

const isConversationTooShort = (stats) =>
  stats.words === 0 ||
  (stats.turnCount < MIN_TURNS_FOR_FEEDBACK &&
    stats.durationSec < MIN_DURATION_SEC_FOR_FEEDBACK);

const toObjectId = (id) => new mongoose.Types.ObjectId(id);

const evaluateConversationSchema = z.object({
  turns: z.array(z.object({
    role: z.enum(['user', 'ai']),
    text: z.string().trim().min(1),
    ts: z.number().optional(),
  })).min(1),
  durationSeconds: z.coerce.number().min(0).max(24 * 60 * 60).default(0),
  startedAt: z.string().optional(),
  endedAt: z.string().optional(),
  level: z.string().trim().max(40).optional().nullable(),
  scenarioId: z.string().trim().optional().nullable(),
});

const scenarioQuerySchema = z.object({
  group: z.string().trim().optional(),
  level: z.string().trim().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(30),
});

const summaryQuerySchema = z.object({
  range: z.enum(['week', 'month']).default('week'),
});

const notebookQuerySchema = z.object({
  limit: z.coerce.number().int().min(5).max(80).default(40),
});

const roundOne = (value) => Math.round((Number(value) || 0) * 10) / 10;

const avg = (items, selector) => {
  const values = items.map(selector).filter((v) => Number.isFinite(Number(v)));
  if (!values.length) return 0;
  return roundOne(values.reduce((sum, v) => sum + Number(v), 0) / values.length);
};

const normalizeDateKey = (date, timezone) =>
  new Date(date).toLocaleDateString('en-CA', { timeZone: timezone });

const dateRangeForSummary = async (userId, range) => {
  const user = await User.findById(userId)
    .select('timezone speakingStreak speakingBadges totalPoints')
    .lean();
  const timezone = user?.timezone || 'Asia/Ho_Chi_Minh';
  const today = new Date();
  const days = range === 'month' ? 30 : 7;
  const start = new Date(today.getTime() - (days - 1) * 24 * 60 * 60 * 1000);
  start.setHours(0, 0, 0, 0);
  return { user, timezone, startDate: start, endDate: today, days };
};

const trendValue = (current, previous) =>
  previous == null ? 0 : Math.round((Number(current || 0) - Number(previous || 0)) * 10) / 10;

const buildTrendPayload = (current, previous) => ({
  overall: trendValue(current?.overall, previous?.overall),
  fc: trendValue(current?.fc, previous?.fc),
  lr: trendValue(current?.lr, previous?.lr),
  gra: trendValue(current?.gra, previous?.gra),
  ia: trendValue(current?.ia, previous?.ia),
});

const getPreviousReviewedConversation = async (userObjectId, beforeId) =>
  SpeakingConversation.findOne({
    userId: userObjectId,
    status: 'reviewed',
    _id: { $lt: beforeId },
  })
    .select('feedback.overall feedback.fc feedback.lr feedback.gra feedback.ia')
    .sort({ _id: -1 })
    .lean();

const scenarioSnapshot = (scenario) => scenario ? {
  slug: scenario.slug,
  title: scenario.title,
  group: scenario.group,
  levelSuggested: scenario.levelSuggested,
  goals: scenario.goals || [],
} : undefined;

const parseOrThrow = (schema, payload) => {
  const result = schema.safeParse(payload || {});
  if (result.success) return result.data;
  const err = new Error('Invalid request payload');
  err.statusCode = 400;
  err.details = result.error.flatten();
  throw err;
};

const serializeConversation = (doc) => {
  if (!doc) return null;
  const obj = doc.toObject ? doc.toObject() : doc;
  return {
    ...obj,
    id: obj._id?.toString?.() ?? obj.id,
  };
};

const getSetsWithProgress = async (userId, filters, options) => {
  // ... (Phần này giữ nguyên, không thay đổi)
  const { mode, level } = filters;
  const { page, limit } = options;
  const skip = (page - 1) * limit;
  const matchConditions = { _destroy: { $ne: true } };
  if (mode) {
    matchConditions.mode = mode;
  }
  if (level) {
    matchConditions.level = level;
  }
  const userObjectId = new mongoose.Types.ObjectId(userId);
  const aggregation = [
    // --- Giai đoạn 1: Lọc các SpeakingSet theo 'mode' và 'level' ---
    {
      $match: matchConditions
    },

    // --- Giai đoạn 2: Lấy (join) dữ liệu Enrollment của user ---
    {
      $lookup: {
        from: 'speakingenrollments', // Tên collection

        // ⬇️ SỬA 1: Dùng '_id' (convert sang string) làm khóa để join
        let: { speakingSetId: '$_id' },

        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$speakingSetId', '$$speakingSetId'] },
                  { $eq: ['$userId', userObjectId] }
                ]
              }
            }
          },
          { $limit: 1 }
        ],
        as: 'enrollment'
      }
    },
    {
      $unwind: {
        path: '$enrollment',
        preserveNullAndEmptyArrays: true
      }
    },
    {
      $project: {
        // ⬇️ SỬA 2: Đổi tên '_id' (ObjectId) thành 'id' (String) cho Flutter DTO
        id: { $toString: '$_id' },

        // Dữ liệu từ SpeakingSet
        title: '$title',
        description: '$description',
        level: '$level',
        mode: '$mode',
        totalSentences: { $size: '$sentences' },

        // Dữ liệu từ Enrollment (giờ sẽ join đúng)
        progress: { $ifNull: ['$enrollment.progress', 0] },
        isCompleted: { $ifNull: ['$enrollment.isCompleted', false] },

        // (bestScore và isResumed giữ nguyên)
        bestScore: {
          $cond: {
            if: { $ifNull: ['$enrollment.averageWer', false] },
            then: {
              $round: [
                { $multiply: [ { $subtract: [1, '$enrollment.averageWer'] }, 100 ] },
                0
              ]
            },
            else: null
          }
        },
        isResumed: {
          $let: {
            vars: { prog: { $ifNull: ['$enrollment.progress', 0] } },
            in: {
              $and: [
                { $gt: [ "$$prog", 0 ] },
                { $lt: [ "$$prog", 1 ] }
              ]
            }
          }
        }
      }
    },
    { $sort: { title: 1 } },
    {
      $facet: {
        // ... (phân trang giữ nguyên)
        data: [
          { $skip: skip },
          { $limit: limit }
        ],
        pagination: [
          { $count: 'totalItems' },
          {
            $addFields: {
              totalPages: { $ceil: { $divide: ['$totalItems', limit] } },
              currentPage: page
            }
          }
        ]
      }
    },
    { $unwind: '$pagination' }
  ];
  const results = await SpeakingSet.aggregate(aggregation);
  if (results.length === 0) {
    return {
      data: [],
      pagination: {
        currentPage: page,
        totalPages: 0,
        totalItems: 0,
      }
    };
  }

  return results[0];
};

const getSetById = async (setId, userId) => {
  // ... (Phần này giữ nguyên, không thay đổi)
  // Kiểm tra ID hợp lệ
  if (!mongoose.Types.ObjectId.isValid(setId) || !mongoose.Types.ObjectId.isValid(userId)) {
    return null;
  }

  const userObjectId = new mongoose.Types.ObjectId(userId);
  const setObjectId = new mongoose.Types.ObjectId(setId);

  const aggregation = [
    {
      $match: { _id: setObjectId, _destroy: { $ne: true } }
    },
    {
      $lookup: {
        from: 'speakingenrollments',
        let: { speakingSetId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$speakingSetId', '$$speakingSetId'] },
                  { $eq: ['$userId', userObjectId] }
                ]
              }
            }
          },
          { $limit: 1 }
        ],
        as: 'enrollment'
      }
    },
    {
      $unwind: {
        path: '$enrollment',
        preserveNullAndEmptyArrays: true // Giữ set lại dù user chưa làm
      }
    },
    {
      $lookup: {
        from: 'speakingattempts',
        let: { speakingSetId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$speakingSetId', '$$speakingSetId'] },
                  { $eq: ['$userId', userObjectId] }
                ]
              }
            }
          },
          { $sort: { submittedAt: -1 } }, // Sắp xếp lịch sử, mới nhất lên đầu
          {
            $project: {
              _id: 0,
              sentenceId: '$sentenceId',
              userTranscript: '$userTranscript',
              wer: '$score.wer', // Lấy điểm WER
              submittedAt: '$submittedAt'
            }
          }
        ],
        as: 'userAttempts' // Sẽ là 1 mảng [ {sentenceId: 'a', wer: 0.1}, ... ]
      }
    },
    {
      $project: {
        id: { $toString: '$_id' },
        title: '$title',
        description: '$description',
        level: '$level',
        mode: '$mode',
        progress: { $ifNull: ['$enrollment.progress', 0] },
        isCompleted: { $ifNull: ['$enrollment.isCompleted', false] },
        sentences: {
          $map: {
            input: '$sentences', // Lặp qua mảng sentences gốc
            as: 'sentence',
            in: {
              id: '$$sentence.id',
              order: '$$sentence.order',
              speaker: '$$sentence.speaker',
              script: '$$sentence.script',
              phonetic_script: '$$sentence.phonetic_script',
              history: {
                $filter: {
                  input: '$userAttempts',
                  as: 'attempt',
                  cond: { $eq: ['$$attempt.sentenceId', '$$sentence.id'] }
                }
              }
            }
          }
        }
      }
    }
  ];
  const results = await SpeakingSet.aggregate(aggregation);
  if (results.length === 0) {
    return null;
  }
  return results[0];
};

const submitAttempt = async (userId, data) => {
  const {
    speakingSetId, // '_id' (String)
    sentenceId,
    userTranscript,
    userAudioUrl,
    score,
    audioDurationSeconds,
  } = data;

  const speakingSetObjectId = toSpeakingSetObjectId(speakingSetId);
  if (!speakingSetObjectId) {
    const err = new Error('Invalid speakingSetId');
    err.statusCode = 400;
    throw err;
  }

  const userObjectId = new mongoose.Types.ObjectId(userId);

  // 1. Lưu Attempt mới
  const newAttempt = new SpeakingAttempt({
    userId: userObjectId,
    speakingSetId: speakingSetObjectId,
    sentenceId: sentenceId,
    userTranscript: userTranscript,
    userAudioUrl: userAudioUrl,
    audioDurationSeconds: audioDurationSeconds,
    score: {
      wer: score.wer,
      confidence: score.confidence,
    },
    submittedAt: new Date(),
  });
  await newAttempt.save();

  // 2. Tìm hoặc tạo Enrollment (để lấy trạng thái cũ)
  let enrollment = await SpeakingEnrollment.findOne({
    userId: userObjectId,
    speakingSetId: speakingSetObjectId,
  });

  if (!enrollment) {
    enrollment = new SpeakingEnrollment({
      userId: userObjectId,
      speakingSetId: speakingSetObjectId,
      completedSentenceIds: [],
      progress: 0,
      isCompleted: false, // Trạng thái ban đầu
    });
  }

  // 🔥 Lưu trạng thái hoàn thành CŨ để so sánh
  const wasCompletedBefore = enrollment.isCompleted;

  // 3. Cập nhật danh sách câu đã hoàn thành
  if (!enrollment.completedSentenceIds.includes(sentenceId)) {
    enrollment.completedSentenceIds.push(sentenceId);
  }

  // 4. Tính toán Progress mới
  const set = await SpeakingSet.findById(speakingSetObjectId).select('sentences');
  const totalSentences = set ? set.sentences.length : 0;

  if (totalSentences > 0) {
    enrollment.progress = enrollment.completedSentenceIds.length / totalSentences;
  }

  // Cập nhật trạng thái hoàn thành MỚI
  if (enrollment.progress >= 1) {
    enrollment.isCompleted = true;
  }

  // 5. Tính điểm trung bình (WER)
  const attempts = await SpeakingAttempt.find({
    userId: userObjectId,
    speakingSetId: speakingSetObjectId,
  }).select('score.wer');

  if (attempts.length > 0) {
    const totalWer = attempts.reduce((sum, att) => sum + (att.score?.wer ?? 0), 0);
    enrollment.averageWer = totalWer / attempts.length;
  }

  enrollment.lastAccessedAt = new Date();
  await enrollment.save();

  // 🔥 6. Xác định xem bài học có VỪA MỚI hoàn thành hay không (để tránh cộng trùng)
  // Chỉ True nếu: Mới xong (isCompleted=true) VÀ Trước đó chưa xong (wasCompletedBefore=false)
  const isLessonJustFinished = enrollment.isCompleted && !wasCompletedBefore;

  // 7. Gamification & Tracking
  const activityData = {
    score: score,
    durationInSeconds: audioDurationSeconds,
    isLessonComplete: isLessonJustFinished // Gửi cờ đã lọc kỹ
  };
  updateGamificationStats(userId, 'speaking', activityData);

  // 8. Trả về kết quả
  const result = newAttempt.toObject();
  result.id = result._id.toString();
  // 🔥 Thêm trường này để Controller đọc được
  result.isLessonComplete = isLessonJustFinished;

  return result;
};
// 1. Admin List: Phân trang
const getAdminList = async (page, limit, level) => {
  const skip = (page - 1) * limit;
  const query = { _destroy: { $ne: true } };
  if (level && level !== 'all') {
    // Map level từ flutter (lowercase) sang backend (Capitalized) nếu cần
    // Ví dụ: 'beginner' -> 'Beginner'
    const levelMap = { beginner: 'Beginner', intermediate: 'Intermediate', advanced: 'Advanced' };
    query.level = levelMap[level.toLowerCase()] || level;
  }

  const totalDocs = await SpeakingSet.countDocuments(query);

  const data = await SpeakingSet.find(query)
    .select('title description level mode sentences') // Select các trường cần thiết
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
  const speakingSetIds = data.map((item) => item._id);
  const attemptsAgg = await SpeakingAttempt.aggregate([
    { $match: { speakingSetId: { $in: speakingSetIds } } },
    { $group: { _id: '$speakingSetId', attemptsCount: { $sum: 1 } } },
  ]);
  const attemptsMap = new Map(
    attemptsAgg.map((item) => [item._id.toString(), item.attemptsCount]),
  );

  const totalPages = Math.ceil(totalDocs / limit);

  return {
    data: data.map(item => ({
      ...item,
      id: item._id.toString(), // Convert _id -> id cho Flutter
      totalSentences: item.sentences ? item.sentences.length : 0,
      attemptsCount: attemptsMap.get(item._id.toString()) ?? 0,
      adminStatus: 'published',
    })),
    pagination: { total: totalDocs, limit, page, totalPages }
  };
};

// 2. Admin Detail
const getAdminDetail = async (id) => {
  const set = await SpeakingSet.findById(id).lean();
  if (!set) return null;
  return { ...set, id: set._id.toString() };
};

// 3. Admin Create
const createSpeakingSet = async (payload) => {
  // Payload: { title, description, level, mode, sentences: [...] }
  const newSet = new SpeakingSet(payload);
  const saved = await newSet.save();
  return { ...saved.toObject(), id: saved._id.toString() };
};

// 4. Admin Update
const updateSpeakingSet = async (id, payload) => {
  const updated = await SpeakingSet.findByIdAndUpdate(id, payload, { new: true }).lean();
  if (!updated) return null;
  return { ...updated, id: updated._id.toString() };
};

// 5. Admin Delete
const deleteSpeakingSet = async (id) => {
  return await SpeakingSet.findByIdAndUpdate(
    id,
    { $set: { _destroy: true, deletedAt: new Date() } },
    { new: true }
  );
};

const getDeletedSpeakingSets = async (page = 1, limit = 50) => {
  const skip = (page - 1) * limit;
  const query = { _destroy: true };
  const totalDocs = await SpeakingSet.countDocuments(query);
  const data = await SpeakingSet.find(query)
    .sort({ deletedAt: -1, updatedAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
  return {
    data: data.map((item) => ({ ...item, id: item._id.toString() })),
    pagination: { total: totalDocs, limit, page, totalPages: Math.ceil(totalDocs / limit) },
  };
};

const restoreSpeakingSet = async (id) => {
  return await SpeakingSet.findByIdAndUpdate(
    id,
    { $set: { _destroy: false, deletedAt: null } },
    { new: true }
  );
};

const evaluateConversation = async (userId, data = {}) => {
  const payload = parseOrThrow(evaluateConversationSchema, data);
  const userObjectId = toObjectId(userId);
  const turns = cleanConversationTurns(payload.turns);
  const durationSeconds = Math.max(0, Math.round(Number(payload.durationSeconds) || 0));
  const stats = computeStats(turns, durationSeconds);
  let scenario = null;

  if (payload.scenarioId) {
    if (!mongoose.Types.ObjectId.isValid(payload.scenarioId)) {
      const err = new Error('Invalid scenarioId');
      err.statusCode = 400;
      throw err;
    }
    scenario = await SpeakingScenario.findOne({
      _id: toObjectId(payload.scenarioId),
      isActive: true,
      _destroy: { $ne: true },
    }).lean();
    if (!scenario) {
      const err = new Error('Speaking scenario not found');
      err.statusCode = 404;
      throw err;
    }
  }

  if (isConversationTooShort(stats)) {
    const err = new Error('Conversation is too short for feedback');
    err.statusCode = 422;
    err.code = 'TOO_SHORT';
    err.details = {
      minTurns: MIN_TURNS_FOR_FEEDBACK,
      minDurationSec: MIN_DURATION_SEC_FOR_FEEDBACK,
      stats,
    };
    throw err;
  }

  const conversation = await SpeakingConversation.create({
    userId: userObjectId,
    mode: 'freeSpeaking',
    scenario: scenario?.slug || null,
    scenarioId: scenario?._id || null,
    scenarioSnapshot: scenarioSnapshot(scenario),
    level: payload.level || scenario?.levelSuggested || null,
    turns,
    wordCount: stats.words,
    durationSeconds,
    status: 'evaluating',
    startedAt: payload.startedAt ? new Date(payload.startedAt) : undefined,
    endedAt: payload.endedAt ? new Date(payload.endedAt) : new Date(),
  });

  try {
    const feedback = await aiService.generateSpeakingFeedback({
      turns,
      level: payload.level || scenario?.levelSuggested || null,
      stats,
      scenario,
    });
    const previous = await getPreviousReviewedConversation(userObjectId, conversation._id);
    feedback.trends = buildTrendPayload(feedback, previous?.feedback);
    if (scenario && !feedback.scenarioTitle) {
      feedback.scenarioTitle = scenario.title;
    }

    conversation.feedback = feedback;
    conversation.score = feedback.overall;
    conversation.status = 'reviewed';
    await conversation.save();

    await trackUserProgress(userId, 'speaking', {
      duration: durationSeconds,
      score: (feedback.overall || 0) / 9,
      metric: 'fluency',
      isLessonJustFinished: true,
    });
    await updateGamificationStats(userId, 'speaking', {
      durationInSeconds: durationSeconds,
      score: feedback.overall,
      isLessonComplete: true,
      isFreeSpeakingConversation: true,
    });

    return serializeConversation(conversation);
  } catch (error) {
    // Persist the failure WITHOUT re-saving the (possibly malformed) feedback,
    // so a bad-feedback save cannot throw again and leak a raw error to the client.
    conversation.status = 'failed';
    conversation.errorMessage = error?.message || 'AI feedback failed';
    conversation.feedback = undefined;
    await SpeakingConversation.updateOne(
      { _id: conversation._id },
      { $set: { status: 'failed', errorMessage: conversation.errorMessage }, $unset: { feedback: 1 } },
    );

    const err = new Error('AI feedback failed');
    err.statusCode = 502;
    err.code = 'AI_FAILED';
    err.conversation = serializeConversation(conversation);
    throw err;
  }
};

const getScenarios = async (query = {}) => {
  const payload = parseOrThrow(scenarioQuerySchema, query);
  const filter = { isActive: true, _destroy: { $ne: true } };
  if (payload.group) filter.group = payload.group;
  if (payload.level) filter.levelSuggested = payload.level;

  const scenarios = await SpeakingScenario.find(filter)
    .select('slug title description group levelSuggested goals roleForAI firstMessage successCriteria starterHints sortOrder')
    .sort({ group: 1, sortOrder: 1, title: 1 })
    .limit(payload.limit)
    .lean();

  return {
    data: scenarios.map((item) => ({
      ...item,
      id: item._id.toString(),
    })),
  };
};

const getProgressSummary = async (userId, query = {}) => {
  const payload = parseOrThrow(summaryQuerySchema, query);
  const { user, timezone, startDate, endDate, days } =
    await dateRangeForSummary(userId, payload.range);
  const userObjectId = toObjectId(userId);

  const previousStart = new Date(startDate.getTime() - days * 24 * 60 * 60 * 1000);
  const conversations = await SpeakingConversation.find({
    userId: userObjectId,
    status: 'reviewed',
    createdAt: { $gte: previousStart, $lte: endDate },
  })
    .select('createdAt durationSeconds feedback.overall feedback.fc feedback.lr feedback.gra feedback.ia feedback.stats.wpm scenarioSnapshot.title score')
    .sort({ createdAt: 1 })
    .lean();

  const current = conversations.filter((item) => item.createdAt >= startDate);
  const previous = conversations.filter((item) => item.createdAt < startDate);
  const labels = [];
  const overallByDay = new Map();
  const wpmByDay = new Map();
  const minutesByDay = new Map();

  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(endDate.getTime() - i * 24 * 60 * 60 * 1000);
    const key = normalizeDateKey(d, timezone);
    labels.push(key.slice(5));
    overallByDay.set(key, []);
    wpmByDay.set(key, []);
    minutesByDay.set(key, 0);
  }

  current.forEach((item) => {
    const key = normalizeDateKey(item.createdAt, timezone);
    if (!overallByDay.has(key)) return;
    overallByDay.get(key).push(item.feedback?.overall ?? item.score ?? 0);
    wpmByDay.get(key).push(item.feedback?.stats?.wpm ?? 0);
    minutesByDay.set(key, (minutesByDay.get(key) || 0) + Math.round((item.durationSeconds || 0) / 60));
  });

  const currentAvg = {
    overall: avg(current, (item) => item.feedback?.overall ?? item.score),
    fc: avg(current, (item) => item.feedback?.fc),
    lr: avg(current, (item) => item.feedback?.lr),
    gra: avg(current, (item) => item.feedback?.gra),
    ia: avg(current, (item) => item.feedback?.ia),
  };
  const previousAvg = previous.length ? {
    overall: avg(previous, (item) => item.feedback?.overall ?? item.score),
    fc: avg(previous, (item) => item.feedback?.fc),
    lr: avg(previous, (item) => item.feedback?.lr),
    gra: avg(previous, (item) => item.feedback?.gra),
    ia: avg(previous, (item) => item.feedback?.ia),
  } : null;

  const dayKeys = Array.from(overallByDay.keys());
  return {
    range: payload.range,
    totals: {
      sessions: current.length,
      minutes: current.reduce((sum, item) => sum + Math.round((item.durationSeconds || 0) / 60), 0),
      bestOverall: current.reduce((max, item) => Math.max(max, item.feedback?.overall ?? item.score ?? 0), 0),
      speakingStreak: user?.speakingStreak || 0,
      xp: user?.totalPoints || 0,
      badges: user?.speakingBadges || [],
    },
    averages: {
      ...currentAvg,
      wpm: avg(current, (item) => item.feedback?.stats?.wpm),
    },
    trends: buildTrendPayload(currentAvg, previousAvg),
    chart: {
      labels,
      overall: dayKeys.map((key) => avg(overallByDay.get(key) || [], (v) => v)),
      wpm: dayKeys.map((key) => Math.round(avg(wpmByDay.get(key) || [], (v) => v))),
      minutes: dayKeys.map((key) => minutesByDay.get(key) || 0),
    },
    recent: current.slice(-8).reverse().map((item) => ({
      id: item._id.toString(),
      createdAt: item.createdAt,
      title: item.scenarioSnapshot?.title || 'Free chat',
      overall: item.feedback?.overall ?? item.score ?? null,
      wpm: item.feedback?.stats?.wpm ?? 0,
      durationSeconds: item.durationSeconds || 0,
    })),
  };
};

const getNotebook = async (userId, query = {}) => {
  const payload = parseOrThrow(notebookQuerySchema, query);
  const conversations = await SpeakingConversation.find({
    userId: toObjectId(userId),
    status: 'reviewed',
  })
    .select('createdAt scenarioSnapshot.title feedback.corrections feedback.improvements feedback.vocabUpgrades')
    .sort({ createdAt: -1 })
    .limit(payload.limit)
    .lean();

  const corrections = [];
  const vocab = [];
  const repeatMap = new Map();

  conversations.forEach((conversation) => {
    const source = {
      conversationId: conversation._id.toString(),
      createdAt: conversation.createdAt,
      title: conversation.scenarioSnapshot?.title || 'Free chat',
    };
    (conversation.feedback?.corrections || []).forEach((item) => {
      if (!item?.before && !item?.after) return;
      const row = { ...item, source };
      corrections.push(row);
      const key = `${(item.type || 'grammar').toLowerCase()}::${(item.before || '').trim().toLowerCase()}`;
      if (!repeatMap.has(key)) {
        repeatMap.set(key, {
          type: item.type || 'grammar',
          before: item.before || '',
          after: item.after || '',
          reason: item.reason || '',
          count: 0,
          lastSeenAt: conversation.createdAt,
        });
      }
      const entry = repeatMap.get(key);
      entry.count += 1;
      if (conversation.createdAt > entry.lastSeenAt) entry.lastSeenAt = conversation.createdAt;
    });
    (conversation.feedback?.improvements || []).forEach((item) => {
      if (!item?.before && !item?.after) return;
      corrections.push({
        type: 'improvement',
        before: item.before || '',
        after: item.after || '',
        reason: item.explain || item.issue || '',
        source,
      });
    });
    (conversation.feedback?.vocabUpgrades || []).forEach((item) => {
      if (!item?.better && !item?.said) return;
      vocab.push({ ...item, source });
    });
  });

  return {
    totals: {
      conversations: conversations.length,
      corrections: corrections.length,
      vocab: vocab.length,
      repeatedErrors: Array.from(repeatMap.values()).filter((item) => item.count > 1).length,
    },
    repeatedErrors: Array.from(repeatMap.values())
      .filter((item) => item.count > 1)
      .sort((a, b) => b.count - a.count || new Date(b.lastSeenAt) - new Date(a.lastSeenAt))
      .slice(0, 20),
    corrections: corrections.slice(0, 60),
    vocab: vocab.slice(0, 60),
  };
};

const getConversationHistory = async (userId, { limit = 20, cursor } = {}) => {
  const safeLimit = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
  const query = { userId: toObjectId(userId), status: 'reviewed' };
  if (cursor && mongoose.Types.ObjectId.isValid(cursor)) {
    query._id = { $lt: toObjectId(cursor) };
  }

  const conversations = await SpeakingConversation.find(query)
    .select('createdAt durationSeconds scenarioSnapshot.title feedback.overall feedback.cefr feedback.stats.turnCount score')
    .sort({ _id: -1 })
    .limit(safeLimit + 1)
    .lean();

  const hasMore = conversations.length > safeLimit;
  const data = conversations.slice(0, safeLimit).map((item) => ({
    id: item._id.toString(),
    createdAt: item.createdAt,
    overall: item.feedback?.overall ?? item.score ?? null,
    cefr: item.feedback?.cefr ?? null,
    title: item.scenarioSnapshot?.title || 'Free chat',
    durationSeconds: item.durationSeconds ?? 0,
    turnCount: item.feedback?.stats?.turnCount ?? 0,
  }));

  return {
    data,
    pagination: {
      limit: safeLimit,
      nextCursor: hasMore ? data[data.length - 1]?.id ?? null : null,
      hasMore,
    },
  };
};

const getConversationById = async (userId, id) => {
  if (!mongoose.Types.ObjectId.isValid(id)) return null;
  const conversation = await SpeakingConversation.findOne({
    _id: toObjectId(id),
    userId: toObjectId(userId),
  }).lean();
  return serializeConversation(conversation);
};

export const speakingService = {
  getSetsWithProgress,
  getSetById,
  submitAttempt,
  evaluateConversation,
  getConversationHistory,
  getConversationById,
  getScenarios,
  getProgressSummary,
  getNotebook,
  computeStats,
  getAdminList,
  getAdminDetail,
  createSpeakingSet,
  updateSpeakingSet,
  deleteSpeakingSet,
  getDeletedSpeakingSets,
  restoreSpeakingSet,
};
