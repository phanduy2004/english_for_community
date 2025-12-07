import Notification from '../models/Notification.js';

const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = 20;

    // 1. Lấy danh sách (Mới nhất trước)
    const notifications = await Notification.find({ recipientId: userId })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('senderId', 'fullName avatarUrl');

    // 2. Đếm số lượng chưa đọc (để hiện badge)
    const unreadCount = await Notification.countDocuments({ recipientId: userId, isRead: false });

    // 3. Check xem còn trang sau không
    const totalDocs = await Notification.countDocuments({ recipientId: userId });
    const hasMore = totalDocs > page * limit;

    res.status(200).json({
      data: notifications,
      unreadCount,
      pagination: { page, hasMore }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await Notification.findByIdAndUpdate(id, { isRead: true });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    await Notification.updateMany({ recipientId: userId, isRead: false }, { isRead: true });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const notificationController = { getNotifications, markAsRead, markAllAsRead };