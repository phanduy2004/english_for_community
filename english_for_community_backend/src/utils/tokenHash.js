import crypto from 'crypto';

/** SHA-256 hash for refresh tokens stored at rest (never store raw JWT refresh tokens). */
export function hashRefreshToken(token) {
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}
