import { Router } from 'express';
import { authenticate, requireAdmin } from '../middleware/auth.js';
import adminController from '../controllers/adminController.js';

const router = Router();

// Middleware bảo vệ: Yêu cầu đăng nhập & quyền Admin
router.use(authenticate);
router.use(requireAdmin);

// 1. Dashboard Stats
router.get('/stats', adminController.getDashboardStats);

// 2. Quản lý User
router.get('/users', adminController.getAllUsers);

// --- 🆕 THÊM CÁC ROUTE NÀY ---
// Ban/Unban User
router.patch('/users/:id/ban', adminController.banUser);

// Xóa User
router.delete('/users/:id', adminController.deleteUser);
router.get('/activities', adminController.getActivities);
router.get('/activities/:id', adminController.getActivityDetail);

// -----------------------------
export default router;