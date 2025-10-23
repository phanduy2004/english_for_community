// src/routes/writingTopicRoutes.js
import { Router } from 'express';
import { getWritingTopics, startWritingForTopic } from '../controllers/writingTopicController.js';
import {authenticate} from "../middleware/auth.js";

const router = Router();
router.use(authenticate);
router.get('/', getWritingTopics);
router.post('/:id/start', startWritingForTopic);

export default router;
