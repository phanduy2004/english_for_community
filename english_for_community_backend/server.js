import 'dotenv/config';
import mongoose from 'mongoose';
import http from 'http';
import app from './app.js';
import { initSocket } from './src/socket/socketManager.js';
import {initSmartNotificationJob} from "./src/jobs/smartNotificationJob.js";
import { initAppReleaseSchedulerJob } from './src/jobs/appReleaseSchedulerJob.js';
import { initExamAttemptExpireJob } from './src/jobs/examAttemptExpireJob.js';

const MONGO_URI = process.env.MONGO_URI ?? process.env.MONGODB_URI;
if (!MONGO_URI) {
  console.error('❌ Missing MONGO_URI / MONGODB_URI in .env');
  process.exit(1);
}

// Kết nối DB
await mongoose.connect(MONGO_URI);
console.log('✅ Connected to MongoDB');

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