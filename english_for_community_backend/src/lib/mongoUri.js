import { loadEnv } from './loadEnv.js';

/**
 * Một nguồn DB duy nhất: biến MONGO_URI trong english_for_community_backend/.env
 */
export function getMongoUri() {
  loadEnv();
  const uri = process.env.MONGO_URI?.trim();
  return uri || null;
}

/**
 * Tên database hiệu lực, truyền vào mongoose.connect({ dbName }).
 *   - MONGO_DB_NAME (env) nếu có — override tường minh.
 *   - Mặc định 'english_community' (tên DB thật của dự án).
 * Ép tên DB ở đây (thay vì phụ thuộc path trong URI) để:
 *   (1) KHÔNG bao giờ rơi về DB mặc định 'test' khi URI thiếu /db;
 *   (2) tránh nối nhầm khi URI mang path sai (vd .env.example cũ ghi 'english_for_community').
 */
export function getMongoDbName() {
  loadEnv();
  return process.env.MONGO_DB_NAME?.trim() || 'english_community';
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
