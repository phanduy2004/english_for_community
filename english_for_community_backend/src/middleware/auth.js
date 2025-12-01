// src/middleware/auth.js
import { verifyAccessToken, extractToken } from '../lib/jwt_token.js';
import User from '../models/User.js';

// 1. Middleware xác thực: Kiểm tra token có hợp lệ không?
export const authenticate = async (req, res, next) => {
  const token = extractToken(req);
  if (!token) return res.status(401).json({ message: 'Authentication required' });

  const { valid, expired, userId } = verifyAccessToken(token);

  if (expired) return res.status(401).json({ message: 'Token expired' });
  if (!valid) return res.status(401).json({ message: 'Invalid token' });

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(401).json({ message: 'User not found' });

    req.user = user; // Lưu toàn bộ user vào req để dùng ở bước sau
    req.userId = user._id;
    next();
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
};

// 2. Middleware phân quyền: Kiểm tra User có phải Admin không?
// (LƯU Ý: Hàm này phải đặt SAU hàm authenticate trong route)
export const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  if (req.user.role === 'admin') {
    next(); // Cho phép đi tiếp
  } else {
    return res.status(403).json({ message: 'Access denied. Admin role required.' });
  }
};