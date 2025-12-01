// 🔽 ✍️ FILE: controllers/vocabController.js
import { vocabService } from "../services/vocabularyService.js";
import {trackUserProgress} from "../untils/progressTracker.js";

// ✍️ Sửa lại: Nhận object từ vựng
const startLearningWord = async (req, res) => {
  try {
    // 🔽 Lấy thêm 3 trường mới từ body
    const { headword, ipa, shortDefinition, pos } = req.body;
    const userId = req.user.id;

    // ✍️ Truyền cả object vào service
    const word = await vocabService.createLearningWord(userId, {
      headword, ipa, shortDefinition, pos
    });
    res.json(word);
  } catch (err) {
    // Thêm log lỗi để debug
    console.error('Error in startLearningWord:', err);
    res.status(500).send('Lỗi server');
  }
};

// ✍️ Sửa lại: Nhận object từ vựng
const saveWord = async (req, res) => {
  try {
    // 🔽 Lấy thêm 3 trường mới từ body
    const { headword, ipa, shortDefinition, pos } = req.body;
    const userId = req.user.id;

    // ✍️ Truyền cả object vào service
    const word = await vocabService.createSavedWord(userId, {
      headword, ipa, shortDefinition, pos
    });
    res.json(word);
  } catch (err) {
    console.error('Error in saveWord:', err);
    res.status(500).send('Lỗi server');
  }
};

// --- CÁC HÀM GET KHÔNG CẦN THAY ĐỔI ---

const getLearningWords = async (req, res) => {
  try {
    const userId = req.user.id;
    const words = await vocabService.getLearningWords(userId);
    res.json(words);
  } catch (err) {
    console.error('Error in getLearningWords:', err);
    res.status(500).send('Lỗi server');
  }
};

const getSavedWords = async (req, res) => {
  try {
    const userId = req.user.id;
    const words = await vocabService.getSavedWords(userId);
    res.json(words);
  } catch (err) {
    console.error('Error in getSavedWords:', err);
    res.status(500).send('Lỗi server');
  }
};
const logRecentWord = async (req, res) => {
  try {
    const { headword, ipa, shortDefinition, pos } = req.body;
    const userId = req.user.id;

    const word = await vocabService.logRecentWord(userId, {
      headword, ipa, shortDefinition, pos
    });
    res.json(word);
  } catch (err) {
    console.error('Error in logRecentWord:', err);
    res.status(500).send('Lỗi server');
  }
};
const getRecentWords = async (req, res) => {
  try {
    const userId = req.user.id;
    const words = await vocabService.getRecentWords(userId);
    res.json(words);
  } catch (err) {
    console.error('Error in getRecentWords:', err);
    res.status(500).send('Lỗi server');
  }
};

const getReviewWords = async (req, res) => {
  try {
    const userId = req.user.id;
    const words = await vocabService.getReviewWords(userId);
    res.json(words);
  } catch (err) {
    console.error('Error in getReviewWords:', err);
    res.status(500).send('Lỗi server');
  }
};

// 🔽 ✍️ THÊM HÀM NÀY
const updateWordReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { wordId, feedback, duration } = req.body; // duration tính bằng giây

    if (!wordId || !['hard', 'good', 'easy'].includes(feedback)) {
      return res.status(400).send('Thiếu wordId hoặc feedback không hợp lệ');
    }

    // 1. Cập nhật trạng thái từ vựng trong DB (Service của bạn)
    const word = await vocabService.updateWordReview(userId, wordId, feedback);

    // 2. TRACKING: Thống kê tiến độ
    const durationSec = duration || 0;

    if (feedback === 'good' || feedback === 'easy') {
      trackUserProgress(userId, 'vocab', {
        duration: durationSec
      });
    } else {
      trackUserProgress(userId, 'review_practice', {
        duration: durationSec
      });
    }

    res.json(word);
  } catch (err) {
    console.error('Error in updateWordReview:', err);
    res.status(500).send('Lỗi server');
  }
};

const getDailyReminders = async (req, res) => {
  try {
    const userId = req.user.id;
    const words = await vocabService.getDailyReminderWords(userId);
    res.json({ data: words });
  } catch (err) {
    console.error('Error fetching daily reminders:', err);
    res.status(500).send('Lỗi server');
  }
};
export const vocabController = {
  startLearningWord,
  saveWord,
  getLearningWords,
  getSavedWords,
  getRecentWords,
  getReviewWords,
  logRecentWord,
  updateWordReview,
  getDailyReminders
};