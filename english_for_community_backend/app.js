// app.js
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import authRoutes from './src/routes/authRoutes.js';
import userRoutes from './src/routes/userRoutes.js';
import listeningRoutes from './src/routes/listeningRoutes.js';
import express from 'express';
import writingTopicRoutes from "./src/routes/writingTopicRoutes.js";
import speakingRoutes from "./src/routes/speakingRoutes.js";
import readingRoutes from "./src/routes/readingRoutes.js";
import vocabRoutes from "./src/routes/vocabRoutes.js";
import progressRoutes from "./src/routes/progressRoutes.js";
import chatRoutes from "./src/routes/chatRoutes.js";
import adminRoutes from "./src/routes/adminRoutes.js";
import reportRoutes from "./src/routes/reportRoutes.js";
import notificationRoutes from "./src/routes/notificationRoutes.js";
import listeningCompRoutes from "./src/routes/listeningCompRoutes.js";
import appVersionRoutes from "./src/routes/appVersionRoutes.js";
import adminAppReleaseRoutes from "./src/routes/adminAppReleaseRoutes.js";
import teacherRoutes from "./src/routes/teacherRoutes.js";
import classroomRoutes from "./src/routes/classroomRoutes.js";
import examRoutes from "./src/routes/examRoutes.js";
import classroomChatRoutes from "./src/routes/classroomChatRoutes.js";
import classroomChatRootRoutes from "./src/routes/classroomChatRootRoutes.js";
import { mongoSanitize } from "./src/middleware/sanitize.js";
import { notFoundHandler, errorHandler } from './src/middleware/errorHandler.js';
const app = express();

// Render (và hầu hết PaaS) đặt app sau 1 lớp proxy → gắn header X-Forwarded-For.
// Phải bật trust proxy để Express lấy đúng IP client; nếu không, express-rate-limit
// ném ERR_ERL_UNEXPECTED_X_FORWARDED_FOR và làm hỏng mọi route có rate-limit (login...).
// Dùng số hop (1 = tin proxy đầu tiên) thay vì `true` để tránh IP spoofing.
app.set('trust proxy', Number(process.env.TRUST_PROXY_HOPS ?? 1));

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests. Please slow down.' },
});

const chatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many chat requests. Please slow down.' },
});

app.get('/healthz', (_req, res) => {
  res.status(200).json({ ok: true, uptime: process.uptime() });
});

app.use(helmet());
app.use(compression());
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// CORS: restrict browser origins when CORS_ALLOWED_ORIGINS is set
// (comma-separated). Requests with no Origin header (mobile app, curl,
// server-to-server) are always allowed — CORS only governs browsers, so the
// Flutter mobile client is unaffected; this guards the web (teacher/admin) build.
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

if (allowedOrigins.length === 0) {
  console.warn(
    '⚠️  CORS is open to all origins. Set CORS_ALLOWED_ORIGINS (comma-separated) to restrict browser access.'
  );
  app.use(cors());
} else {
  app.use(
    cors({
      origin(origin, cb) {
        if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
        return cb(new Error('Not allowed by CORS'));
      },
      credentials: true,
    })
  );
}

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use(globalLimiter);
app.use(mongoSanitize); // strip NoSQL operator injection from body/query/params
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/listening', listeningRoutes);
app.use('/api/writing', writingTopicRoutes);
app.use('/api/speaking', speakingRoutes);
app.use('/api/reading', readingRoutes);
app.use('/api/vocab', vocabRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/chat', chatLimiter, chatRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/listening-comp', listeningCompRoutes);
app.use('/api/app', appVersionRoutes);
app.use('/api/admin/app-releases', adminAppReleaseRoutes);
app.use('/api/teacher', teacherRoutes);
app.use('/api/classrooms', classroomRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/classroom-chat', classroomChatRootRoutes);
app.use('/api/classroom-chat/:classroomId', classroomChatRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
