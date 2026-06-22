import express from 'express';
import { authController } from '../controllers/authController.js';
import { authenticate } from '../middleware/auth.js';
import { loginLimiter, otpLimiter, authLimiter } from '../middleware/authRateLimit.js';

const router = express.Router();

// --- Đăng ký & OTP --- (OTP/email endpoints: anti-enumeration + mail-flood)
router.post('/register', otpLimiter, authController.register);
router.post('/register/resend-otp', otpLimiter, authController.resendSignupOtp);
router.post('/verify-otp', otpLimiter, authController.verifyOtp);

// --- Đăng nhập & Đăng xuất --- (login: brute-force protection)
router.post('/login', loginLimiter, authController.login);
router.post('/logout', authenticate, authController.logout);

// --- Quên mật khẩu --- (OTP-based reset)
router.post('/forgot-password', otpLimiter, authController.requestPasswordReset);
router.post('/reset-password', otpLimiter, authController.resetPassword);

// --- Token Management (Logic cũ của bạn đã được chuyển vào controller này) ---
router.post('/refresh', authLimiter, authController.refreshToken);
router.post('/google', authLimiter, authController.googleLogin);
export default router;