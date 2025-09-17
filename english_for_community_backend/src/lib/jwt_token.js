// src/lib/jwt_token.js
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '1h' });
};

export const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return { valid: true, expired: false, userId: decoded.userId };
  } catch (error) {
    return {
      valid: false,
      expired: error.name === 'TokenExpiredError',
      userId: null,
    };
  }
};

// Chỉ lấy token từ Authorization header dạng "Bearer <token>"
export const extractToken = (req) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7); // cắt "Bearer "
  }
  return null;
};

// Không dùng cookie nữa nên clearToken là no-op (tuỳ thích)
export const clearToken = () => {};
