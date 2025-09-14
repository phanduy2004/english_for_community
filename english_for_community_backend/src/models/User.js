import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  phone: { type: String, unique: true, sparse: true },
  email: { type: String, unique: true, sparse: true },
  password: { type: String, required: true },

  avatarUrl: { type: String, default: 'https://github.com/shadcn.png' },
  fullName: { type: String, required: true },
  username: { type: String, required: true }, // <- fix

  dateOfBirth: { type: Date },
  bio: { type: String, default: '' },

  // NEW: mục tiêu học, level CEFR, thói quen/nhắc nhở, ngôn ngữ, timezone
  goal: { type: String, default: '' },                  // ví dụ: "IELTS 6.5"
  cefr: {                                               // A1–C2 (không bắt buộc)
    type: String,
    enum: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', null],
    default: null
  },
  dailyMinutes: { type: Number, default: 0, min: 0, max: 1440 },
  reminder: {                                           // thay cho TimeOfDay
    hour:   { type: Number, min: 0, max: 23, default: null },
    minute: { type: Number, min: 0, max: 59, default: null }
  },
  strictCorrection: { type: Boolean, default: false },  // sửa lỗi gắt khi chấm
  language: { type: String, default: 'en' },            // ngôn ngữ học/chính
  timezone: { type: String, default: 'Asia/Ho_Chi_Minh' },

  status: {
    isOnline: { type: Boolean, default: false },
    lastActiveAt: { type: Date, default: null }
  },

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: null },

  _destroy: { type: Boolean, default: false },

  // OTP quên mật khẩu
  resetOtp: { type: String, default: null },
  resetOtpExpiresAt: { type: Date, default: null },
  resetOtpAttempts: { type: Number, default: 0 },
  resetLastSentAt: { type: Date, default: null }
});

userSchema.pre('save', function (next) {
  this.updatedAt = Date.now();
  next();
});

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
    return ret;
  }
});

const User = mongoose.model('User', userSchema);
export default User;
