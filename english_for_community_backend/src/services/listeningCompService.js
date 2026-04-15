import mongoose from 'mongoose';
import ListeningComprehension from '../models/ListeningComprehension.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import { cloudinary } from '../config/cloudinary.js';

const getListeningById = async (id) => {
  return await ListeningComprehension.findById(id).lean();
};

const getAllListenings = async (userId, filters, page = 1, limit = 10) => {
  const query = { _destroy: { $ne: true } };

  if (filters.difficulty) query.difficulty = filters.difficulty;
  if (filters.q) {
    const keyword = filters.q.trim();
    query.$or = [{ title: { $regex: keyword, $options: 'i' } }];
  }

  const skip = (page - 1) * limit;
  const totalDocs = await ListeningComprehension.countDocuments(query);

  // Không lấy 'questions' và 'transcript' ở màn hình list để tối ưu tốc độ tải
  const docs = await ListeningComprehension.find(query)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
  const listeningIds = docs.map((d) => d._id);
  const attemptsAgg = await ListeningCompAttempt.aggregate([
    { $match: { listeningId: { $in: listeningIds } } },
    { $group: { _id: '$listeningId', attemptsCount: { $sum: 1 } } },
  ]);
  const attemptsMap = new Map(
    attemptsAgg.map((item) => [item._id.toString(), item.attemptsCount]),
  );

  let data = docs;

  // Nếu user đã đăng nhập, tính điểm cao nhất và trạng thái từ bảng Attempt
  if (userId && docs.length > 0) {
    const listeningIds = docs.map((d) => d._id);

    // Group by listeningId và tìm max score
    const userAttempts = await ListeningCompAttempt.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          listeningId: { $in: listeningIds }
        }
      },
      {
        $group: {
          _id: '$listeningId',
          highScore: { $max: '$score' },
          attemptsCount: { $sum: 1 }
        }
      }
    ]);

    const progressMap = new Map(
      userAttempts.map((a) => [a._id.toString(), a])
    );

    data = docs.map((doc) => {
      const progress = progressMap.get(doc._id.toString());
      return {
        ...doc,
        // Trả về số lượng câu hỏi thực tế trước khi ẩn mảng questions đi
        totalQuestions: doc.questions ? doc.questions.length : 0,
        // Ẩn mảng questions và transcript để gửi về client nhẹ hơn
        questions: undefined,
        transcript: undefined,
        userProgress: progress ? 1 : 0,
        highScore: progress ? progress.highScore : 0,
        attemptsCount: attemptsMap.get(doc._id.toString()) ?? 0,
        adminStatus: 'published',
      };
    });
  } else {
    data = docs.map((doc) => ({
      ...doc,
      totalQuestions: doc.questions ? doc.questions.length : 0,
      questions: undefined,
      transcript: undefined,
      attemptsCount: attemptsMap.get(doc._id.toString()) ?? 0,
      adminStatus: 'published',
    }));
  }

  return {
    data,
    pagination: {
      total: totalDocs, page, limit, totalPages: Math.ceil(totalDocs / limit),
    },
  };
};

const getAttempts = async (userId, listeningId) => {
  return await ListeningCompAttempt.find({ userId, listeningId })
    .sort({ createdAt: -1 })
    .lean();
};

const submitAttempt = async (userId, payload) => {
  const { listeningId, answers, durationInSeconds } = payload;

  const listening = await ListeningComprehension.findById(listeningId).lean();
  if (!listening) throw new Error('Listening Comprehension not found');

  const questions = listening.questions || [];
  const totalQuestions = questions.length;
  let correctCount = 0;

  // Xử lý logic chấm điểm
  const evaluatedAnswers = (answers || []).map((ans) => {
    const question = questions.find((q) => q._id.toString() === ans.questionId);

    let isCorrect = false;
    if (question && ans.chosenIndex !== -1) {
      isCorrect = question.correctAnswerIndex === ans.chosenIndex;
    }

    if (isCorrect) correctCount++;

    return {
      questionId: ans.questionId,
      chosenIndex: ans.chosenIndex,
      isCorrect: isCorrect
    };
  });

  const score = totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0;

  // 🔥 THÊM LOGIC TRACKING: Kiểm tra xem user đã làm bài này bao giờ chưa
  const previousAttempts = await ListeningCompAttempt.countDocuments({ userId, listeningId });
  const isLessonJustFinished = previousAttempts === 0; // Nếu = 0 tức là lần đầu tiên hoàn thành

  // Lưu record
  const newAttempt = await ListeningCompAttempt.create({
    userId,
    listeningId,
    answers: evaluatedAnswers,
    score,
    correctCount,
    totalQuestions,
    durationInSeconds: durationInSeconds || 0
  });

  // Trả về kèm cờ isLessonJustFinished để Controller gọi ProgressTracker
  return {
    attempt: newAttempt,
    isLessonJustFinished
  };
};

// ============================================================
// ADMIN FUNCTIONS
// ============================================================

const createListening = async (payload) => {
  return await ListeningComprehension.create(payload);
};

const updateListening = async (id, payload) => {
  return await ListeningComprehension.findByIdAndUpdate(id, payload, { new: true });
};

const getPublicIdFromUrl = (url) => {
  try {
    if (!url) return null;
    const regex = /\/upload\/(?:v\d+\/)?(.+)\.[^.]+$/;
    const match = url.match(regex);
    if (match && match[1]) return match[1];
    return null;
  } catch (e) {
    return null;
  }
};

const deleteListening = async (id) => {
  const listening = await ListeningComprehension.findById(id);
  if (!listening) return null;

  // Xóa toàn bộ lịch sử làm bài liên quan khi xóa bài
  await ListeningCompAttempt.deleteMany({ listeningId: id });

  // Xóa file Audio trên Cloudinary
  if (listening.audioUrl) {
    const publicId = getPublicIdFromUrl(listening.audioUrl);
    if (publicId) {
      try {
        await cloudinary.uploader.destroy(publicId, { resource_type: 'video' });
      } catch (err) {
        console.error("Cloudinary delete error:", err);
      }
    }
  }

  return await ListeningComprehension.findByIdAndUpdate(
    id,
    { $set: { _destroy: true, deletedAt: new Date() } },
    { new: true }
  );
};

const getDeletedListenings = async (page = 1, limit = 50) => {
  const skip = (page - 1) * limit;
  const query = { _destroy: true };
  const totalDocs = await ListeningComprehension.countDocuments(query);
  const data = await ListeningComprehension.find(query)
    .sort({ deletedAt: -1, updatedAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
  return {
    data,
    pagination: {
      total: totalDocs,
      limit,
      page,
      totalPages: Math.ceil(totalDocs / limit),
    },
  };
};

const restoreListening = async (id) => {
  return await ListeningComprehension.findByIdAndUpdate(
    id,
    { $set: { _destroy: false, deletedAt: null } },
    { new: true }
  );
};

export const listeningCompService = {
  getListeningById, getAllListenings, getAttempts, submitAttempt,
  createListening, updateListening, deleteListening,
  getDeletedListenings, restoreListening,
};