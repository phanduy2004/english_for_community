import { loadEnv } from './loadEnv.js';

/**
 * Một nguồn DB duy nhất: biến MONGO_URI trong english_for_community_backend/.env
 */
export function getMongoUri() {
  loadEnv();
  const uri = process.env.MONGO_URI?.trim();
  return uri || null;
}

/** In log an toàn (ẩn password). */
export function getMongoUriForLog(uri = getMongoUri()) {
  if (!uri) return '(not set)';
  try {
    const u = new URL(uri.replace(/^mongodb(\+srv)?:\/\//, 'https://'));
    const db = u.pathname?.replace(/^\//, '') || '';
    const host = u.hostname || uri;
    return db ? `${host}/${db}` : host;
  } catch {
    return uri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:***@');
  }
}
