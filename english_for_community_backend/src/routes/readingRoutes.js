import express from 'express';
import {readingController} from '../controllers/readingController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.get('/', readingController.getAllReadings);

router.get('/history/:readingId', readingController.getAttemptHistory);
router.post('/', readingController.createReading);

router.post('/submit', readingController.submitAttempt);
router.get('/:id', readingController.getReadingById);
router.delete('/:id', readingController.deleteReading);
export default router;