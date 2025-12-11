import User from '../models/User.js';

// Helper: Chuyển đổi Date Object sang chuỗi YYYY-MM-DD theo Timezone
const getDateString = (dateInput, timezone = 'Asia/Ho_Chi_Minh') => {
  if (!dateInput) return null;
  return new Date(dateInput).toLocaleDateString('en-CA', { timeZone: timezone });
};

export const updateGamificationStats = async (userId, activityType, activityData) => {
  try {
    const user = await User.findById(userId);
    if (!user) return;

    const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';

    // Ngày hiện tại
    const todayStr = getDateString(new Date(), userTimezone);

    // Ngày hôm qua
    const yesterdayStr = (() => {
      const d = new Date();
      d.setDate(d.getDate() - 1);
      return getDateString(d, userTimezone);
    })();

    // 🔥 FIX: Lấy mốc ngày tính streak dựa trên dailyProgressDate (ngày học cuối cùng)
    // Nếu chưa có dailyProgressDate (user mới), fallback về null
    const lastStreakDateStr = user.dailyProgressDate || null;

    // === 1. LOGIC TÍNH STREAK (SỬA LẠI) ===

    // Chỉ xử lý nếu hôm nay chưa ghi nhận streak (Ngày học cuối khác ngày hôm nay)
    if (lastStreakDateStr !== todayStr) {

      // Nếu ngày học cuối cùng là hôm qua -> Tăng Streak
      if (lastStreakDateStr === yesterdayStr) {
        user.currentStreak = (user.currentStreak || 0) + 1;
      }
      // Nếu không phải hôm qua (bỏ cách ngày hoặc user mới) -> Reset về 1
      else {
        user.currentStreak = 1;
      }

      // Cập nhật ngày đã tính streak là hôm nay
      user.dailyProgressDate = todayStr;

      // Reset tiến độ trong ngày về 0 vì đây là ngày mới
      user.dailyActivityProgress = 0;
    }

    // === 2. CẬP NHẬT DAILY GOAL TIẾN ĐỘ ===
    let isCompletion = false;
    if (activityType === 'reading' || activityType === 'writing') {
      isCompletion = true;
    } else if (activityType === 'dictation' || activityType === 'speaking') {
      isCompletion = activityData?.isLessonComplete === true;
    }

    if (isCompletion) {
      user.dailyActivityProgress += 1;
    }

    // === 3. CẬP NHẬT ĐIỂM VÀ LEVEL ===
    let newPoints = 0;
    if (activityType === 'speaking') newPoints = 25;
    if (activityType === 'dictation') newPoints = 20;
    if (activityType === 'reading') newPoints = 15;
    if (activityType === 'writing') newPoints = 100;

    user.totalPoints = (user.totalPoints || 0) + newPoints;
    user.level = Math.floor(user.totalPoints / 1000) + 1;

    // Cập nhật luôn lastActivityDate để biết user còn online
    user.lastActivityDate = new Date();

    await user.save();
    console.log(`✅ Updated Streak: ${user.currentStreak}, Date: ${todayStr}`);

  } catch (error) {
    console.error(`Lỗi cập nhật gamification:`, error);
  }
};