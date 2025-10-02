import express from 'express';
import { getLesson } from '../controllers/lessionController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.get('/:id', getLesson);

export default router;