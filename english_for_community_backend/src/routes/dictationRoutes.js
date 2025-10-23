import express from 'express';
import {getDictationAttempts, submitDictation} from '../controllers/dictationController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.post('/submit', submitDictation);
router.get('/attempts', getDictationAttempts);

export default router;