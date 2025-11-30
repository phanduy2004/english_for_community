import User from '../models/User.js';
import UserDailyProgress from "../models/UserDailyProgress.js";

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
    const responseUser = {
      ...user,
      dailyActivityProgress: todayLessonsCompleted,
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
      phone: req.body.phone,
      dateOfBirth: req.body.dateOfBirth,
      avatarUrl: avatarUrl,

      goal: req.body.goal,
      cefr: req.body.cefr,
      dailyMinutes: req.body.dailyMinutes,

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