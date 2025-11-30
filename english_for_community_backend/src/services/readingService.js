// lib/services/readingService.js
import Reading from '../models/Reading.js';
import ReadingProgress from '../models/ReadingProgress.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import {updateGamificationStats} from "./gamificationService.js";

// ... existing code (getAllReadings) ...
const getAllReadings = async (userId, difficulty, page, limit) => {
  const skip = (page - 1) * limit;

  const query = {};
  if (difficulty && difficulty !== 'all') {
    query.difficulty = difficulty;
  }
  const totalDocs = await Reading.countDocuments(query);
  const allReadings = await Reading.find(query)
    .sort({ createdAt: 1 })
    .skip(skip)
    .limit(limit)
    .lean();
  const userProgress = await ReadingProgress.find({ userId }).lean();
  const progressMap = new Map();
  for (const progress of userProgress) {
    progressMap.set(progress.readingId.toString(), progress);
  }
  const resultsData = allReadings.map(reading => {
    const progress = progressMap.get(reading._id.toString());
    return {
      ...reading,
      progress: progress || null,
    };
  });
  const totalPages = Math.ceil(totalDocs / limit);
  const pagination = {
    total: totalDocs,
    limit: limit,
    page: page,
    totalPages: totalPages,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1
  };
  return {
    data: resultsData,
    pagination: pagination
  };
};

// 👇 1. THÊM HÀM TẠO MỚI
const createReading = async (payload) => {
  // Payload sẽ chứa: title, content, questions, translation, etc.
  // Mongoose sẽ tự validate các trường required dựa trên Schema
  const newReading = new Reading(payload);
  return await newReading.save();
};

// ... existing code (submitAttempt) ...
const submitAttempt = async (userId, payload) => {
  const newAttempt = new ReadingAttempt({
    userId,
    readingId: payload.readingId,
    answers: payload.answers,
    score: payload.score,
    correctCount: payload.correctCount,
    totalQuestions: payload.totalQuestions,
    durationInSeconds: payload.durationInSeconds,
  });
  const savedAttempt = await newAttempt.save();
  updateGamificationStats(userId, 'reading', payload);
  await ReadingProgress.findOneAndUpdate(
    { userId, readingId: savedAttempt.readingId },
    {
      $set: {
        status: 'completed',
        lastAttemptedAt: new Date()
      },
      $inc: { attemptsCount: 1 },
      $max: { highScore: savedAttempt.score }
    },
    { upsert: true, new: true }
  );

  return {
    ...savedAttempt.toObject(),  // hoặc savedAttempt._doc
    isCompleted: true            // QUAN TRỌNG NHẤT
  };
};

const deleteReading = async (id) => {
  // Có thể cần xóa các dữ liệu liên quan (như Progress) nếu cần thiết
  // await ReadingProgress.deleteMany({ readingId: id });

  return await Reading.findByIdAndDelete(id);
};const getAttemptHistory = async (userId, readingId) => {
  const history = await ReadingAttempt.find({ userId, readingId })
    .sort({ createdAt: -1 })
    .lean();

  return history;
};
const getReadingById = async (id) => {
  // Sử dụng lean() để trả về object JS thuần (nhanh hơn)
  const reading = await Reading.findById(id).lean();
  return reading;
};
// ✍️ Cập nhật export
export const readingService = {
  getAllReadings,
  createReading, // 👈 Export hàm mới
  submitAttempt,
  getAttemptHistory,
  getReadingById,
  deleteReading
};