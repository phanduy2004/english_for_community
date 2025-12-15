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
// 1. [DAILY VOCAB] GỬI CHUỖI 3 TỪ CỤ THỂ
// ============================================================
const sendSingleWordNotification = async (user, word, index, total) => {
  try {
    const title = `Từ vựng mỗi ngày (${index + 1}/${total}) ⏰`;
    const body = `Hôm nay học từ: "${word.headword}" (${word.pos}) - ${word.shortDefinition}`;

    const messagePayload = {
      notification: { title, body },
      data: {
        type: 'DAILY_VOCAB',
        wordId: word._id.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      tokens: user.fcmTokens
    };

    if (messaging && user.fcmTokens?.length > 0) {
      // 1. Job tự gửi FCM
      await messaging.sendEachForMulticast(messagePayload);

      // 2. Lưu DB (Chặn Socket + Chặn FCM của Service)
      notificationService.createNotification({
        recipientId: user._id,
        senderId: null,
        type: 'DAILY_REMINDER',
        title,
        message: body,
        data: { wordId: word._id.toString() }, // ✅ SỬA LẠI DATA CHUẨN
        skipSocket: true,
        skipFCM: true // ✅ ĐÃ CÓ (TỐT)
      });
    }
  } catch (error) {
    console.error(`❌ Error sending word "${word.headword}":`, error.message);
  }
};

const triggerDailyVocabSequence = async (user) => {
  try {
    const words = await vocabService.getDailyReminderWords(user._id);
    if (!words || words.length === 0) return;

    console.log(`🚀 [Daily Vocab] Sending ${words.length} words to ${user.username}`);

    words.forEach((word, index) => {
      setTimeout(() => {
        sendSingleWordNotification(user, word, index, words.length);
      }, index * 20000);
    });
  } catch (error) {
    console.error(`❌ Error logic daily vocab:`, error);
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
        if (user.reminder?.enabled !== false && user.reminder?.hour != null) {
          if (hour === user.reminder.hour && minute === user.reminder.minute) {
            await triggerDailyVocabSequence(user);
          }
        }

        // B. Review Reminder (19:00)
        if (hour === 19 && minute === 0) {
          await checkReviewReminders(user);
        }

        // C. Progress Nudge (20:00) - Bạn đang set phút 8 để test
        if (hour === 23 && minute === 12) {
          await checkProgressNudge(user, dateStr);
        }

        // D. Streak Rescue (22:00)
        if (hour === 23 && minute === 14) {
          await checkStreakRescue(user, dateStr);
        }
      }
    } catch (error) {
      console.error('❌ Smart Notification Error:', error);
    }
  });
};