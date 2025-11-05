// src/routes/writingTopicRoutes.js
import { Router } from 'express';
import {
  getWritingTopics,
  startWritingForTopic,
  submitForReview,
  updateDraft
} from '../controllers/writingTopicController.js';
import {authenticate} from "../middleware/auth.js";

const router = Router();
router.use(authenticate);
router.get('/', getWritingTopics);
router.post('/:id/start', startWritingForTopic);
router.patch('/:id/draft', updateDraft);
router.post('/:id/submit', submitForReview);
export default router;
