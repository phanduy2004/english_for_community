import 'dotenv/config';
import mongoose from 'mongoose';
import http from 'http';
import app from './app.js';
import { initSocket } from './src/socket/socketManager.js';
import {initSmartNotificationJob} from "./src/jobs/smartNotificationJob.js";
import { initAppReleaseSchedulerJob } from './src/jobs/appReleaseSchedulerJob.js';
import { initExamAttemptExpireJob } from './src/jobs/examAttemptExpireJob.js';
import { initExamSessionExpireJob } from './src/jobs/examSessionExpireJob.js';
import User from './src/models/User.js';

import { getMongoUri, getMongoUriForLog, getMongoDbName } from './src/lib/mongoUri.js';

const MONGO_URI = getMongoUri();
if (!MONGO_URI) {
  console.error('❌ Missing MONGO_URI in .env');
  process.exit(1);
}

// dbName tường minh: nếu URI thiếu path DB, Mongoose sẽ dùng 'test' → ép đúng DB ở đây.
const MONGO_DB_NAME = getMongoDbName();

await mongoose.connect(MONGO_URI, {
  dbName: MONGO_DB_NAME,
  maxPoolSize: 20,
  minPoolSize: 5,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  retryWrites: true,
});
console.log(
  `✅ Connected to MongoDB (${getMongoUriForLog(MONGO_URI)}) [db: ${MONGO_DB_NAME}]`
);

// Cờ isOnline còn sót từ vòng đời process trước (Render restart/crash/spin-down) → reset.
try {
  const r = await User.updateMany({ isOnline: true }, { $set: { isOnline: false } });
  console.log(`🧹 Presence boot-reset: ${r.modifiedCount} user(s) → offline`);
} catch (e) {
  console.error('Presence boot-reset failed:', e?.message || e);
}

// 1. Tạo HTTP Server từ Express App
const httpServer = http.createServer(app);

// 2. Khởi tạo Socket.io gắn vào HTTP Server
initSocket(httpServer);
initSmartNotificationJob();
initAppReleaseSchedulerJob();
initExamAttemptExpireJob();
initExamSessionExpireJob();
// 3. Lắng nghe port (Dùng httpServer.listen thay vì app.listen)
const PORT = Number(process.env.PORT ?? 3000);
httpServer.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`🔌 Socket.IO ready`);
});

const shutdown = async (signal) => {
  console.log(`\n${signal} received — shutting down gracefully`);
  httpServer.close(() => {
    console.log('HTTP server closed');
  });
  try {
    await mongoose.connection.close(false);
    console.log('MongoDB connection closed');
  } catch (err) {
    console.error('Error closing MongoDB:', err?.message || err);
  }
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('unhandledRejection', (reason) => {
  console.error('💥 Unhandled promise rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('💥 Uncaught exception:', err);
});
