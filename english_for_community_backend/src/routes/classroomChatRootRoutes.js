/**
 * Classroom chat routes không có :classroomId — inbox tổng hợp.
 * Base: /api/classroom-chat
 */
import express from 'express';
import { authenticate } from '../middleware/auth.js';
import * as ctrl from '../controllers/classroomChatController.js';

const router = express.Router();

router.get('/inbox', authenticate, ctrl.getChatInbox);

export default router;
