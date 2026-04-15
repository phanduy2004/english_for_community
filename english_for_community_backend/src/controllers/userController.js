import User from '../models/User.js';
import UserDailyProgress from "../models/UserDailyProgress.js";
import bcrypt from "bcrypt";
const calcAvg = (agg) => agg.count > 0 ? (agg.total / agg.count) : 0;

// 🔥 API ADMIN: Lấy chi tiết User + Thống kê học tập
export const getUserDetailsForAdmin = async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Lấy thông tin User
    const user = await User.findById(id).lean();
    if (!user) return res.status(404).json({ message: 'User not found' });

    const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';
    const dailyGoal = user.dailyMinutes || 30;

    // 2. Lấy TOÀN BỘ lịch sử hoạt động từ UserDailyProgress (Sắp xếp cũ -> mới)
    const records = await UserDailyProgress.find({ userId: id }).sort({ date: 1 }).lean();

    // --- A. TÍNH TOÁN STATS GRID (ALL TIME) ---
    let totalVocab = 0;
    let totalSecondsInRange = 0;
    let totalLessons = 0;

    // Object gom nhóm để tính trung bình điểm số
    const aggs = {
      readingAcc: { total: 0, count: 0 },
      dictationAcc: { total: 0, count: 0 },
      speakingScore: { total: 0, count: 0 },
      writingScore: { total: 0, count: 0 },
    };

    records.forEach(rec => {
      // Cộng dồn thời gian & từ vựng
      totalSecondsInRange += (rec.studySeconds || 0);
      totalVocab += (rec.vocabLearned || 0);

      // Cộng tổng số bài học (Listening + Reading + Speaking + Writing)
      if (rec.lessonsCompleted) {
        totalLessons += (rec.lessonsCompleted.listening || 0) +
          (rec.lessonsCompleted.reading || 0) +
          (rec.lessonsCompleted.speaking || 0) +
          (rec.lessonsCompleted.writing || 0);
      }

      // Cộng dồn điểm số để tính trung bình
      if (rec.stats) {
        if (rec.stats.readingAccuracy?.count) {
          aggs.readingAcc.total += rec.stats.readingAccuracy.total;
          aggs.readingAcc.count += rec.stats.readingAccuracy.count;
        }
        if (rec.stats.dictationAccuracy?.count) {
          aggs.dictationAcc.total += rec.stats.dictationAccuracy.total;
          aggs.dictationAcc.count += rec.stats.dictationAccuracy.count;
        }
        if (rec.stats.speakingScore?.count) {
          aggs.speakingScore.total += rec.stats.speakingScore.total;
          aggs.speakingScore.count += rec.stats.speakingScore.count;
        }
        if (rec.stats.writingScore?.count) {
          aggs.writingScore.total += rec.stats.writingScore.total;
          aggs.writingScore.count += rec.stats.writingScore.count;
        }
      }
    });

    const statsGrid = {
      vocabLearned: totalVocab,
      lessonsCompleted: totalLessons, // 🔥 Đã thay thế vị trí cho WPM
      avgWritingScore: parseFloat(calcAvg(aggs.writingScore).toFixed(1)),
      readingAccuracy: Math.round(calcAvg(aggs.readingAcc) * 100),
      dictationAccuracy: Math.round(calcAvg(aggs.dictationAcc) * 100),
      speakingAccuracy: Math.round(calcAvg(aggs.speakingScore) * 100),
      // ❌ Đã bỏ readingWpm hoàn toàn
    };

    // --- B. TÍNH TOÁN STUDY TIME ---
    const now = new Date();
    const todayStr = now.toLocaleDateString('en-CA', { timeZone: userTimezone });

    // Tìm record hôm nay để tính todayMinutes
    const todayRecord = records.find(h => h.date === todayStr);
    const todayMinutes = todayRecord ? Math.round((todayRecord.studySeconds || 0) / 60) : 0;

    const studyTime = {
      todayMinutes: todayMinutes,
      goalMinutes: dailyGoal,
      totalMinutesInRange: Math.round(totalSecondsInRange / 60), // Tổng phút All-Time
      progressPercent: dailyGoal > 0 ? Math.min(todayMinutes / dailyGoal, 1.0) : 0
    };

    // --- C. WEEKLY CHART (7 ngày gần nhất) ---
    const labels = [];
    const minutes = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dStr = d.toLocaleDateString('en-CA', { timeZone: userTimezone });

      const label = d.toLocaleDateString('en-US', { weekday: 'short', timeZone: userTimezone });
      labels.push(label);

      const record = records.find(r => r.date === dStr);
      minutes.push(record ? Math.round((record.studySeconds || 0) / 60) : 0);
    }

    const weeklyChart = { labels, minutes };

    // --- D. CALLOUT ---
    const callout = {
      title: "Tổng quan quá trình",
      message: `Người dùng đã tham gia học ${records.length} ngày với tổng thời lượng ${(totalSecondsInRange/3600).toFixed(1)} giờ.`
    };

    // 4. Trả về kết quả
    const responseData = {
      ...user,
      progressSummary: {
        studyTime,
        statsGrid,
        weeklyChart,
        callout
      }
    };

    res.status(200).json(responseData);

  } catch (error) {
    console.error("Get Admin User Details Error:", error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
export const getPublicProfile = async (req, res) => {
  try {
    const { id } = req.params; // Lấy ID từ URL (vd: /users/123/public)

    // Chỉ select các trường an toàn
    const user = await User.findById(id)
      .select('fullName username avatarUrl bio dateOfBirth gender totalPoints level currentStreak isOnline lastActivityDate')
      .lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json(user);

  } catch (error) {
    console.error("Get Public Profile Error:", error);
    res.status(500).json({ message: 'Server error' });
  }
};
// Get user profile
export const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    const userTimezone = user.timezone || 'Asia/Ho_Chi_Minh';

    const now = new Date();
    const todayStr = now.toLocaleDateString('en-CA', { timeZone: userTimezone });

    const yesterdayStr = (() => {
      const d = new Date(now);
      d.setDate(d.getDate() - 1);
      return d.toLocaleDateString('en-CA', { timeZone: userTimezone });
    })();

    const dailyRecord = await UserDailyProgress.findOne({
      userId: user._id,
      date: todayStr
    }).lean();

    let todayLessonsCompleted = 0;

    if (dailyRecord) {
      todayLessonsCompleted =
        (dailyRecord.lessonsCompleted?.listening || 0) +
        (dailyRecord.lessonsCompleted?.reading || 0) +
        (dailyRecord.lessonsCompleted?.speaking || 0) +
        (dailyRecord.lessonsCompleted?.writing || 0);
    }

    // Streak chỉ còn hợp lệ nếu lần học cuối là hôm nay hoặc hôm qua.
    // Nếu bỏ lỡ ít nhất 1 ngày, streak phải hiển thị là 0.
    const lastStreakDateStr = user.dailyProgressDate || null;
    const effectiveStreak =
      lastStreakDateStr === todayStr || lastStreakDateStr === yesterdayStr
        ? (user.currentStreak || 0)
        : 0;

    const responseUser = {
      ...user,
      dailyActivityProgress: todayLessonsCompleted,
      currentStreak: effectiveStreak,
    };

    res.status(200).json(responseUser);

  } catch (error) {
    console.error("Get Profile Error:", error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
export const updateProfile = async (req, res) => {
  try {
    // --- DEBUG LOG ---
    console.log("📷 Update Profile Request...");
    console.log("📝 Body:", req.body);

    // 1. XỬ LÝ AVATAR (Giữ nguyên logic của bạn)
    let avatarUrl = undefined;
    if (req.file && req.file.path) {
      avatarUrl = req.file.path;
    } else if (req.body.avatarUrl && req.body.avatarUrl.startsWith('http')) {
      avatarUrl = req.body.avatarUrl;
    }

    // 2. XỬ LÝ REMINDER (🔥 SỬA LỖI Ở ĐÂY)
    let reminder = req.body.reminder;

    // Trường hợp 1: Client gửi string "null" (do FormData) hoặc giá trị null
    if (reminder === 'null' || reminder === null) {
      reminder = null; // Gán null thật sự để xóa trong DB
    }
    // Trường hợp 2: Client gửi JSON string (ví dụ: '{"hour":7,"minute":30}')
    else if (reminder && typeof reminder === 'string') {
      try {
        reminder = JSON.parse(reminder);
      } catch (e) {
        console.log("⚠️ Lỗi parse reminder:", e.message);
        reminder = undefined; // Nếu lỗi format thì bỏ qua, không update trường này
      }
    }

    // 3. GOM DỮ LIỆU CẦN UPDATE
    const updates = {
      fullName: req.body.fullName,
      username: req.body.username,
      bio: req.body.bio,
      phone: req.body.phone === '' ? undefined : req.body.phone,
      dateOfBirth: req.body.dateOfBirth,
      avatarUrl: avatarUrl,
      gender: req.body.gender,
      goal: req.body.goal,
      cefr: req.body.cefr,
      dailyMinutes: req.body.dailyMinutes,
      dailyLessonGoal: req.body.dailyLessonGoal,
      reminder: reminder, // Có thể là Object {hour, minute} hoặc null (để xóa)

      strictCorrection: req.body.strictCorrection,
      language: req.body.language,
      timezone: req.body.timezone
    };

    // 4. LỌC BỎ CÁC TRƯỜNG UNDEFINED
    // (Lưu ý: null vẫn được giữ lại để update vào DB, chỉ xóa undefined)
    Object.keys(updates).forEach(key => updates[key] === undefined && delete updates[key]);

    // 5. THỰC HIỆN UPDATE
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      updates,
      { new: true, runValidators: true }
    );

    console.log("✅ Update Success, New Reminder Value:", updatedUser.reminder);
    res.status(200).json(updatedUser);

  } catch (error) {
    console.error("Update Profile Error:", error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
// Delete user account
export const deleteAccount = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user._id;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Missing password fields' });
    }

    // 1. Tìm User (lấy cả field password)
    const user = await User.findById(userId).select('+password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // 2. Kiểm tra mật khẩu cũ
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    // 3. Hash mật khẩu mới
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // 4. Lưu
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error("Change Password Error:", error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
export const updateFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    const userId = req.user.id;

    if (!token) return res.status(400).json({ message: 'Token is required' });

    // Thêm token vào mảng fcmTokens nếu chưa có (addToSet tránh trùng lặp)
    await User.findByIdAndUpdate(userId, {
      $addToSet: { fcmTokens: token }
    });

    res.status(200).json({ message: 'FCM Token updated successfully' });
  } catch (error) {
    console.error('Update FCM Token Error:', error);
    res.status(500).json({ message: error.message });
  }
};