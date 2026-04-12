import Notification from '../models/Notification.js';
import { getIO } from '../socket/socketManager.js';
import User from "../models/User.js";
import { messaging } from '../config/firebase.js';

const createNotification = async ({
                                    recipientId,
                                    senderId,
                                    type,
                                    title,
                                    message,
                                    data,
                                    skipSocket = false, // 🔥 Nhận tham số skipSocket
                                    skipFCM = false     // 🔥 THÊM THAM SỐ skipFCM (Để tránh gửi trùng từ Job)
                                  }) => {
  try {
    const rId = (recipientId && typeof recipientId === 'object' && recipientId._id)
      ? recipientId._id.toString()
      : recipientId.toString();

    let sId = null;
    if (senderId) {
      sId = (typeof senderId === 'object' && senderId._id)
        ? senderId._id.toString()
        : senderId.toString();
    }

    if (sId && rId === sId) return null;

    // 1. Lưu Notification vào DB
    const notification = await Notification.create({
      recipientId: rId,
      senderId: sId,
      type,
      title,
      message,
      data,
      isRead: false
    });

    let senderName = 'Hệ thống';
    if (sId) {
      await notification.populate('senderId', 'fullName avatarUrl');
      if (notification.senderId && notification.senderId.fullName) {
        senderName = notification.senderId.fullName;
      }
    } else {
      notification.senderId = { fullName: 'Hệ thống', avatarUrl: '' };
    }

    // 2. 🔥 KIỂM TRA skipSocket
    if (!skipSocket) {
      try {
        const io = getIO();
        io.to(rId).emit('new_notification', notification);
        // console.log('⚡ Socket event emitted');
      } catch (e) {
        console.error('Socket error:', e.message);
      }
    }

    // 3. 🔥 KIỂM TRA skipFCM
    // Nếu Job đã gửi FCM rồi thì truyền skipFCM: true vào đây để không gửi lại
    if (!skipFCM) {
      try {
        const recipient = await User.findById(rId).select('fcmTokens');
        if (recipient && recipient.fcmTokens && recipient.fcmTokens.length > 0) {

          const messagePayload = {
            notification: {
              title: title,
              body: `${senderName}: ${message}`,
            },
            data: {
              type: type,
              ...Object.keys(data || {}).reduce((acc, key) => {
                acc[key] = String(data[key]);
                return acc;
              }, {}),
              click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            tokens: recipient.fcmTokens
          };

          if (messaging) {
            const response = await messaging.sendEachForMulticast(messagePayload);
            // console.log(`📲 FCM Auto-Send: ${response.successCount} success`);

            // Dọn dẹp token lỗi
            if (response.failureCount > 0) {
              const failedTokens = [];
              response.responses.forEach((resp, idx) => {
                if (!resp.success) failedTokens.push(recipient.fcmTokens[idx]);
              });
              if (failedTokens.length > 0) {
                await User.findByIdAndUpdate(rId, { $pull: { fcmTokens: { $in: failedTokens } } });
              }
            }
          }
        }
      } catch (fcmError) {
        console.error('❌ FCM Error:', fcmError.message);
      }
    }

    return notification;
  } catch (error) {
    console.error('Create notification error:', error);
    return null;
  }
};

/** API user: danh sách + phân trang (không emit socket) */
const listForUser = async (userId, page = 1, limit = 20) => {
  const notifications = await Notification.find({ recipientId: userId })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('senderId', 'fullName avatarUrl');

  const unreadCount = await Notification.countDocuments({ recipientId: userId, isRead: false });
  const totalDocs = await Notification.countDocuments({ recipientId: userId });
  const hasMore = totalDocs > page * limit;

  return {
    data: notifications,
    unreadCount,
    pagination: { page, hasMore },
  };
};

const markOneAsReadForUser = async (userId, notificationId) => {
  const updated = await Notification.findOneAndUpdate(
    { _id: notificationId, recipientId: userId },
    { isRead: true },
    { new: true },
  );
  return updated;
};

const markAllAsReadForUser = async (userId) => {
  await Notification.updateMany(
    { recipientId: userId, isRead: false },
    { isRead: true },
  );
};

export const notificationService = {
  createNotification,
  listForUser,
  markOneAsReadForUser,
  markAllAsReadForUser,
};