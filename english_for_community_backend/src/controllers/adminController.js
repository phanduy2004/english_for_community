import { adminService } from '../services/adminService.js';
import { getIO } from '../socket/socketManager.js';

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

const getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { filter, search } = req.query;

    const result = await adminService.getAllUsers(page, limit, filter, search);
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

    // Xử lý socket
    getIO().to(id).emit('force_logout', { reason: 'Tài khoản đã bị xóa.' });

    res.status(200).json({ message: 'User deleted' });
  } catch (error) {
    if (error.message === 'User not found') return res.status(404).json({ message: error.message });
    res.status(500).json({ message: 'Error', error: error.message });
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
  getAllUsers,
  getReports,
  updateReportStatus,
  banUser,
  deleteUser,
  getActivities,
  getActivityDetail
};