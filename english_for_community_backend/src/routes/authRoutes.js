import express from 'express';
import { authController } from '../controllers/authController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

// --- Đăng ký & OTP ---
router.post('/register', authController.register);
router.post('/register/resend-otp', authController.resendSignupOtp);
router.post('/verify-otp', authController.verifyOtp);

// --- Đăng nhập & Đăng xuất ---
router.post('/login', authController.login);
router.post('/logout', authenticate, authController.logout);

// --- Quên mật khẩu ---
router.post('/forgot-password', authController.requestPasswordReset);
router.post('/reset-password', authController.resetPassword);

// --- Token Management (Logic cũ của bạn đã được chuyển vào controller này) ---
router.post('/refresh', authController.refreshToken);

export default router;