import { setUserOfflineAndNotify } from '../socket/socketManager.js';
import User from '../models/User.js';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../lib/jwt_token.js';
import sendMail from '../utils/sendMailUtil.js';
import { hashRefreshToken } from '../utils/tokenHash.js';
import admin from "firebase-admin";
const FIREBASE_CONFIG_BASE64 = process.env.FIREBASE_CONFIG_BASE64;

let serviceAccount = null;

if (FIREBASE_CONFIG_BASE64) {
  try {
    // 1. Giải mã chuỗi Base64 thành chuỗi JSON
    const jsonString = Buffer.from(FIREBASE_CONFIG_BASE64, 'base64').toString('utf8');

    // 2. Parse chuỗi JSON đó thành đối tượng
    serviceAccount = JSON.parse(jsonString);
    console.log("[CONFIG] Đã tải Firebase Service Account từ Base64 (Env).");

  } catch (e) {
    // Lỗi này xảy ra khi có lỗi trong quá trình Buffer.from() hoặc JSON.parse()
    console.error("LỖI CẤU HÌNH: Không thể Parse hoặc Giải mã Base64 Firebase Key.", e);
  }
} else {
  console.warn("CẢNH BÁO: Biến môi trường FIREBASE_CONFIG_BASE64 chưa được thiết lập!");
}
// Cấu hình OTP
const OTP_TTL_MS = 10 * 60 * 1000; // 10 phút
const RESEND_COOLDOWN_MS = 60 * 1000; // 60s
const OTP_MAX_ATTEMPTS = 5;
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}
// Helper tạo lỗi có status code
const createError = (status, message, reason = null) => {
  const err = new Error(message);
  err.statusCode = status;
  if (reason) err.reason = reason;
  return err;
};

// Helper sinh OTP (cryptographically secure)
const generateOtp = (length = 6) => {
  let otp = '';
  for (let i = 0; i < length; i++) {
    otp += crypto.randomInt(0, 10).toString();
  }
  return otp;
};

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const isBcryptHash = (value) =>
  typeof value === 'string' && /^\$2[aby]\$\d{2}\$/.test(value);

async function findUserByEmailForLogin(email) {
  const normalized = normalizeEmail(email);
  if (!normalized) return null;

  let user = await User.findOne({ email: normalized, _destroy: { $ne: true } });
  if (user) return user;

  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({
    email: new RegExp(`^${escaped}$`, 'i'),
    _destroy: { $ne: true },
  });
}

/** Đăng nhập bằng email hoặc username (seed: seed_hd_s04). */
async function findUserForLogin(identifier) {
  const raw = String(identifier || '').trim();
  if (!raw) return null;

  if (raw.includes('@')) {
    return findUserByEmailForLogin(raw);
  }

  let user = await User.findOne({ username: raw, _destroy: { $ne: true } });
  if (user) return user;

  const escaped = raw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return User.findOne({
    username: new RegExp(`^${escaped}$`, 'i'),
    _destroy: { $ne: true },
  });
}

// --- 1. Đăng ký User mới ---
function resolveRegisterRole(accountType) {
  const t = String(accountType || 'student').trim().toLowerCase();
  if (t === 'teacher') return 'teacher';
  if (t === 'admin') throw createError(400, 'Invalid account type');
  return 'user';
}

const registerUser = async (data) => {
  // Giữ lại các trường bạn đã thêm vào RegisterPage
  const { username, email, password, fullName, phone, dateOfBirth, gender, accountType } = data;
  const role = resolveRegisterRole(accountType);

  // 🔥 VALIDATION SẠCH: Chỉ check các trường bắt buộc theo Mongoose Model
  if (!email || !password || !fullName || !username) {
    throw createError(400, 'Missing required fields: email, password, fullName, username');
  }

  // Check exist (email/username)
  const existing = await User.findOne({ $or: [{ email }, { username }] });
  if (existing) throw createError(400, 'Email or Username already registered');

  // Hash Password
  const salt = await bcrypt.genSalt(10);
  const hashed = await bcrypt.hash(password, salt);

  // Tạo OTP
  const otp = generateOtp(6);
  const now = Date.now();

  const user = new User({
    username, email, password: hashed, fullName,
    phone: phone || null,
    dateOfBirth: dateOfBirth,
    gender: gender || null,
    role,

    resetOtp: otp,
    resetOtpExpiresAt: new Date(now + OTP_TTL_MS),
    resetOtpAttempts: 0,
    resetLastSentAt: new Date(now),
    otpPurpose: 'signup',
    isVerified: false
  });

  await user.save();

  // 🔥 TÁI KÍCH HOẠT GỬI MAIL
  const text = `Your verification OTP is ${otp}. It expires in 10 minutes.`;
  await sendMail(email, "Mã xác thực đăng ký", text);

  return user;
};

// --- 2. Gửi lại OTP Đăng ký ---
const requestSignupVerification = async (email) => {
  const user = await User.findOne({ email });
  if (!user) throw createError(404, 'User not found');
  if (user.isVerified) throw createError(400, 'User already verified');

  const now = Date.now();
  if (user.resetLastSentAt && now - user.resetLastSentAt.getTime() < RESEND_COOLDOWN_MS) {
    throw createError(429, 'Please wait before requesting another OTP');
  }

  const otp = generateOtp(6);
  user.resetOtp = otp;
  user.resetOtpExpiresAt = new Date(now + OTP_TTL_MS);
  user.resetOtpAttempts = 0;
  user.resetLastSentAt = new Date(now);
  user.otpPurpose = 'signup';

  await user.save();

  // 🔥 TÁI KÍCH HOẠT GỬI MAIL
  const text = `Your new verification OTP is ${otp}. It expires in 10 minutes.`;
  await sendMail(email, "Mã xác thực đăng ký", text);
};

// --- 3. Verify OTP (Chung) ---
const verifyOtp = async (email, otp, purpose) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw createError(404, 'User not found');
  }

  // Check hiệu lực OTP và mục đích
  if (!user.resetOtp || !user.resetOtpExpiresAt || user.otpPurpose !== purpose) {
    // Check lý do thất bại cụ thể
    if (!user.resetOtp) throw createError(400, 'No active OTP found. Please request a new one.');
    if (user.otpPurpose !== purpose) throw createError(400, 'OTP purpose mismatch.');
    throw createError(400, 'Invalid or expired OTP request');
  }

  // Check hết hạn
  if (Date.now() > user.resetOtpExpiresAt.getTime()) {
    user.resetOtp = null;
    await user.save();
    throw createError(400, 'OTP expired. Please request a new one');
  }

  // Check số lần thử sai
  if (user.resetOtpAttempts >= OTP_MAX_ATTEMPTS) {
    throw createError(429, 'Too many failed attempts. Please request new OTP');
  }

  // So sánh OTP
  if (user.resetOtp !== otp) {
    user.resetOtpAttempts += 1;
    await user.save();
    throw createError(400, 'Invalid OTP');
  }

  // --> OTP ĐÚNG
  user.resetOtpAttempts = 0;

  if (purpose === 'signup') {
    // Signup: OTP dùng một lần — tiêu thụ ngay và kích hoạt tài khoản.
    user.resetOtp = null;
    user.resetOtpExpiresAt = null;
    user.otpPurpose = null;
    user.isVerified = true; // Kích hoạt tài khoản
  }
  // Forgot (và purpose khác): CHỈ xác thực ở bước này, GIỮ NGUYÊN OTP để bước
  // reset-password tiêu thụ. Nếu clear tại đây, resetPassword sẽ báo 'Invalid
  // OTP' vì resetOtp/otpPurpose đã bị xoá.

  await user.save();
  return true;
};
// --- 4. Login ---
const loginUser = async (email, password) => {
  if (!email || !password) {
    throw createError(400, 'Email and password are required');
  }

  const user = await findUserForLogin(email);
  if (!user) throw createError(400, 'Invalid credentials');
  if (!user.isVerified) {
    throw createError(403, 'Please verify your email address to log in.');
  }
  if (!isBcryptHash(user.password)) {
    throw createError(
      400,
      'This account was created with Google sign-in. Please use Continue with Google.'
    );
  }

  const ok = await bcrypt.compare(String(password), user.password);
  if (!ok) throw createError(400, 'Invalid credentials');

  // Check Ban Status (Giữ nguyên logic cũ)
  if (user.isBanned) {
    const now = new Date();
    if (!user.banExpiresAt) {
      throw createError(403, 'Account permanently banned', user.banReason);
    }
    if (new Date(user.banExpiresAt) > now) {
      throw createError(403, `Account banned until ${user.banExpiresAt.toLocaleString('vi-VN')}`, user.banReason);
    }
    user.isBanned = false;
    user.banExpiresAt = null;
    user.banReason = '';
    await user.save();
  }

  // Tạo Token
  const accessToken = generateAccessToken(user._id);
  const refreshToken = generateRefreshToken(user._id);

  // Cập nhật trạng thái DB (Vẫn giữ lại isOnline/lastActivityDate)
  user.refreshToken = hashRefreshToken(refreshToken);
  user.lastActivityDate = new Date();
  await user.save();

  // 🔥 ĐÃ XÓA KHỐI SOCKET IO:
  // Khối code này đã bị loại bỏ vì không cần thông báo real-time.

  return {
    accessToken,
    refreshToken,
    user: user.toJSON()
  };
};

// --- 5. Logout ---
const logoutUser = async (userId) => {
  if (!userId) return;
  const user = await User.findById(userId);
  if (user) {
    user.refreshToken = null;
    user.isOnline = false;
    await user.save();
  }
  try {
    await setUserOfflineAndNotify(userId);
  } catch (e) {
    console.error('setUserOfflineAndNotify failed:', e.message);
  }
};

// --- 6. Quên mật khẩu: Request OTP (Giữ nguyên) ---
const requestPasswordReset = async (email) => {
  const user = await User.findOne({ email });
  if (!user) return;

  const now = Date.now();
  if (user.resetLastSentAt && now - user.resetLastSentAt.getTime() < RESEND_COOLDOWN_MS) {
    throw createError(429, 'Please wait');
  }

  const otp = generateOtp(6);
  user.resetOtp = otp;
  user.resetOtpExpiresAt = new Date(now + OTP_TTL_MS);
  user.resetOtpAttempts = 0;
  user.resetLastSentAt = new Date(now);
  user.otpPurpose = 'forgot';

  await user.save();
  const text = `Your password reset OTP is ${otp}. It expires in 10 minutes.`;
  await sendMail(email, "Mã đặt lại mật khẩu", text);
};

// --- 7. Quên mật khẩu: Reset Pass (Giữ nguyên) ---
const resetPassword = async (email, otp, newPassword) => {
  if (newPassword.length < 6) throw createError(400, 'Password too short');

  const user = await User.findOne({ email });
  if (!user) throw createError(404, 'User not found');

  if (user.resetOtp !== otp || user.otpPurpose !== 'forgot') {
    throw createError(400, 'Invalid OTP');
  }
  if (Date.now() > user.resetOtpExpiresAt.getTime()) throw createError(400, 'OTP Expired');

  const salt = await bcrypt.genSalt(10);
  user.password = await bcrypt.hash(newPassword, salt);

  user.resetOtp = null;
  user.otpPurpose = null;
  await user.save();
};
const refreshToken = async (token) => {
  if (!token) {
    throw createError(401, 'Refresh token required');
  }

  // 1. Verify token
  const { valid, expired, userId } = verifyRefreshToken(token);

  if (expired) {
    throw createError(401, 'Refresh token expired');
  }
  if (!valid) {
    throw createError(401, 'Invalid refresh token');
  }

  // 2. Tìm User
  const user = await User.findById(userId);
  if (!user) {
    throw createError(404, 'User not found');
  }

  // 3. Token gửi lên phải khớp hash trong DB (legacy plaintext vẫn chấp nhận 1 lần)
  const tokenHash = hashRefreshToken(token);
  const stored = user.refreshToken;
  const validStored = stored === tokenHash || stored === token;
  if (!validStored) {
    user.refreshToken = null;
    await user.save();
    throw createError(403, 'Refresh token is not valid (revoked)');
  }

  const newAccessToken = generateAccessToken(user._id);
  const newRefreshToken = generateRefreshToken(user._id);
  user.refreshToken = hashRefreshToken(newRefreshToken);
  await user.save();

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
};
const loginWithGoogle = async (idToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { email, name, picture, uid } = decodedToken;

    let user = await User.findOne({ email });

    if (!user) {
      user = new User({
        email,
        fullName: name,
        username: email.split('@')[0],
        avatarUrl: picture,
        password: `google_${uid}`,
        isVerified: true,
        role: 'user',
        loginMethod: 'google'
      });
      await user.save();
    }

    if (user.isBanned) {
      // Translated Error: Account is banned
      const error = new Error('Account is banned');
      error.statusCode = 403;
      error.reason = user.banReason;
      throw error;
    }

    const accessToken = generateAccessToken(user._id);
    const refreshTokenValue = generateRefreshToken(user._id);

    user.refreshToken = hashRefreshToken(refreshTokenValue);
    user.lastActivityDate = new Date();
    await user.save();

    return {
      user: user.toJSON(),
      accessToken: accessToken,
      refreshToken: refreshTokenValue
    };

  } catch (error) {
    console.error("Firebase Error:", error);
    // Translated Error: Google Auth Failed
    const err = new Error('Google Auth Failed: ' + (error.message || ''));
    err.statusCode = 401;
    throw err;
  }
};
export const authService = {
  registerUser,
  requestSignupVerification,
  verifyOtp,
  loginUser,
  logoutUser,
  requestPasswordReset,
  resetPassword,
  refreshToken,
  loginWithGoogle
};