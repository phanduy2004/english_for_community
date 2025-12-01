import Word from '../models/Word.js'; // Import Mongoose model

const calculateInterval = (level) => {
  if (level <= 0) return 0; // Không ôn tập

  // Đây là ví dụ về khoảng cách tăng dần (bạn có thể tùy chỉnh)
  // Level 1: 1 ngày
  // Level 2: 3 ngày
  // Level 3: 7 ngày
  // Level 4: 16 ngày
  // Level 5: 35 ngày
  const intervals = [1, 3, 7, 16, 35, 90, 180]; // (ngày)

  const days = intervals[level - 1] || intervals[intervals.length - 1]; // Lấy

  const now = new Date();
  now.setDate(now.getDate() + days);
  return now;
};
const getReviewWords = async (userId) => {
  try {
    // Lấy các từ 'learning' đã đến hạn ôn tập (nextReviewDate <= now)
    // Sắp xếp để từ cũ nhất lên trước
    return Word.find({
      user: userId,
      status: 'learning',
      nextReviewDate: { $lte: new Date() }
    }).sort({ nextReviewDate: 1 });
  } catch (error) {
    console.error('Error in getReviewWords service:', error);
    throw new Error('Không thể lấy từ cần ôn tập');
  }
};

// 🔽 ✍️ THÊM HÀM NÀY (HÀM EBBINGHAUS CỐT LÕI)
const updateWordReview = async (userId, wordId, feedback) => {
  // feedback sẽ là 'hard', 'good', 'easy'
  try {
    const word = await Word.findOne({ _id: wordId, user: userId });
    if (!word) {
      throw new Error('Không tìm thấy từ');
    }

    let newLevel = word.learningLevel;

    if (feedback === 'hard') {
      // 1. Nhấn 'Khó' -> Reset về Cấp 1
      newLevel = 1;
    } else if (feedback === 'good') {
      // 2. Nhấn 'Nhớ' -> Tăng 1 Cấp
      newLevel += 1;
    } else if (feedback === 'easy') {
      // 3. Nhấn 'Dễ' -> Tăng 2 Cấp (để qua nhanh)
      newLevel += 2;
    }

    // Cập nhật từ vựng
    word.learningLevel = newLevel;
    word.lastReviewedDate = new Date();
    word.nextReviewDate = calculateInterval(newLevel); // Tính ngày ôn tập mới

    await word.save();
    return word;

  } catch (error) {
    console.error('Error in updateWordReview service:', error);
    throw new Error('Không thể cập nhật từ');
  }
};
const logRecentWord = async (userId, wordData) => {
  const query = { user: userId, headword: wordData.headword };

  const update = {
    $set: {
      user: userId,
      headword: wordData.headword,
      ipa: wordData.ipa,
      shortDefinition: wordData.shortDefinition,
      pos: wordData.pos,
      lastReviewedDate: new Date(), // Luôn cập nhật ngày xem cuối
    },
    $setOnInsert: {
      // $setOnInsert: Chỉ set các trường này KHI TẠO MỚI (upsert)
      status: 'recent',
      learningLevel: 0,
      nextReviewDate: new Date(),
    }
  };

  const options = {
    new: true,    // Trả về doc đã cập nhật
    upsert: true  // Tạo mới nếu không tìm thấy
  };

  try {
    const word = await Word.findOneAndUpdate(query, update, options);
    return word;
  } catch (error) {
    console.error('Error in logRecentWord service:', error);
    throw new Error('Không thể log từ vựng');
  }
};
const createLearningWord = async (userId, wordData) => {
  // wordData = { headword, ipa, shortDefinition, pos }

  const query = { user: userId, headword: wordData.headword };

  const update = {
    $set: {
      ...wordData,
      user: userId,
      status: 'learning',
      // --- 🔽 LOGIC EBBINGHAUS BẮT ĐẦU 🔽 ---
      learningLevel: 1, // Bắt đầu học ở level 1
      lastReviewedDate: new Date(),
      nextReviewDate: calculateInterval(1), // Tính ngày review cho level 1 (ví dụ: +1 ngày)
      // --- 🔼 🔼 🔼 ---
    }
  };

  const options = { new: true, upsert: true };

  try {
    const word = await Word.findOneAndUpdate(query, update, options);
    return word;
  } catch (error) {
    console.error('Error in createLearningWord service:', error);
    throw new Error('Không thể thêm từ vào lộ trình học');
  }
};

// ✍️ Sửa lại hàm này
const createSavedWord = async (userId, wordData) => {
  // wordData = { headword, ipa, shortDefinition, pos }

  const query = { user: userId, headword: wordData.headword };

  const update = {
    $set: {
      ...wordData,
      user: userId,
      status: 'saved',
      // Khi "save", ta có thể reset trạng thái học
      learningLevel: 0,
      lastReviewedDate: new Date(),
      nextReviewDate: new Date(), // Không có lịch review
    }
  };

  const options = { new: true, upsert: true };

  try {
    const word = await Word.findOneAndUpdate(query, update, options);
    return word;
  } catch (error) {
    console.error('Error in createSavedWord service:', error);
    throw new Error('Không thể lưu từ');
  }
};

const getLearningWords = async (userId) => {
  return Word.find({ user: userId, status: 'learning' }).sort({ learningLevel: -1 });
};

// HÀM GET SAVED WORDS
const getSavedWords = async (userId) => {
  return Word.find({ user: userId, status: 'saved' }).sort({ createdAt: -1 });
};

const getRecentWords = async (userId) => {
  return Word.find({ user: userId }).sort({ updatedAt: -1 }).limit(20);
};

const getDailyReminderWords = async (userId) => {
  // 1. Lấy 3 từ đang học, ưu tiên từ chưa bao giờ nhắc hoặc nhắc lâu nhất
  const words = await Word.find({
    user: userId,
    status: 'learning'
  })
    .sort({ lastRemindedDate: 1 }) // Null trước, ngày cũ trước
    .limit(3);

  if (words.length > 0) {
    // 2. Cập nhật lastRemindedDate cho đám này thành hôm nay
    // Để ngày mai query sẽ ra 3 từ khác
    const wordIds = words.map(w => w._id);
    await Word.updateMany(
      { _id: { $in: wordIds } },
      { $set: { lastRemindedDate: new Date() } }
    );
  }

  return words;
};

export const vocabService = {
  createLearningWord,
  createSavedWord,
  getLearningWords,
  getSavedWords,
  getRecentWords,
  logRecentWord,
  getReviewWords,
  updateWordReview,
  getDailyReminderWords
};