import express from 'express';
import { submitDictation } from '../controllers/dictationController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.post('/submit', submitDictation);

export default router;