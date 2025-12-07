// models/Notification.js
import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  // Người nhận thông báo
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // Người tạo ra thông báo (Ví dụ: Người đã reply/like). Null nếu là SYSTEM.
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  type: {
    type: String,
    enum: ['COMMENT_REPLY', 'COMMENT_REACTION', 'DAILY_REMINDER', 'SYSTEM_ANNOUNCEMENT'],
    required: true
  },

  title: { type: String, required: true },
  message: { type: String, required: true },

  // Dữ liệu payload để Client biết đường navigate
  data: {
    listeningId: String,  // Để mở bài nghe
    commentId: String,    // Để scroll tới comment (nếu làm xịn)
    url: String           // Nếu là System thông báo kèm link
  },

  isRead: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

notificationSchema.index({ recipientId: 1, createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);
export default Notification;