// lib/services/speakingService.js
import SpeakingSet from '../models/SpeakingSet.js';
import mongoose from 'mongoose';
import SpeakingAttempt from "../models/SpeakingAttempt.js";
import SpeakingEnrollment from "../models/SpeakingEnrollment.js";
import {updateGamificationStats} from "./gamificationService.js";

const getSetsWithProgress = async (userId, filters, options) => {
  // ... (Phần này giữ nguyên, không thay đổi)
  const { mode, level } = filters;
  const { page, limit } = options;
  const skip = (page - 1) * limit;
  const matchConditions = {};
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
        let: { speakingSetIdStr: { $toString: '$_id' } },

        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  // So sánh với speakingSetId (String) trong Enrollment
                  { $eq: ['$speakingSetId', '$$speakingSetIdStr'] },
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
      $match: { _id: setObjectId }
    },
    {
      $lookup: {
        from: 'speakingenrollments',
        let: { setIdStr: { $toString: '$_id' } },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$speakingSetId', '$$setIdStr'] },
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
        let: { setIdStr: { $toString: '$_id' } },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$speakingSetId', '$$setIdStr'] },
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

  const userObjectId = new mongoose.Types.ObjectId(userId);

  // 1. Lưu Attempt mới
  const newAttempt = new SpeakingAttempt({
    userId: userObjectId,
    speakingSetId: speakingSetId,
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
    speakingSetId: speakingSetId,
  });

  if (!enrollment) {
    enrollment = new SpeakingEnrollment({
      userId: userObjectId,
      speakingSetId: speakingSetId,
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
  const set = await SpeakingSet.findById(speakingSetId).select('sentences');
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
    speakingSetId: speakingSetId,
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
  const query = {};
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

  const totalPages = Math.ceil(totalDocs / limit);

  return {
    data: data.map(item => ({
      ...item,
      id: item._id.toString(), // Convert _id -> id cho Flutter
      totalSentences: item.sentences ? item.sentences.length : 0
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
  return await SpeakingSet.findByIdAndDelete(id);
};
export const speakingService = {
  getSetsWithProgress,
  getSetById,
  submitAttempt,
  getAdminList,
  getAdminDetail,
  createSpeakingSet,
  updateSpeakingSet,
  deleteSpeakingSet
};