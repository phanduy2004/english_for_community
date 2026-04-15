import { Router } from 'express';
import { authenticate, requirePermissions } from '../middleware/auth.js';
import adminController from '../controllers/adminController.js';

const router = Router();

// Middleware bảo vệ: Yêu cầu đăng nhập & quyền Admin
router.use(authenticate);

// 1. Dashboard Stats
router.get('/stats', requirePermissions('content.read'), adminController.getDashboardStats);
router.get('/content-summary', requirePermissions('content.read'), adminController.getContentSummary);

// 2. Quản lý User
router.get('/users', requirePermissions('users.read'), adminController.getAllUsers);
router.get('/users/deleted', requirePermissions('users.read'), adminController.getDeletedUsers);

// --- 🆕 THÊM CÁC ROUTE NÀY ---
// Ban/Unban User
router.patch('/users/:id/ban', requirePermissions('users.read'), adminController.banUser);
router.patch('/users/bulk/ban', requirePermissions('users.read'), adminController.bulkBanUsers);

// Xóa User
router.delete('/users/:id', requirePermissions('users.read'), adminController.deleteUser);
router.post('/users/:id/restore', requirePermissions('users.restore'), adminController.restoreUser);
router.patch('/users/bulk/soft-delete', requirePermissions('users.read'), adminController.bulkDeleteUsers);
router.patch('/reports/bulk/status', requirePermissions('reports.bulk_update'), adminController.bulkUpdateReports);
router.get('/moderation-queue', requirePermissions('moderation.queue.read'), adminController.getModerationQueue);
router.get('/audit-logs', requirePermissions('users.read'), adminController.getAuditLogs);
router.get('/exports/csv', requirePermissions('exports.read'), adminController.exportCsv);
router.get('/permission-matrix', requirePermissions('users.read'), adminController.getPermissionMatrix);
router.put('/permission-matrix', requirePermissions('users.read'), adminController.updateRolePermissions);
router.get('/activities', requirePermissions('users.read'), adminController.getActivities);
router.get('/activities/:id', requirePermissions('users.read'), adminController.getActivityDetail);

// -----------------------------
export default router;