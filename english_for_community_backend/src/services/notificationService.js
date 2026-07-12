import Notification from '../models/Notification.js';
import { getIO } from '../socket/socketManager.js';
import User from "../models/User.js";
import { messaging, fcmDeliveryOptions } from '../config/firebase.js';
import { serializeNotificationRows } from '../lib/leanApiSerialize.js';

/** Plain JSON for Socket.IO clients (Flutter/web). */
export function toNotificationSocketPayload(doc) {
  const o = doc?.toObject ? doc.toObject({ virtuals: true }) : { ...doc };
  const id = o._id?.toString?.() ?? String(o._id ?? o.id ?? '');
  const payload = {
    _id: id,
    id,
    recipientId: o.recipientId?.toString?.() ?? o.recipientId,
    type: o.type,
    title: o.title,
    message: o.message,
    data: o.data && typeof o.data === 'object' ? o.data : {},
    isRead: !!o.isRead,
    createdAt: o.createdAt instanceof Date ? o.createdAt.toISOString() : o.createdAt,
  };
  if (o.senderId && typeof o.senderId === 'object') {
    payload.senderId = {
      _id: o.senderId._id?.toString?.() ?? o.senderId._id,
      fullName: o.senderId.fullName ?? '',
      avatarUrl: o.senderId.avatarUrl ?? '',
    };
  } else if (o.senderId) {
    payload.senderId = o.senderId.toString();
  }
  return payload;
}

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
        const socketPayload = toNotificationSocketPayload(notification);
        io.to(rId).emit('new_notification', socketPayload);
        console.log(`⚡ [Socket] new_notification → room ${rId} (${type})`);
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
            ...fcmDeliveryOptions, // high-priority + channel + apns
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

/**
 * Gửi FCM push tới NHIỀU user mà KHÔNG tạo bản ghi Notification (không vào chuông).
 * Dùng cho thông báo "đẩy thuần" như tin nhắn chat lớp: user nhận được cả khi app
 * đã đóng, nhưng KHÔNG hiển thị trong hộp thư chuông (chat vẫn thuộc chat-inbox).
 * Gộp 1 lần multicast cho toàn bộ token + tự dọn token lỗi theo từng user.
 */
export const sendPushToUsers = async ({ userIds, title, body, data = {}, excludeUserId = null }) => {
  try {
    if (!messaging) return { ok: false, reason: 'FCM_NOT_CONFIGURED' };

    const exclude = excludeUserId != null ? String(excludeUserId) : null;
    const ids = [...new Set((userIds || []).map(String).filter(Boolean))]
      .filter((id) => id !== exclude);
    if (!ids.length) return { ok: false, reason: 'NO_RECIPIENTS' };

    const users = await User.find({ _id: { $in: ids } }).select('_id fcmTokens').lean();
    const tokenOwner = new Map(); // token -> userId (để dọn token lỗi)
    const tokens = [];
    for (const u of users) {
      for (const t of u.fcmTokens || []) {
        if (t && !tokenOwner.has(t)) {
          tokenOwner.set(t, String(u._id));
          tokens.push(t);
        }
      }
    }
    if (!tokens.length) return { ok: false, reason: 'NO_TOKEN' };

    const messagePayload = {
      notification: { title, body },
      data: {
        ...Object.keys(data || {}).reduce((acc, key) => {
          acc[key] = String(data[key]);
          return acc;
        }, {}),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      ...fcmDeliveryOptions, // high-priority + channel + apns (đánh thức máy khi app đã kill)
      tokens,
    };

    const response = await messaging.sendEachForMulticast(messagePayload);

    // Dọn token lỗi theo từng user
    if (response.failureCount > 0) {
      const failedByUser = new Map();
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const owner = tokenOwner.get(tokens[idx]);
          if (owner) {
            if (!failedByUser.has(owner)) failedByUser.set(owner, []);
            failedByUser.get(owner).push(tokens[idx]);
          }
        }
      });
      await Promise.all(
        [...failedByUser.entries()].map(([uid, toks]) =>
          User.findByIdAndUpdate(uid, { $pull: { fcmTokens: { $in: toks } } })
        )
      );
    }

    return {
      ok: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('❌ sendPushToUsers error:', error.message);
    return { ok: false, reason: 'ERROR', message: error.message };
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
    data: serializeNotificationRows(notifications),
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

export { createNotification };

export const notificationService = {
  createNotification,
  sendPushToUsers,
  listForUser,
  markOneAsReadForUser,
  markAllAsReadForUser,
};