import express from 'express';
import { getCues } from '../controllers/cueController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.get('/', getCues);

export default router;