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
import { Permission } from '../constants/permissions.js';

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


router.get('/admin/all', requirePermissions(Permission.CONTENT_READ), getAdminWritingTopics);
router.get('/admin/deleted', requirePermissions(Permission.CONTENT_READ), getDeletedWritingTopics);
router.post('/', requirePermissions(Permission.CONTENT_UPDATE), createWritingTopic);
router.post('/:id/submit-approval', requirePermissions(Permission.CONTENT_UPDATE), submitWritingTopicApproval);
router.post('/:id/review-approval', requirePermissions(Permission.CONTENT_APPROVE), reviewWritingTopicApproval);
router.post('/:id/restore', requirePermissions(Permission.CONTENT_UPDATE), restoreWritingTopic);
router.get('/:id/versions', requirePermissions(Permission.CONTENT_VERSION_READ), getWritingTopicVersions);
router.post('/:id/versions/:versionId/rollback', requirePermissions(Permission.CONTENT_VERSION_ROLLBACK), rollbackWritingTopicVersion);
// Learners need topic detail for practice & integrated exams (same as GET /reading/:id).
router.get('/:id', getWritingTopicDetail);
router.put('/:id', requirePermissions(Permission.CONTENT_UPDATE), updateWritingTopic);
router.delete('/:id', requirePermissions(Permission.CONTENT_UPDATE), deleteWritingTopic);
export default router;