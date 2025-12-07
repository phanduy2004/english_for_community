import Notification from '../models/Notification.js';
import { getIO } from '../socket/socketManager.js';

const createNotification = async ({ recipientId, senderId, type, title, message, data }) => {
  try {
    // 🛡️ LỚP BẢO VỆ: Đảm bảo 100% ID là chuỗi (Dù Controller đã làm rồi nhưng cẩn tắc vô áy náy)
    const rId = (typeof recipientId === 'object' && recipientId._id) ? recipientId._id.toString() : recipientId.toString();
    const sId = (typeof senderId === 'object' && senderId._id) ? senderId._id.toString() : senderId.toString();

    // 1. Chặn Self-Notification
    if (rId === sId) return null;

    // 2. Tạo Notification
    const notification = await Notification.create({
      recipientId: rId,
      senderId: sId,
      type,
      title,
      message,
      data
    });

    // 3. Populate
    await notification.populate('senderId', 'fullName avatarUrl');

    // 4. Bắn Socket
    try {
      const io = getIO();
      console.log(`🚀 [Noti Service] Sending to Room: ${rId}`);

      const sockets = await io.in(rId).allSockets();
      if (sockets.size === 0) {
        console.log(`   ⚠️ User ${rId} seems OFFLINE.`);
      } else {
        console.log(`   ✅ Sockets found: ${sockets.size}`);
      }

      io.to(rId).emit('new_notification', notification);
    } catch (e) {
      console.error('Socket error:', e.message);
    }

    return notification;
  } catch (error) {
    console.error('Create notification error:', error);
    return null;
  }
};

export const notificationService = { createNotification };