import cron from 'node-cron';
import User from '../models/User.js';
import Word from '../models/Word.js';
import { vocabService } from '../services/vocabularyService.js';
import { messaging } from '../config/firebase.js';
import { notificationService } from '../services/notificationService.js';

// --- HELPER: Lấy giờ phút theo Timezone User ---
const getUserTime = (timezone = 'Asia/Ho_Chi_Minh') => {
  try {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      hour: 'numeric',
      minute: 'numeric',
      hour12: false
    });
    const parts = formatter.formatToParts(now);
    const hour = parseInt(parts.find(p => p.type === 'hour').value);
    const minute = parseInt(parts.find(p => p.type === 'minute').value);
    return { hour, minute, dateStr: now.toLocaleDateString('en-CA', { timeZone: timezone }) };
  } catch (e) {
    return { hour: new Date().getHours(), minute: new Date().getMinutes(), dateStr: '' };
  }
};

// ============================================================
// 1. [DAILY REMINDER] GỬI 1 NHẮC CHUNG
// ============================================================
const triggerDailyVocabSequence = async (user) => {
  try {
    const words = (await vocabService.getDailyReminderWords(user._id) || []).slice(0, 3);
    const wordNames = words
      .map(word => word?.headword)
      .filter(Boolean);
    const firstWord = words[0];

    const title = 'Đến giờ học rồi 👋';
    const body = wordNames.length > 0
      ? `Ôn lại: ${wordNames.join(', ')}. Vào học nhé!`
      : 'Đã đến giờ học tiếng Anh của bạn. Vào luyện tập ngay!';
    const data = {
      type: 'DAILY_REMINDER',
      ...(firstWord?._id ? { wordId: firstWord._id.toString() } : {})
    };

    const messagePayload = {
      notification: { title, body },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      tokens: user.fcmTokens
    };

    if (messaging && user.fcmTokens?.length > 0) {
      await messaging.sendEachForMulticast(messagePayload);
      console.log(`📢 [DAILY_REMINDER] Sent to ${user.username}`);

      await notificationService.createNotification({
        recipientId: user._id,
        senderId: null,
        type: 'DAILY_REMINDER',
        title,
        message: body,
        data,
        skipSocket: true,
        skipFCM: true
      });
    }
  } catch (error) {
    console.error(`❌ Error logic daily reminder:`, error);
  }
};

// ============================================================
// 2. [REVIEW REMINDER]
// ============================================================
const checkReviewReminders = async (user) => {
  try {
    const dueCount = await Word.countDocuments({
      user: user._id,
      status: 'learning',
      nextReviewDate: { $lte: new Date() }
    });

    if (dueCount > 0) {
      await sendPush(user, {
        title: "Ôn tập từ vựng 🎓",
        body: `Bạn có ${dueCount} từ cần ôn tập ngay. Đừng để quên nhé!`,
        type: 'REVIEW_REMINDER'
      });
    }
  } catch (error) {
    console.error(`❌ Error checking review count:`, error);
  }
};

// ============================================================
// 3. [PROGRESS NUDGE]
// ============================================================
const checkProgressNudge = async (user, todayStr) => {
  if (user.dailyProgressDate === todayStr) {
    const currentProgress = user.dailyActivityProgress || 0;
    const lessonGoal = user.dailyLessonGoal || 5;

    if (currentProgress < lessonGoal) {
      const remain = lessonGoal - currentProgress;
      await sendPush(user, {
        title: "Sắp hoàn thành rồi! 🏃‍♂️",
        body: `Chỉ còn ${remain} bài học nữa là đạt mục tiêu ngày. Cố lên!`,
        type: 'PROGRESS_NUDGE'
      });
    }
  }
};

// ============================================================
// 4. [STREAK RESCUE]
// ============================================================
const checkStreakRescue = async (user, todayStr) => {
  const hasStudiedToday = user.dailyProgressDate === todayStr;
  const currentStreak = user.currentStreak || 0;

  if (!hasStudiedToday && currentStreak > 0) {
    await sendPush(user, {
      title: "🔥 Báo động: Bạn sắp mất Streak!",
      body: `Chuỗi ${currentStreak} ngày đang gặp nguy hiểm. Vào học 5 phút ngay!`,
      type: 'STREAK_RESCUE'
    });
  }
};

// ============================================================
// 🔥 HELPER GỬI PUSH CHUNG (ĐÃ SỬA)
// ============================================================
const sendPush = async (user, { title, body, type }) => {
  try {
    const payload = {
      notification: { title, body },
      data: { type, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      tokens: user.fcmTokens
    };

    if (messaging && user.fcmTokens?.length > 0) {
      // 1. Job tự gửi FCM
      await messaging.sendEachForMulticast(payload);
      console.log(`📢 [${type}] Sent to ${user.username}`);

      // 2. Lưu DB (Chặn Socket + Chặn FCM của Service)
      notificationService.createNotification({
        recipientId: user._id,
        senderId: null,
        type: 'SYSTEM_ANNOUNCEMENT',
        title,
        message: body,
        data: { type },
        skipSocket: true, // ✅ Chặn Socket
        skipFCM: true     // ✅ THÊM DÒNG NÀY ĐỂ TRÁNH GỬI 2 LẦN
      });
    }
  } catch (e) { console.error(e); }
};

// ============================================================
// 🔥 MAIN JOB
// ============================================================
export const initSmartNotificationJob = () => {
  console.log('🧠 Smart Notification Job Started (Checking every minute)');

  cron.schedule('* * * * *', async () => {
    try {
      const userCursor = User.find({
        fcmTokens: { $exists: true, $not: { $size: 0 } }
      }).cursor();

      for (let user = await userCursor.next(); user != null; user = await userCursor.next()) {
        const { hour, minute, dateStr } = getUserTime(user.timezone);

        // A. Daily Vocab
        if (user.reminder?.hour != null) {
          if (hour === user.reminder.hour && minute === user.reminder.minute) {
            await triggerDailyVocabSequence(user);
          }
        }

        // B. Review Reminder (19:00)
        if (hour === 19 && minute === 0) {
          await checkReviewReminders(user);
        }

        // C. Progress Nudge (20:00)
        if (hour === 20 && minute === 0) {
          await checkProgressNudge(user, dateStr);
        }

        // D. Streak Rescue (22:00)
        if (hour === 22 && minute === 0) {
          await checkStreakRescue(user, dateStr);
        }
      }
    } catch (error) {
      console.error('❌ Smart Notification Error:', error);
    }
  });
};
