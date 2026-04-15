// src/middleware/auth.js
import { verifyAccessToken, extractToken } from '../lib/jwt_token.js';
import User from '../models/User.js';
import RolePermission from '../models/RolePermission.js';

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
    if (user._destroy) return res.status(403).json({ message: 'Account disabled' });

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

const ROLE_PERMISSIONS = {
  admin: ['*'],
  moderator: [
    'reports.read',
    'reports.update',
    'reports.bulk_update',
    'moderation.queue.read',
    'users.read',
    'users.restore',
    'exports.read',
  ],
  content_manager: [
    'content.read',
    'content.update',
    'content.version.read',
    'content.version.rollback',
    'content.approve',
    'users.read',
    'exports.read',
  ],
  support: [
    'reports.read',
    'reports.update',
    'users.read',
    'exports.read',
  ],
  user: [],
};

async function resolvePermissionsForRole(role) {
  const dynamic = await RolePermission.findOne({ role, isActive: true }).lean();
  if (dynamic && Array.isArray(dynamic.permissions)) return dynamic.permissions;
  return ROLE_PERMISSIONS[role] || [];
}

export const requirePermissions = (required = []) => async (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
  const userRole = req.user.role || 'user';
  const granted = await resolvePermissionsForRole(userRole);
  if (granted.includes('*')) return next();

  const requiredList = Array.isArray(required) ? required : [required];
  const allowed = requiredList.every((perm) => granted.includes(perm));
  if (!allowed) {
    return res.status(403).json({ message: 'Access denied. Missing permissions.' });
  }
  return next();
};

export const upsertRolePermissions = async (role, permissions = []) => {
  if (!role) return null;
  return RolePermission.findOneAndUpdate(
    { role },
    { $set: { permissions, isActive: true } },
    { upsert: true, new: true }
  );
};

export const getRolePermissions = async () => {
  const dynamic = await RolePermission.find({ isActive: true }).lean();
  const map = {};
  dynamic.forEach((item) => {
    map[item.role] = item.permissions || [];
  });
  return { defaults: ROLE_PERMISSIONS, dynamic: map };
};