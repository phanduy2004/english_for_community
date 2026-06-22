import jwt from "jsonwebtoken";

// Secrets must come from the environment. Never ship hardcoded fallbacks:
// a known default lets anyone forge access/refresh tokens and impersonate users.
// Accept JWT_SECRET as an alias for the access secret — existing deployments set
// JWT_SECRET, so without this alias the access token would silently fall back to
// a public default (a live token-forgery hole).
const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || process.env.JWT_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

if (!ACCESS_SECRET || !REFRESH_SECRET) {
  const msg = 'Missing JWT_ACCESS_SECRET / JWT_REFRESH_SECRET in environment.';
  if (process.env.NODE_ENV === 'production') {
    // Refuse to boot with insecure tokens in production.
    throw new Error(`${msg} Refusing to start without secure JWT secrets.`);
  }
  console.warn(
    `⚠️  ${msg} Using an INSECURE dev fallback — set both in .env before any shared/remote deploy.`
  );
}

// Dev-only fallback (loud warning above). Production throws before reaching here.
const accessSecret = ACCESS_SECRET || 'dev-only-insecure-access-secret-change-me';
const refreshSecret = REFRESH_SECRET || 'dev-only-insecure-refresh-secret-change-me';

// Tạo Access Token (ngắn hạn, ví dụ: 15 phút)
export const generateAccessToken = (userId) => {
  return jwt.sign({ userId }, accessSecret, { expiresIn: '15m' });
};

// Tạo Refresh Token (dài hạn, ví dụ: 7 ngày)
export const generateRefreshToken = (userId) => {
  return jwt.sign({ userId }, refreshSecret, { expiresIn: '7d' });
};

// Xác thực Access Token
export const verifyAccessToken = (token) => {
  try {
    const decoded = jwt.verify(token, accessSecret);
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
    const decoded = jwt.verify(token, refreshSecret);
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
