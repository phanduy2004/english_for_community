// src/routes/writingTopicRoutes.js
import { Router } from 'express';
import {
  getWritingTopics,
  startWritingForTopic,
  submitForReview,
  updateDraft,
  getTopicSubmissions // 1️⃣ Import hàm mới
} from '../controllers/writingTopicController.js';
import { authenticate } from "../middleware/auth.js";

const router = Router();

// Middleware xác thực user cho tất cả các route bên dưới
router.use(authenticate);

// Lấy danh sách topics
router.get('/', getWritingTopics);

// 2️⃣ Thêm route lấy lịch sử bài làm của một topic cụ thể
// GET /api/writing-topics/:id/submissions
router.get('/:id/submissions', getTopicSubmissions);

// Bắt đầu làm bài (tạo hoặc resume draft)
router.post('/:id/start', startWritingForTopic);

// Lưu nháp (autosave)
router.patch('/:id/draft', updateDraft);

// Nộp bài để chấm điểm
router.post('/:id/submit', submitForReview);

export default router;