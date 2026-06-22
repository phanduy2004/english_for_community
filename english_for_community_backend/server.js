import 'dotenv/config';
import mongoose from 'mongoose';
import http from 'http';
import app from './app.js';
import { initSocket } from './src/socket/socketManager.js';
import {initSmartNotificationJob} from "./src/jobs/smartNotificationJob.js";
import { initAppReleaseSchedulerJob } from './src/jobs/appReleaseSchedulerJob.js';
import { initExamAttemptExpireJob } from './src/jobs/examAttemptExpireJob.js';

import { getMongoUri, getMongoUriForLog } from './src/lib/mongoUri.js';

const MONGO_URI = getMongoUri();
if (!MONGO_URI) {
  console.error('❌ Missing MONGO_URI in .env');
  process.exit(1);
}

await mongoose.connect(MONGO_URI, {
  maxPoolSize: 20,
  minPoolSize: 5,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  retryWrites: true,
});
console.log(`✅ Connected to MongoDB (${getMongoUriForLog(MONGO_URI)})`);

// 1. Tạo HTTP Server từ Express App
const httpServer = http.createServer(app);

// 2. Khởi tạo Socket.io gắn vào HTTP Server
initSocket(httpServer);
initSmartNotificationJob();
initAppReleaseSchedulerJob();
initExamAttemptExpireJob();
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