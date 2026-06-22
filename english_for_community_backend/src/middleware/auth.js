import { verifyAccessToken, extractToken } from '../lib/jwt_token.js';
import User from '../models/User.js';
import { ROLE_PERMISSIONS, ALL_KNOWN_PERMISSIONS } from '../constants/permissions.js';

export const authenticate = async (req, res, next) => {
  const token = extractToken(req);
  if (!token) return res.status(401).json({ message: 'Authentication required' });

  const { valid, expired, userId } = verifyAccessToken(token);
  if (expired) return res.status(401).json({ message: 'Token expired' });
  if (!valid) return res.status(401).json({ message: 'Invalid token' });

  try {
    const user = await User.findById(userId)
      .select('_id role _destroy isBanned banExpiresAt banReason fullName username email avatarUrl')
      .lean();
    if (!user) return res.status(401).json({ message: 'User not found' });
    if (user._destroy) return res.status(403).json({ message: 'Account disabled' });

    req.user = { ...user, id: user._id.toString() };
    req.userId = user._id;
    next();
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
};

export const requireAdmin = (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
  if (req.user.role === 'admin') return next();
  return res.status(403).json({ message: 'Access denied. Admin role required.' });
};

function resolvePermissionsForRole(role) {
  return ROLE_PERMISSIONS[role] || [];
}

export const requirePermissions = (required = []) => (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
  const userRole = req.user.role || 'user';
  const granted = resolvePermissionsForRole(userRole);

  if (granted.includes('*')) return next();

  const requiredList = Array.isArray(required) ? required : [required];
  const allowed = requiredList.every((perm) => granted.includes(perm));
  if (!allowed) {
    return res.status(403).json({ message: 'Access denied. Missing permissions.' });
  }
  return next();
};

export const getRolePermissions = () => {
  return {
    roles: Object.keys(ROLE_PERMISSIONS),
    defaults: ROLE_PERMISSIONS,
    allPermissions: ALL_KNOWN_PERMISSIONS,
  };
};
