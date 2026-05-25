import { notificationService } from '../services/notificationService.js';

const getNotifications = async (req, res) => {
  try {
    const userId = req.user._id?.toString?.() ?? req.user.id?.toString?.();
    const page = parseInt(req.query.page, 10) || 1;
    const limit = 20;

    const result = await notificationService.listForUser(userId, page, limit);

    res.status(200).json({
      data: result.data,
      unreadCount: result.unreadCount,
      pagination: result.pagination,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id?.toString?.() ?? req.user.id?.toString?.();

    const updated = await notificationService.markOneAsReadForUser(userId, id);
    if (!updated) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id?.toString?.() ?? req.user.id?.toString?.();
    await notificationService.markAllAsReadForUser(userId);
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const notificationController = { getNotifications, markAsRead, markAllAsRead };
