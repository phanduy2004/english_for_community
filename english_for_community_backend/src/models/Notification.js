// models/Notification.js
import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  // Người nhận thông báo
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // Người tạo ra thông báo (Ví dụ: Người đã reply/like). Null nếu là SYSTEM.
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  type: {
    type: String,
    enum: [
      'COMMENT_REPLY',
      'COMMENT_REACTION',
      'DAILY_REMINDER',
      'SYSTEM_ANNOUNCEMENT',
      'CLASSROOM_JOIN_REQUEST',
      'CLASSROOM_JOIN_APPROVED',
      'CLASSROOM_JOIN_REJECTED',
      'EXAM_ASSIGNED',
      'EXAM_ASSIGNMENT_UPDATED',
      'EXAM_ASSIGNMENT_CLOSED',
      'EXAM_SESSION_LIVE',
      'EXAM_SUBMISSION_RECEIVED',
      'EXAM_RESULTS_RELEASED',
    ],
    required: true
  },

  title: { type: String, required: true },
  message: { type: String, required: true },

  // Payload for deep links (classroomId, assignmentId, listeningId, …)
  data: { type: mongoose.Schema.Types.Mixed, default: {} },

  isRead: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

notificationSchema.index({ recipientId: 1, createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);
export default Notification;