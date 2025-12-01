import express from 'express';
import { chatWithAI } from '../controllers/chatController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

// POST /api/chat/ask
router.post('/ask',authenticate , chatWithAI);

export default router;