// src/routes/writingTopicRoutes.js
import { Router } from 'express';
import {
  getWritingTopics,
  startWritingForTopic,
  submitForReview,
  updateDraft,
  getTopicSubmissions, getAdminWritingTopics, createWritingTopic, getWritingTopicDetail, updateWritingTopic,
  deleteWritingTopic, deleteSubmission // 1️⃣ Import hàm mới
} from '../controllers/writingTopicController.js';
import {authenticate, requireAdmin} from "../middleware/auth.js";

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
router.delete('/submissions/:id', deleteSubmission);


router.get('/admin/all',requireAdmin, getAdminWritingTopics); // Lấy list cho admin
router.post('/', requireAdmin,createWritingTopic);            // Tạo mới
router.get('/:id', requireAdmin,getWritingTopicDetail);       // Lấy chi tiết (đặt sau /admin/all để tránh conflict route)
router.put('/:id',requireAdmin, updateWritingTopic);          // Sửa
router.delete('/:id',requireAdmin, deleteWritingTopic);
export default router;