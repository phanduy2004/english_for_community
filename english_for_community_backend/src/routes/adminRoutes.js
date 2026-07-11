import { Router } from 'express';
import { authenticate, requirePermissions } from '../middleware/auth.js';
import adminController from '../controllers/adminController.js';
import { Permission } from '../constants/permissions.js';

const router = Router();

// Middleware bảo vệ: Yêu cầu đăng nhập & quyền Admin
router.use(authenticate);

// 1. Dashboard Stats
router.get('/stats', requirePermissions(Permission.CONTENT_READ), adminController.getDashboardStats);
router.get('/analytics', requirePermissions(Permission.USERS_READ), adminController.getUserAnalytics);
router.get('/content-summary', requirePermissions(Permission.CONTENT_READ), adminController.getContentSummary);

// 2. Quản lý User
router.get('/users', requirePermissions(Permission.USERS_READ), adminController.getAllUsers);
router.get('/users/deleted', requirePermissions(Permission.USERS_READ), adminController.getDeletedUsers);

// --- 🆕 THÊM CÁC ROUTE NÀY ---
// Ban/Unban User
router.patch('/users/:id/ban', requirePermissions(Permission.USERS_READ), adminController.banUser);
router.patch('/users/bulk/ban', requirePermissions(Permission.USERS_READ), adminController.bulkBanUsers);

// Xóa User
router.delete('/users/:id', requirePermissions(Permission.USERS_READ), adminController.deleteUser);
router.post('/users/:id/restore', requirePermissions(Permission.USERS_RESTORE), adminController.restoreUser);
router.patch('/users/bulk/soft-delete', requirePermissions(Permission.USERS_READ), adminController.bulkDeleteUsers);
router.patch('/reports/bulk/status', requirePermissions(Permission.REPORTS_BULK_UPDATE), adminController.bulkUpdateReports);
router.get('/moderation-queue', requirePermissions(Permission.MODERATION_QUEUE_READ), adminController.getModerationQueue);
router.get('/audit-logs', requirePermissions(Permission.USERS_READ), adminController.getAuditLogs);
router.get('/exports/csv', requirePermissions(Permission.EXPORTS_READ), adminController.exportCsv);
router.get('/permission-matrix', requirePermissions(Permission.USERS_READ), adminController.getPermissionMatrix);
router.patch('/users/:id/role', requirePermissions(Permission.USERS_READ), adminController.promoteUser);
router.get('/activities', requirePermissions(Permission.USERS_READ), adminController.getActivities);
router.get('/activities/:id', requirePermissions(Permission.USERS_READ), adminController.getActivityDetail);


// -----------------------------
export default router;