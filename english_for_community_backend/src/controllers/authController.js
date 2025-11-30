import { authService } from '../services/authService.js';

// --- Helper để lấy status code từ lỗi Service ---
const getStatusCode = (err) => err.statusCode || err.status || 500;

// POST /auth/register
const register = async (req, res) => {
  try {
    // Service xử lý hash pass, gửi OTP, và lưu user (chưa verified)
    const newUser = await authService.registerUser(req.body);

    // Trả về email để Client biết mà chuyển sang trang OTP
    return res.status(201).json({
      message: 'Registration successful. OTP sent to email.',
      email: newUser.email
    });
  } catch (error) {
    const status = getStatusCode(error);
    return res.status(status).json({ message: error.message || 'Server error' });
  }
};

// POST /auth/login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Service xử lý check pass, check ban, tạo tokens
    const result = await authService.loginUser(email, password);

    // Trả về tokens và user object
    return res.status(200).json(result);
  } catch (error) {
    const status = getStatusCode(error);
    // Trả về status 403 nếu bị ban, kèm theo reason (lấy từ service)
    return res.status(status).json({
      message: error.message || 'Server error',
      reason: error.reason
    });
  }
};

// POST /auth/logout
const logout = async (req, res) => {
  try {
    // req.userId được cung cấp từ middleware 'authenticate'
    const userId = req.userId;
    await authService.logoutUser(userId);
    return res.status(200).json({ message: 'Logout successful' });
  } catch (error) {
    return res.status(200).json({ message: 'Logout successful' }); // Trả về 200 an toàn
  }
};

// POST /auth/register/resend-otp
const resendSignupOtp = async (req, res) => {
  try {
    const { email } = req.body;
    await authService.requestSignupVerification(email);
    return res.status(200).json({ message: 'OTP has been resent to your email.' });
  } catch (err) {
    const status = getStatusCode(err);
    return res.status(status).json({ message: err.message || 'Server error' });
  }
};

// POST /auth/verify-otp
const verifyOtp = async (req, res) => {
  try {
    // Nhận thêm 'purpose' để biết OTP là cho signup hay forgot password
    const { email, otp, purpose } = req.body;
    await authService.verifyOtp(email, otp, purpose);

    return res.status(200).json({ message: 'OTP verified successfully.' });
  } catch (err) {
    const status = getStatusCode(err);
    return res.status(status).json({ message: err.message || 'Server error' });
  }
};

// POST /auth/forgot-password
const requestPasswordReset = async (req, res) => {
  try {
    await authService.requestPasswordReset(req.body.email);
    // Luôn trả 200 để tránh user enumeration
    return res.status(200).json({ message: 'If the email exists, an OTP has been sent' });
  } catch (err) {
    const status = getStatusCode(err);
    return res.status(status).json({ message: err.message || 'Server error' });
  }
};

// POST /auth/reset-password
const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    await authService.resetPassword(email, otp, newPassword);
    return res.status(200).json({ message: 'Password has been reset successfully' });
  } catch (err) {
    const status = getStatusCode(err);
    return res.status(status).json({ message: err.message || 'Server error' });
  }
};
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    // Gọi service xử lý logic
    const newAccessToken = await authService.refreshToken(refreshToken);

    return res.status(200).json({ accessToken: newAccessToken });
  } catch (err) {
    const status = getStatusCode(err);
    // 401/403 được service xử lý chi tiết
    return res.status(status).json({ message: err.message || 'Server error' });
  }
};

export const authController = {
  login,
  register,
  logout,
  resendSignupOtp,
  verifyOtp,
  requestPasswordReset,
  resetPassword,
  refreshToken
};