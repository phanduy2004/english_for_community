import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import reportController from '../controllers/reportController.js';

const router = Router();

router.use(authenticate);

// User gửi báo cáo
router.post('/', reportController.createReport);

export default router;