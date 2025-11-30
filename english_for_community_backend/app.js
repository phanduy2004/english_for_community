// app.js
import cors from 'cors';
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
const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/listening', listeningRoutes);
app.use('/api/writing', writingTopicRoutes);
app.use('/api/speaking', speakingRoutes);
app.use('/api/reading', readingRoutes);
app.use('/api/vocab', vocabRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/admin', adminRoutes);


export default app;
