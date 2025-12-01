import mongoose from 'mongoose';
import Listening from '../models/Listening.js';
import Enrollment from '../models/Enrollment.js';
import DictationAttempt from '../models/DictationAttempt.js';

// ============================================================
// 🛠 HELPER: Chuẩn hóa nghiêm ngặt (Chỉ bỏ dấu câu & Case)
// ============================================================
const normalize = (s = '') => {
  return String(s)
    .toLowerCase()                         // 1. Chuyển thành chữ thường
    .replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?"'’]/g, "") // 2. Xóa sạch các dấu câu phổ biến
    .replace(/\s{2,}/g, " ")               // 3. Biến nhiều dấu cách thành 1 dấu cách
    .trim();                               // 4. Cắt khoảng trắng đầu cuối
};

// ============================================================
// 1. GET DETAIL
// ============================================================
const getListeningById = async (id) => {
  return await Listening.findById(id).lean();
};

// ============================================================
// 2. GET LIST
// ============================================================
const getAllListenings = async (userId, filters, page = 1, limit = 10) => {
  const query = {};

  if (filters.difficulty && filters.difficulty !== 'all') {
    query.difficulty = filters.difficulty;
  }

  if (filters.q) {
    const keyword = filters.q.trim();
    query.$or = [
      { title: { $regex: keyword, $options: 'i' } },
      { code: { $regex: keyword, $options: 'i' } },
    ];
  }

  const skip = (page - 1) * limit;
  const totalDocs = await Listening.countDocuments(query);

  const docs = await Listening.find(query)
    .select('-cues.textNorm -cues.text')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

  let data = docs;
  if (userId) {
    const listeningIds = docs.map((d) => d._id);
    const enrollments = await Enrollment.find(
      { userId, listeningId: { $in: listeningIds } },
      { listeningId: 1, progress: 1 }
    ).lean();

    const progressMap = new Map(
      enrollments.map((e) => [e.listeningId.toString(), e.progress])
    );

    data = docs.map((doc) => ({
      ...doc,
      userProgress: progressMap.get(doc._id.toString()) || 0,
      isCompleted: (progressMap.get(doc._id.toString()) || 0) >= 1,
    }));
  }

  return {
    data,
    pagination: {
      total: totalDocs,
      page,
      limit,
      totalPages: Math.ceil(totalDocs / limit),
    },
  };
};

// ============================================================
// 3. HISTORY
// ============================================================
const getAttempts = async (userId, listeningId, isLatest = true) => {
  const matchStage = {
    listeningId: new mongoose.Types.ObjectId(listeningId),
    userId: new mongoose.Types.ObjectId(userId),
  };

  if (isLatest) {
    return await DictationAttempt.aggregate([
      { $match: matchStage },
      { $sort: { submittedAt: -1, _id: -1 } },
      { $group: { _id: '$cueIdx', doc: { $first: '$$ROOT' } } },
      { $replaceRoot: { newRoot: '$doc' } },
      { $sort: { cueIdx: 1 } },
      {
        $project: {
          _id: 1, cueIdx: 1, cueId: 1, userText: 1, submittedAt: 1,
          'score.wer': 1, 'score.passed': 1,
        },
      },
    ]);
  } else {
    return await DictationAttempt.find(matchStage)
      .sort({ submittedAt: -1 })
      .lean();
  }
};

// ============================================================
// 4. SUBMIT (SO SÁNH TUYỆT ĐỐI SAU KHI BỎ DẤU CÂU)
// ============================================================
const submitAttempt = async (userId, payload) => {
  const { listeningId, answers, durationInSeconds } = payload;
  const now = new Date();

  // A. Lấy đề bài
  const listening = await Listening.findById(listeningId).select('cues').lean();
  if (!listening) throw new Error('Listening not found');

  // Sắp xếp cues theo startMs (đảm bảo index khớp Frontend)
  const cues = (listening.cues || []).sort((a, b) => (a.startMs || 0) - (b.startMs || 0));

  // B. Lưu câu trả lời mới
  if (userId && Array.isArray(answers) && answers.length > 0) {
    const bulkOps = answers
      .map((ans) => {
        // Tìm câu hỏi trong DB dựa trên ID mà Flutter gửi lên
        const cueIdx = cues.findIndex((c) => c._id.toString() === ans.cueId);

        if (cueIdx === -1) return null;

        const cue = cues[cueIdx];

        // 🟢 LOGIC CHẤM ĐIỂM: SO SÁNH CHUỖI TUYỆT ĐỐI
        const userNorm = normalize(ans.value);
        const correctNorm = normalize(cue.text);

        // Chỉ đúng khi 2 chuỗi (sau khi bỏ dấu câu) giống hệt nhau
        const isCorrect = userNorm === correctNorm;

        // Debug Log xem tại sao sai/đúng
        if (!isCorrect) {
          console.log(`[WRONG] User: "${userNorm}" vs Correct: "${correctNorm}"`);
        }

        return {
          updateOne: {
            filter: { userId, listeningId, cueIdx },
            update: {
              $set: {
                cueId: cue._id.toString(),
                userText: ans.value,
                userTextNorm: userNorm,
                score: {
                  passed: isCorrect,
                  wer: isCorrect ? 0 : 1 // Đúng là 0, sai là 1
                },
                submittedAt: now,
                durationInSeconds: durationInSeconds,
              },
              $inc: { attemptsCount: 1 },
              $setOnInsert: { firstSubmittedAt: now },
            },
            upsert: true,
          },
        };
      })
      .filter((op) => op !== null);

    if (bulkOps.length > 0) {
      await DictationAttempt.bulkWrite(bulkOps);
    }
  }

  // C. Load lại lịch sử
  const historyMap = new Map();
  if (userId) {
    const attempts = await DictationAttempt.find({ userId, listeningId }).lean();
    attempts.forEach((att) => historyMap.set(att.cueIdx, att));
  }

  // D. Tổng hợp kết quả
  let correctCount = 0;
  const detailResult = [];

  cues.forEach((cue, index) => {
    const attempt = historyMap.get(index);
    const userValueRaw = attempt ? attempt.userText : '';

    let isCorrect = false;
    if (attempt && attempt.score) {
      isCorrect = attempt.score.passed;
    }

    if (isCorrect) correctCount++;

    detailResult.push({
      cueId: cue._id,
      cueIdx: index,
      userValue: userValueRaw,
      correctValue: cue.text,
      isCorrect,
    });
  });

  // E. Update Enrollment
  const totalCues = cues.length;
  const isLessonJustFinished = await _handleEnrollmentUpdate(
    userId, listeningId, totalCues, detailResult
  );

  return {
    listeningId,
    totalCues,
    correctCount,
    score: totalCues > 0 ? correctCount / totalCues : 0,
    isCompleted: isLessonJustFinished,
    details: detailResult,
  };
};

// Helper update enrollment (Giữ nguyên)
const _handleEnrollmentUpdate = async (userId, listeningId, totalCues, detailResult) => {
  if (!userId) return false;
  let isJustFinished = false;
  const correctCueIds = detailResult.filter((d) => d.isCorrect).map((d) => d.cueId);

  const enr = await Enrollment.findOneAndUpdate(
    { userId, listeningId },
    {
      $setOnInsert: { progress: 0, isCompleted: false, createdAt: new Date() },
      $set: { lastAccessedAt: new Date() },
      $addToSet: { completedCueIds: { $each: correctCueIds } },
    },
    { upsert: true, new: true }
  );

  const updatedEnr = await Enrollment.findById(enr._id).select('completedCueIds').lean();
  const doneCount = updatedEnr.completedCueIds ? updatedEnr.completedCueIds.length : 0;
  const progress = totalCues > 0 ? Math.min(1, doneCount / totalCues) : 0;
  const isNowCompleted = progress >= 1.0;

  await Enrollment.updateOne({ _id: enr._id }, { $set: { progress: progress } });

  if (isNowCompleted) {
    const result = await Enrollment.updateOne(
      { _id: enr._id, isCompleted: false },
      { $set: { isCompleted: true } }
    );
    if (result.modifiedCount > 0) {
      isJustFinished = true;
    }
  }

  return isJustFinished;
};

// ============================================================
// 5. ADMIN (Giữ nguyên)
// ============================================================
const createListening = async (payload) => {
  if (payload.cues && Array.isArray(payload.cues)) {
    payload.cues = payload.cues.map((cue) => ({
      ...cue,
      textNorm: cue.textNorm || normalize(cue.text),
    }));
    payload.totalCues = payload.cues.length;
  }
  return await Listening.create(payload);
};

const updateListening = async (id, payload) => {
  if (Array.isArray(payload.cues)) {
    payload.totalCues = payload.cues.length;
    payload.cues = payload.cues.map((cue) => ({
      ...cue,
      textNorm: cue.textNorm || normalize(cue.text),
    }));
  }
  return await Listening.findByIdAndUpdate(id, payload, { new: true });
};

const deleteListening = async (id) => {
  await DictationAttempt.deleteMany({ listeningId: id });
  return await Listening.findByIdAndDelete(id);
};

export const listeningService = {
  getListeningById,
  getAllListenings,
  getAttempts,
  submitAttempt,
  createListening,
  updateListening,
  deleteListening,
};