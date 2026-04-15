import express from 'express';
import { listeningCompController } from '../controllers/listeningCompController.js';
import { authenticate, requireAdmin } from '../middleware/auth.js';
import uploadCloud from "../config/cloudinary.js";

const router = express.Router();

// Áp dụng middleware xác thực cho tất cả các route
router.use(authenticate);

// ============================================================
// 🌍 PUBLIC ROUTES (Dành cho app Flutter)
// ============================================================

// Lấy danh sách bài nghe (có phân trang, tìm kiếm, lọc độ khó)
router.get('/', listeningCompController.getAllListenings);

// Nộp bài (Lưu điểm 1 lần cho toàn bộ bài)
router.post('/submit', listeningCompController.submitAttempt);

// Lấy lịch sử làm bài của 1 bài nghe cụ thể
router.get('/attempts', listeningCompController.getAttempts);
router.get('/admin/deleted', requireAdmin, listeningCompController.getDeletedListenings);
router.post('/:id/restore', requireAdmin, listeningCompController.restoreListening);

// Lấy chi tiết 1 bài nghe (kèm câu hỏi) - Lưu ý: Các route có /:id luôn để ở cuối nhóm
router.get('/:id', listeningCompController.getListeningById);


// ============================================================
// 🔐 ADMIN ROUTES (Dành cho CMS/Web Admin)
// ============================================================

// Tạo mới bài nghe (có upload file audio)
router.post('/', requireAdmin, uploadCloud.single('audio'), listeningCompController.createListening);

// Cập nhật bài nghe
router.put('/:id', requireAdmin, uploadCloud.single('audio'), listeningCompController.adminUpdate);

// Xóa bài nghe
router.delete('/:id', requireAdmin, listeningCompController.deleteListening);

export default router;