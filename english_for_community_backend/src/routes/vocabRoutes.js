import express from 'express';
// 🔽 ✍️ SỬA LẠI IMPORT: Import object 'vocabController'
import { vocabController } from '../controllers/vocabController.js';
import {authenticate} from "../middleware/auth.js";

const router = express.Router();
router.use(authenticate);

router.post('/learn', vocabController.startLearningWord);
router.post('/save',  vocabController.saveWord);
router.get('/learning', vocabController.getLearningWords);
router.get('/saved',  vocabController.getSavedWords);
router.get('/recent', vocabController.getRecentWords);
router.get('/review', vocabController.getReviewWords);
router.post('/recent', vocabController.logRecentWord);
router.get('/review', vocabController.getReviewWords);
router.post('/review-update', vocabController.updateWordReview);
router.get('/daily-reminders', vocabController.getDailyReminders);
export default router;