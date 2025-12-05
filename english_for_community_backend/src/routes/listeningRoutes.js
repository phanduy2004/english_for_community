import express from 'express';
import { listeningController } from '../controllers/listeningController.js';
import {authenticate, requireAdmin} from '../middleware/auth.js';
import uploadCloud from "../config/cloudinary.js";

const router = express.Router();

// Áp dụng middleware xác thực
router.use(authenticate);

// ============================================================
// 🌍 GENERAL ROUTES
// ============================================================

// 1. Lấy danh sách bài nghe
// GET /api/listenings
router.get('/', listeningController.getAllListenings);

// 2. Nộp bài (Gộp từ dictationRoutes cũ)
// POST /api/listenings/submit
router.post('/submit', listeningController.submitAttempt);

// 3. Lấy lịch sử làm bài (Gộp từ dictationRoutes cũ)
// GET /api/listenings/attempts?listeningId=...
router.get('/attempts', listeningController.getAttempts);

// 4. Lấy chi tiết bài nghe
// GET /api/listenings/:id
// ⚠️ QUAN TRỌNG: Route có param /:id phải để cuối cùng trong nhóm GET
router.get('/:id', listeningController.getListeningById);

// ============================================================
// 🔐 ADMIN ROUTES
// ============================================================

// Tạo mới
router.post('/', requireAdmin, uploadCloud.single('audio'), listeningController.createListening);
// Cập nhật
router.put('/:id', requireAdmin, uploadCloud.single('audio'), listeningController.adminUpdate);
router.delete('/:id', requireAdmin, listeningController.deleteListening);

export default router;