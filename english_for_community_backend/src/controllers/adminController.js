import { adminService } from '../services/adminService.js';
import { getIO } from '../socket/socketManager.js';
import { writeAdminAudit, listAdminAudits } from '../services/adminAuditService.js';
import { getRolePermissions } from '../middleware/auth.js';
import { VALID_ROLES } from '../constants/permissions.js';
import User from '../models/User.js';
const getDashboardStats = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const result = await adminService.getDashboardStats(range);
    return res.status(200).json(result);
  } catch (error) {
    console.error("Dashboard Stats Error:", error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getUserAnalytics = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const result = await adminService.getUserAnalytics(range);
    return res.status(200).json(result);
  } catch (error) {
    console.error("User Analytics Error:", error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { filter, search, role } = req.query;

    const result = await adminService.getAllUsers(page, limit, filter, search, role);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
};

const getReports = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { status } = req.query;

    const result = await adminService.getReports(page, limit, status);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching reports', error: error.message });
  }
};

const updateReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminResponse } = req.body;

    const report = await adminService.updateReportStatus(id, status, adminResponse);
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'report.status.update',
      targetType: 'report',
      targetId: id,
      metadata: { status, adminResponse },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    res.status(200).json({ message: 'Report updated successfully', report });
  } catch (error) {
    if (error.message === 'Report not found') return res.status(404).json({ message: error.message });
    res.status(500).json({ message: 'Error updating report', error: error.message });
  }
};

const banUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { banType, durationInHours, reason } = req.body;

    const result = await adminService.updateUserBanStatus(id, banType, durationInHours, reason);
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.ban.update',
      targetType: 'user',
      targetId: id,
      metadata: { banType, durationInHours, reason },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });

    // --- XỬ LÝ SOCKET Ở CONTROLLER ---
    if (result.banType !== 'unban') {
      // Kick user qua socket
      getIO().to(id).emit('force_logout', { reason: result.socketMessage });
      // Báo cho Admin online biết user này vừa bị sút
      getIO().to('admin_room').emit('user_status_change', { userId: id, isOnline: false });
    }

    res.status(200).json({ message: 'User status updated', user: result.user });
  } catch (error) {
    if (error.message === 'User not found') return res.status(404).json({ message: error.message });
    res.status(500).json({ message: 'Error updating user status', error: error.message });
  }
};

const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    await adminService.deleteUser(id);
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.soft_delete',
      targetType: 'user',
      targetId: id,
      metadata: {},
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });

    // Xử lý socket
    getIO().to(id).emit('force_logout', { reason: 'Tài khoản đã bị xóa.' });

    res.status(200).json({ message: 'User deleted' });
  } catch (error) {
    if (error.message === 'User not found') return res.status(404).json({ message: error.message });
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const getDeletedUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { search } = req.query;
    const data = await adminService.listDeletedUsers(page, limit, search);
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const restoreUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await adminService.restoreUser(id);
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.restore',
      targetType: 'user',
      targetId: id,
      metadata: {},
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    res.status(200).json({ message: 'User restored', user });
  } catch (error) {
    if (error.message === 'User not found') return res.status(404).json({ message: error.message });
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const bulkBanUsers = async (req, res) => {
  try {
    const { userIds = [], banType, durationInHours, reason } = req.body;
    const result = await adminService.bulkBanUsers({ userIds, banType, durationInHours, reason });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.bulk_ban',
      targetType: 'user',
      targetId: 'bulk',
      metadata: { userIdsCount: userIds.length, banType, durationInHours, reason },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    res.status(200).json({ message: 'Bulk user ban updated', ...result });
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const bulkDeleteUsers = async (req, res) => {
  try {
    const { userIds = [] } = req.body;
    const result = await adminService.bulkDeleteUsers({ userIds });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.bulk_soft_delete',
      targetType: 'user',
      targetId: 'bulk',
      metadata: { userIdsCount: userIds.length },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    res.status(200).json({ message: 'Bulk user soft delete done', ...result });
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const bulkUpdateReports = async (req, res) => {
  try {
    const { reportIds = [], status, adminResponse } = req.body;
    const result = await adminService.bulkUpdateReports({ reportIds, status, adminResponse });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'report.bulk_status.update',
      targetType: 'report',
      targetId: 'bulk',
      metadata: { reportIdsCount: reportIds.length, status },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    res.status(200).json({ message: 'Bulk report status updated', ...result });
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const getModerationQueue = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const slaHours = parseInt(req.query.slaHours) || 24;
    const result = await adminService.getModerationQueue({ page, limit, slaHours });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const getAuditLogs = async (req, res) => {
  try {
    const { page = 1, limit = 20, action, targetType, actorId } = req.query;
    const result = await listAdminAudits({ page, limit, action, targetType, actorId });
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Error', error: error.message });
  }
};

const exportCsv = async (req, res) => {
  try {
    const { resource = 'users', onlyDeleted = 'false' } = req.query;
    let csv = '';
    if (resource === 'users') {
      csv = await adminService.exportUsersCsv({ onlyDeleted: onlyDeleted === 'true' });
    } else if (resource === 'reports') {
      csv = await adminService.exportReportsCsv();
    } else if (resource === 'audit_logs') {
      csv = await adminService.exportAuditLogsCsv();
    } else {
      return res.status(400).json({ message: 'Unsupported resource' });
    }
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${resource}.csv"`);
    return res.status(200).send(csv);
  } catch (error) {
    return res.status(500).json({ message: 'Error', error: error.message });
  }
};

const getPermissionMatrix = (req, res) => {
  try {
    const data = getRolePermissions();
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ message: 'Error', error: error.message });
  }
};

const promoteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!role || !VALID_ROLES.includes(role)) {
      return res.status(400).json({ message: `Invalid role. Allowed: ${VALID_ROLES.join(', ')}` });
    }

    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: 'User not found' });
    if (target._destroy) return res.status(400).json({ message: 'Cannot change role of deleted user' });

    const oldRole = target.role;
    if (oldRole === role) return res.status(200).json({ message: 'No change', user: target });

    // Chặn tự đổi vai trò của chính mình (tránh tự gỡ quyền admin).
    if (req.user?._id?.toString() === String(id)) {
      return res.status(400).json({ message: 'Không thể đổi vai trò của chính bạn' });
    }
    // Chặn hạ cấp admin cuối cùng → nếu không sẽ khoá cứng toàn hệ thống (không còn admin).
    if (oldRole === 'admin' && role !== 'admin') {
      const adminCount = await User.countDocuments({ role: 'admin', _destroy: { $ne: true } });
      if (adminCount <= 1) {
        return res.status(400).json({ message: 'Không thể hạ cấp admin cuối cùng của hệ thống' });
      }
    }

    target.role = role;
    await target.save();

    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'user.role.update',
      targetType: 'user',
      targetId: id,
      metadata: { oldRole, newRole: role },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });

    if (role === 'user' && oldRole === 'admin') {
      getIO().to(id).emit('force_logout', { reason: 'Your admin access has been revoked.' });
    }

    return res.status(200).json({ message: `Role updated: ${oldRole} → ${role}`, user: target });
  } catch (error) {
    return res.status(500).json({ message: 'Error', error: error.message });
  }
};

const getActivities = async (req, res) => {
  try {
    const { startDate, endDate, type, userId } = req.query;

    const data = await adminService.getActivities(userId, startDate, endDate, type);

    res.status(200).json({
      success: true,
      count: data.length,
      data: data
    });
  } catch (error) {
    console.error('Admin Activity List Error:', error);
    res.status(500).json({ message: error.message });
  }
};

const getContentSummary = async (req, res) => {
  try {
    const data = await adminService.getContentSummary();
    res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Admin Content Summary Error:', error);
    res.status(500).json({ message: error.message });
  }
};

const getStatusCode = (err) => err.statusCode || 500;

const getActivityDetail = async (req, res) => {
  try {
    const { id } = req.params;

    // 🔥 1. ĐẢM BẢO PHẢI CÓ subType Ở ĐÂY
    const { type, subType } = req.query;

    if (!type) {
      return res.status(400).json({ message: "Missing 'type' parameter" });
    }

    // 🔥 2. TRUYỀN ĐỦ 3 THAM SỐ VÀO SERVICE
    const data = await adminService.getActivityDetail(id, type, subType);

    res.status(200).json({
      success: true,
      data: data
    });
  } catch (error) {
    console.error('Admin Activity Detail Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export default {
  getDashboardStats,
  getUserAnalytics,
  getAllUsers,
  getReports,
  updateReportStatus,
  banUser,
  deleteUser,
  getDeletedUsers,
  restoreUser,
  bulkBanUsers,
  bulkDeleteUsers,
  bulkUpdateReports,
  getModerationQueue,
  getAuditLogs,
  exportCsv,
  getPermissionMatrix,
  promoteUser,
  getActivities,
  getActivityDetail,
  getContentSummary,
};
