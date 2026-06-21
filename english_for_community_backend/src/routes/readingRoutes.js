import express from 'express';
import { readingController } from '../controllers/readingController.js';
import { authenticate, requireAdmin } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.get('/', readingController.getAllReadings);
router.get('/history/:readingId', readingController.getAttemptHistory);
router.post('/submit', readingController.submitAttempt);

router.get('/admin/deleted', requireAdmin, readingController.getDeletedReadings);
router.post('/:id/restore', requireAdmin, readingController.restoreReading);
router.post('/', requireAdmin, readingController.createReading);
router.delete('/:id', requireAdmin, readingController.deleteReading);

router.get('/:id', readingController.getReadingById);

export default router;
