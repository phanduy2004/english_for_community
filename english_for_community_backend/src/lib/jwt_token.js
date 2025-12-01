import jwt from "jsonwebtoken";

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'your-access-secret-key';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';

// Tạo Access Token (ngắn hạn, ví dụ: 15 phút)
export const generateAccessToken = (userId) => {
  return jwt.sign({ userId }, ACCESS_SECRET, { expiresIn: '15m' });
};

// Tạo Refresh Token (dài hạn, ví dụ: 7 ngày)
export const generateRefreshToken = (userId) => {
  return jwt.sign({ userId }, REFRESH_SECRET, { expiresIn: '7d' });
};

// Xác thực Access Token
export const verifyAccessToken = (token) => {
  try {
    const decoded = jwt.verify(token, ACCESS_SECRET);
    return { valid: true, expired: false, userId: decoded.userId };
  } catch (error) {
    return {
      valid: false,
      expired: error.name === 'TokenExpiredError',
      userId: null,
    };
  }
};

// Xác thực Refresh Token
export const verifyRefreshToken = (token) => {
  try {
    const decoded = jwt.verify(token, REFRESH_SECRET);
    return { valid: true, expired: false, userId: decoded.userId };
  } catch (error) {
    return {
      valid: false,
      expired: error.name === 'TokenExpiredError',
      userId: null,
    };
  }
};

export const extractToken = (req) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7); // cắt "Bearer "
  }
  return null;
};
