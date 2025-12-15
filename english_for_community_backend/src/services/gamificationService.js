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

    // Ngày học cuối cùng đã ghi nhận
    const lastStreakDateStr = user.dailyProgressDate || null;

    // === 1. LOGIC TÍNH STREAK (ĐÃ SỬA) ===

    // 🔥 QUAN TRỌNG: Chỉ tính lại streak nếu HÔM NAY CHƯA ĐƯỢC TÍNH
    if (lastStreakDateStr !== todayStr) {

      console.log(`🔄 Checking Streak: Last=${lastStreakDateStr}, Yesterday=${yesterdayStr}, Today=${todayStr}`);

      // Trường hợp 1: Học liên tục (Ngày cuối cùng là hôm qua)
      if (lastStreakDateStr === yesterdayStr) {
        user.currentStreak = (user.currentStreak || 0) + 1;
        console.log(`🔥 Streak increased to ${user.currentStreak}`);
      }
        // Trường hợp 2: Bị ngắt quãng (Ngày cuối cùng trước hôm qua) HOẶC user mới
      // Lưu ý: Nếu user.currentStreak đang là 0 thì lên 1 luôn.
      else {
        user.currentStreak = 1;
        console.log(`⚠️ Streak reset/started at 1`);
      }

      // Cập nhật ngày đã tính streak là hôm nay để không tính lại nữa
      user.dailyProgressDate = todayStr;

      // Reset tiến độ trong ngày về 0 vì đây là ngày mới
      user.dailyActivityProgress = 0;
    }
    else {
      console.log(`ℹ️ Streak already updated for today (${todayStr}). Keeping: ${user.currentStreak}`);
    }

    // === 2. CẬP NHẬT DAILY GOAL TIẾN ĐỘ ===
    // (Logic này chạy mỗi lần học, bất kể streak đã tính hay chưa)
    let isCompletion = false;
    if (activityType === 'reading' || activityType === 'writing') {
      isCompletion = true;
    } else if (activityType === 'dictation' || activityType === 'speaking') {
      isCompletion = activityData?.isLessonComplete === true;
    }

    if (isCompletion) {
      user.dailyActivityProgress = (user.dailyActivityProgress || 0) + 1;
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
    console.log(`✅ Gamification Saved. Points: ${user.totalPoints}, DailyProgress: ${user.dailyActivityProgress}`);

  } catch (error) {
    console.error(`Lỗi cập nhật gamification:`, error);
  }
};