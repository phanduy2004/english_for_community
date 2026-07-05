import User from '../models/User.js';

/** Chuyển Date sang chuỗi YYYY-MM-DD theo timezone user. */
const getDateString = (dateInput, timezone = 'Asia/Ho_Chi_Minh') => {
  if (!dateInput) return null;
  return new Date(dateInput).toLocaleDateString('en-CA', { timeZone: timezone });
};

const getYesterdayStr = (timezone) => {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return getDateString(d, timezone);
};

/**
 * Cập nhật streak khi sang ngày mới (chưa ghi nhận hôm nay).
 * @returns {boolean} true nếu vừa cập nhật streak cho hôm nay
 */
function applyDailyStreak(user, { resetLegacyDailyProgress = false } = {}) {
  const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';
  const todayStr = getDateString(new Date(), userTimezone);
  const yesterdayStr = getYesterdayStr(userTimezone);
  const lastStreakDateStr = user.dailyProgressDate || null;

  if (lastStreakDateStr === todayStr) {
    return false;
  }

  console.log(`🔄 Checking Streak: Last=${lastStreakDateStr}, Yesterday=${yesterdayStr}, Today=${todayStr}`);

  if (lastStreakDateStr === yesterdayStr) {
    user.currentStreak = (user.currentStreak || 0) + 1;
    console.log(`🔥 Streak increased to ${user.currentStreak}`);
  } else {
    user.currentStreak = 1;
    console.log('⚠️ Streak reset/started at 1');
  }

  user.dailyProgressDate = todayStr;
  if (resetLegacyDailyProgress) {
    user.dailyActivityProgress = 0;
  }
  return true;
}

function applySpeakingStreak(user) {
  const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';
  const todayStr = getDateString(new Date(), userTimezone);
  const yesterdayStr = getYesterdayStr(userTimezone);
  const lastSpeakingDate = user.speakingStreakDate || null;

  if (lastSpeakingDate === todayStr) return false;

  user.speakingStreak = lastSpeakingDate === yesterdayStr
    ? (user.speakingStreak || 0) + 1
    : 1;
  user.speakingStreakDate = todayStr;
  return true;
}

function addBadge(user, badge) {
  if (!badge) return;
  const badges = Array.isArray(user.speakingBadges) ? user.speakingBadges : [];
  if (!badges.includes(badge)) {
    badges.push(badge);
    user.speakingBadges = badges;
  }
}

/**
 * Ghi nhận hoạt động hàng ngày (đăng nhập / mở app).
 * Streak tăng khi user active ít nhất 1 lần mỗi ngày — không bắt buộc hoàn thành bài học.
 */
export const touchDailyStreak = async (userId) => {
  try {
    const user = await User.findById(userId);
    if (!user) return null;

    const updated = applyDailyStreak(user, { resetLegacyDailyProgress: false });
    if (updated) {
      user.lastActivityDate = new Date();
      await user.save();
      console.log(`✅ Daily streak touched. Streak: ${user.currentStreak}`);
    }
    return user;
  } catch (error) {
    console.error('touchDailyStreak error:', error);
    return null;
  }
};

export const updateGamificationStats = async (userId, activityType, activityData) => {
  try {
    const user = await User.findById(userId);
    if (!user) return;

    applyDailyStreak(user, { resetLegacyDailyProgress: true });

    let isCompletion = false;
    if (activityType === 'reading' || activityType === 'writing') {
      isCompletion = true;
    } else if (activityType === 'dictation' || activityType === 'speaking') {
      isCompletion = activityData?.isLessonComplete === true;
    }

    if (isCompletion) {
      user.dailyActivityProgress = (user.dailyActivityProgress || 0) + 1;
    }

    let newPoints = 0;
    if (activityType === 'speaking') {
      if (activityData?.isFreeSpeakingConversation === true) {
        applySpeakingStreak(user);
        const durationBonus = Math.min(20, Math.floor((activityData.durationInSeconds || 0) / 60) * 5);
        const scoreBonus = Math.max(0, Math.round(Number(activityData.score || 0) * 2));
        newPoints = 30 + durationBonus + scoreBonus;
        if ((activityData.score || 0) >= 7) addBadge(user, 'speaking-clear-communicator');
        if ((user.speakingStreak || 0) >= 3) addBadge(user, 'speaking-3-day-streak');
        if ((user.speakingStreak || 0) >= 7) addBadge(user, 'speaking-7-day-streak');
      } else {
        newPoints = 25;
      }
    }
    if (activityType === 'dictation') newPoints = 20;
    if (activityType === 'reading') newPoints = 15;
    if (activityType === 'writing') newPoints = 100;

    user.totalPoints = (user.totalPoints || 0) + newPoints;
    user.level = Math.floor(user.totalPoints / 1000) + 1;
    user.lastActivityDate = new Date();

    await user.save();
    console.log(`✅ Gamification Saved. Points: ${user.totalPoints}, DailyProgress: ${user.dailyActivityProgress}`);
  } catch (error) {
    console.error('Lỗi cập nhật gamification:', error);
  }
};
