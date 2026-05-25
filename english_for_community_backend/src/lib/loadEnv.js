import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
/** Thư mục gốc backend (chứa .env), không phụ thuộc cwd khi chạy npm/node. */
export const backendRoot = path.resolve(__dirname, '../..');

let loaded = false;

export function loadEnv() {
  if (loaded) return;
  dotenv.config({ path: path.join(backendRoot, '.env') });
  loaded = true;
}
