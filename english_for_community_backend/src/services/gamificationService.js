import User from '../models/User.js';

// Helper: Chuyển đổi Date Object sang chuỗi YYYY-MM-DD theo Timezone
const getDateString = (dateInput, timezone = 'Asia/Ho_Chi_Minh') => {
  if (!dateInput) return null; // Nếu chưa có ngày hoạt động nào
  return new Date(dateInput).toLocaleDateString('en-CA', { timeZone: timezone });
};

// Hàm chính
export const updateGamificationStats = async (userId, activityType, activityData) => {
  try {
    const user = await User.findById(userId);
    if (!user) return;

    // 1. Chuẩn bị các biến ngày dạng String (YYYY-MM-DD)
    const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';
    const todayStr = getDateString(new Date(), userTimezone);
    const yesterdayStr = (() => {
      const d = new Date();
      d.setDate(d.getDate() - 1);
      return getDateString(d, userTimezone);
    })();

    // 🔥 QUAN TRỌNG: Chuyển lastActivityDate trong DB ra String để so sánh
    const lastActivityStr = getDateString(user.lastActivityDate, userTimezone);

    // === 1. CẬP NHẬT DAILY GOAL ===
    let isCompletion = false;
    if (activityType === 'reading' || activityType === 'writing') {
      isCompletion = true;
    } else if (activityType === 'dictation' || activityType === 'speaking') {
      isCompletion = activityData?.isLessonComplete === true;
    }

    if (isCompletion) {
      if (user.dailyProgressDate !== todayStr) {
        user.dailyActivityProgress = 1;
        // (Lưu ý: user.dailyProgressDate sẽ được update ở block streak bên dưới)
      } else {
        user.dailyActivityProgress += 1;
      }
    }

    // === 2. CẬP NHẬT DAY STREAK (SỬA LỖI TẠI ĐÂY) ===

    // Nếu hôm nay CHƯA ghi nhận hoạt động (so sánh 2 chuỗi String)
    if (lastActivityStr !== todayStr) {

      // Kiểm tra xem lần cuối hoạt động có phải là hôm qua không
      if (lastActivityStr === yesterdayStr) {
        // Nếu đúng là hôm qua -> Tăng chuỗi
        user.currentStreak = (user.currentStreak || 0) + 1;
      } else {
        // Nếu không phải hôm qua (đã bỏ lỡ 1 ngày hoặc user mới) -> Reset về 1
        user.currentStreak = 1;
      }

      // Cập nhật ngày hoạt động mới nhất là hôm nay (Lưu dạng Date Object chuẩn cho DB)
      user.lastActivityDate = new Date();

      // Reset lại tracking ngày cho Daily Goal nếu sang ngày mới
      if (user.dailyProgressDate !== todayStr) {
        user.dailyProgressDate = todayStr;
        if (!isCompletion) {
          user.dailyActivityProgress = 0;
        }
      }
    }

    // === 3. CẬP NHẬT ĐIỂM VÀ LEVEL ===
    let newPoints = 0;
    if (activityType === 'speaking') newPoints = 25;
    if (activityType === 'dictation') newPoints = 20;
    if (activityType === 'reading') newPoints = 15;
    if (activityType === 'writing') newPoints = 100;

    user.totalPoints = (user.totalPoints || 0) + newPoints;
    user.level = Math.floor(user.totalPoints / 1000) + 1;

    await user.save();

  } catch (error) {
    console.error(`Lỗi cập nhật gamification:`, error);
  }
};