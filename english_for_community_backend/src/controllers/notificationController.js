import { notificationService } from '../services/notificationService.js';
import { notificationActionService } from '../services/notificationActionService.js';

function getStatusCode(err) {
  return err.statusCode || 500;
}

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

const respond = async (req, res) => {
  try {
    const userId = req.user._id?.toString?.() ?? req.user.id?.toString?.();
    const { action } = req.body || {};
    const result = await notificationActionService.respond(userId, req.params.id, action);
    return res.status(200).json(result);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const notificationController = { getNotifications, markAsRead, markAllAsRead, respond };
