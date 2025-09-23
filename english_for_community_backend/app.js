// app.js
import cors from 'cors';
import authRoutes from './src/routes/authRoutes.js';
import userRoutes from './src/routes/userRoutes.js';
import lessonRoutes from './src/routes/lessonRoutes.js';
import listeningRoutes from './src/routes/listeningRoutes.js';
import cueRoutes from './src/routes/cueRoutes.js';
import dictationRoutes from './src/routes/dictationRoutes.js';
import express from 'express';


const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/users', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/lessons', lessonRoutes);
app.use('/api/listenings', listeningRoutes);
app.use('/api/cues', cueRoutes);
app.use('/api/dictation', dictationRoutes);

export default app;
