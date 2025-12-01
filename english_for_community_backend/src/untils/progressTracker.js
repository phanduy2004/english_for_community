// src/utils/progressTracker.js
import UserDailyProgress from '../models/UserDailyProgress.js';
import User from '../models/User.js';

/**
 * @param {string} userId
 * @param {string} type - 'reading', 'dictation', 'speaking', 'writing'
 * @param {object} data
 * - duration: number (giây) -> Luôn cộng
 * - score: number (0-1 hoặc điểm) -> Luôn cộng để tính trung bình
 * - isLessonJustFinished: boolean -> ⚠️ QUAN TRỌNG: Chỉ khi = true mới cộng lesson count
 */
export const trackUserProgress = async (userId, type, data = {}) => {
  try {
    // 1. Lấy timezone (cache hoặc query nhẹ)
    const user = await User.findById(userId).select('timezone').lean();
    const timezone = user?.timezone || 'Asia/Ho_Chi_Minh';

    const todayStr = new Date().toLocaleDateString('en-CA', { timeZone: timezone });

    // 2. Luôn cộng thời gian học (duration)
    const updateOps = {
      $inc: { studySeconds: data.duration || 0 }
    };

    // 3. Xử lý riêng cho từng kỹ năng
    if (type === 'reading') {
      // Chỉ cộng bài hoàn thành nếu Controller báo là vừa mới xong
      if (data.isLessonJustFinished) {
        updateOps.$inc['lessonsCompleted.reading'] = 1;
      }

      // Cộng điểm để tính trung bình
      if (data.score != null) {
        updateOps.$inc['stats.readingAccuracy.total'] = data.score;
        updateOps.$inc['stats.readingAccuracy.count'] = 1;
      }
      if (data.wpm != null) {
        updateOps.$inc['stats.readingWpm.total'] = data.wpm;
        updateOps.$inc['stats.readingWpm.count'] = 1;
      }
    }
    else if (type === 'dictation') {
      if (data.isLessonJustFinished) {
        updateOps.$inc['lessonsCompleted.listening'] = 1;
      }

      if (data.score != null) {
        updateOps.$inc['stats.dictationAccuracy.total'] = data.score;
        updateOps.$inc['stats.dictationAccuracy.count'] = 1;
      }
    }
    else if (type === 'speaking') {
      if (data.isLessonJustFinished) {
        updateOps.$inc['lessonsCompleted.speaking'] = 1;
      }

      if (data.score != null) {
        updateOps.$inc['stats.speakingScore.total'] = data.score;
        updateOps.$inc['stats.speakingScore.count'] = 1;
      }
    }
    else if (type === 'writing') {
      // Bài viết: Nộp xong là tính 1 bài luôn (thường là vậy)
      if (data.isLessonJustFinished) {
        updateOps.$inc['lessonsCompleted.writing'] = 1;
      }

      if (data.score != null) {
        updateOps.$inc['stats.writingScore.total'] = data.score;
        updateOps.$inc['stats.writingScore.count'] = 1;
      }
    }
    else if (type === 'vocab') {
      updateOps.$inc['vocabLearned'] = 1;
    }

    // 4. Update Atomic
    await UserDailyProgress.findOneAndUpdate(
      { userId, date: todayStr },
      updateOps,
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

  } catch (error) {
    console.error("Track Progress Error:", error);
  }
};