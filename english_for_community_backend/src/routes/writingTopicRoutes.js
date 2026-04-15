// src/routes/writingTopicRoutes.js
import { Router } from 'express';
import {
  getWritingTopics,
  startWritingForTopic,
  submitForReview,
  updateDraft,
  getTopicSubmissions, getAdminWritingTopics, createWritingTopic, getWritingTopicDetail, updateWritingTopic,
  deleteWritingTopic, deleteSubmission, getWritingTopicVersions, rollbackWritingTopicVersion,
  submitWritingTopicApproval, reviewWritingTopicApproval, getDeletedWritingTopics, restoreWritingTopic
} from '../controllers/writingTopicController.js';
import {authenticate, requirePermissions} from "../middleware/auth.js";

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


router.get('/admin/all', requirePermissions('content.read'), getAdminWritingTopics);
router.get('/admin/deleted', requirePermissions('content.read'), getDeletedWritingTopics);
router.post('/', requirePermissions('content.update'), createWritingTopic);
router.post('/:id/submit-approval', requirePermissions('content.update'), submitWritingTopicApproval);
router.post('/:id/review-approval', requirePermissions('content.approve'), reviewWritingTopicApproval);
router.post('/:id/restore', requirePermissions('content.update'), restoreWritingTopic);
router.get('/:id/versions', requirePermissions('content.version.read'), getWritingTopicVersions);
router.post('/:id/versions/:versionId/rollback', requirePermissions('content.version.rollback'), rollbackWritingTopicVersion);
router.get('/:id', requirePermissions('content.read'), getWritingTopicDetail);
router.put('/:id', requirePermissions('content.update'), updateWritingTopic);
router.delete('/:id', requirePermissions('content.update'), deleteWritingTopic);
export default router;