import User from '../models/User.js';
import UserDailyProgress from '../models/UserDailyProgress.js';

export const getUserContext = async (userId) => {
  try {
    // 1. Lấy thông tin User
    const user = await User.findById(userId).select('fullName level currentStreak totalPoints dailyMinutes timezone').lean();
    if (!user) return "Không tìm thấy thông tin người dùng.";

    const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';
    const todayStr = new Date().toLocaleDateString('en-CA', { timeZone: userTimezone });

    // 2. Lấy tiến độ hôm nay
    const todayRecord = await UserDailyProgress.findOne({ userId, date: todayStr }).lean();

    // 3. Format dữ liệu thành văn bản để AI dễ hiểu (Tiết kiệm token hơn JSON)
    const todaySummary = todayRecord
      ? `
        - Thời gian học hôm nay: ${Math.round((todayRecord.studySeconds || 0) / 60)} phút
        - Từ mới đã học: ${todayRecord.vocabLearned || 0} từ
        - Bài học hoàn thành: ${(todayRecord.lessonsCompleted?.reading || 0) + (todayRecord.lessonsCompleted?.listening || 0)} bài
        `
      : "- Hôm nay chưa học gì cả.";

    const contextText = `
    THÔNG TIN NGƯỜI DÙNG HIỆN TẠI:
    - Tên: ${user.fullName}
    - Level: ${user.level}
    - Chuỗi (Streak): ${user.currentStreak} ngày
    - Điểm tích lũy: ${user.totalPoints}
    - Mục tiêu mỗi ngày: ${user.dailyMinutes} phút
    
    TIẾN ĐỘ HÔM NAY (${todayStr}):
    ${todaySummary}
    `;

    return contextText;
  } catch (error) {
    console.error("Get Context Error:", error);
    return "Không lấy được dữ liệu ngữ cảnh.";
  }
};