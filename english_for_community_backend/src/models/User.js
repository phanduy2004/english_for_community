import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  phone: { type: String, unique: true, sparse: true },
  email: { type: String, unique: true, sparse: true },
  password: { type: String, required: true },

  avatarUrl: { type: String, default: 'https://github.com/shadcn.png' },
  fullName: { type: String, required: true },
  username: { type: String, required: true },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  dateOfBirth: { type: Date },
  bio: { type: String, default: '' },

  // 🔥 THÊM: Gender (từ code register cũ)
  gender: { type: String, default: null },

  // 🔥 THÊM TRƯỜNG XÁC THỰC EMAIL
  isVerified: { type: Boolean, default: false },

  // NEW: mục tiêu học, level CEFR, thói quen/nhắc nhở, ngôn ngữ, timezone
  goal: { type: String, default: '' },
  cefr: {
    type: String,
    enum: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', null],
    default: null
  },
  dailyMinutes: { type: Number, default: 0, min: 0, max: 1440 },
  reminder: {
    hour:   { type: Number, min: 0, max: 23, default: null },
    minute: { type: Number, min: 0, max: 59, default: null }
  },
  dailyActivityGoal: { type: Number, default: 5, min: 1, max: 100 },
  dailyActivityProgress: { type: Number, default: 0 },
  dailyProgressDate: { type: String, default: null},

  // 2. Thêm các trường này
  totalPoints: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  currentStreak: { type: Number, default: 0 },
  // ------------------------------------
  strictCorrection: { type: Boolean, default: false },
  language: { type: String, default: 'en' },
  timezone: { type: String, default: 'Asia/Ho_Chi_Minh' },

  isOnline: { type: Boolean, default: false },
  lastActivityDate: { type: Date },
  isBanned: { type: Boolean, default: false },
  banExpiresAt: { type: Date, default: null },
  banReason: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: null },

  _destroy: { type: Boolean, default: false },
  refreshToken: { type: String, default: null },

  // OTP quên mật khẩu
  resetOtp: { type: String, default: null },
  resetOtpExpiresAt: { type: Date, default: null },
  resetOtpAttempts: { type: Number, default: 0 },
  resetLastSentAt: { type: Date, default: null },

  // 🔥 THÊM TRƯỜNG NÀY ĐỂ PHÂN BIỆT MỤC ĐÍCH OTP
  otpPurpose: { type: String, enum: ['signup', 'forgot', null], default: null },

  // 🔥 Cần thêm trường này để kích hoạt TTL Index (tự động xóa sau 10 phút)
  otpCreatedAt: { type: Date, default: null }
});

userSchema.pre('save', function (next) {
  this.updatedAt = Date.now();
  next();
});

// 🔥 INDEX TTL: Tự động xóa user sau 10 phút nếu chưa xác thực VÀ purpose là 'signup'
userSchema.index(
  { "otpCreatedAt": 1 },
  {
    expireAfterSeconds: 600, // 600 giây = 10 phút
    partialFilterExpression: {
      isVerified: false,
      otpCreatedAt: { $exists: true },
      otpPurpose: 'signup'  // 🔥 THÊM: Chỉ áp dụng cho signup, tránh xóa khi forgot
    }
  }
);


// Chuẩn hoá JSON trả ra client (ẩn field nhạy cảm)
userSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.password;
    delete ret.resetOtp;
    delete ret.resetOtpExpiresAt;
    delete ret.resetOtpAttempts;
    delete ret.resetLastSentAt;
    delete ret.refreshToken;
    delete ret.otpPurpose; // Ẩn trường này
    delete ret.otpCreatedAt; // Ẩn trường này
    return ret;
  }
});

const User = mongoose.model('User', userSchema);
export default User;