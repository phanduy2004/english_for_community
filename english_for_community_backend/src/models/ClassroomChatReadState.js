import mongoose from 'mongoose';

/**
 * Trạng thái đã đọc chat nhóm lớp theo từng user.
 * unread = tin nhắn createdAt > lastReadAt từ người khác.
 */
const classroomChatReadStateSchema = new mongoose.Schema(
  {
    classroomId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Classroom',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    lastReadAt: { type: Date, default: null },
    /** Tắt thông báo hội thoại (per-user). */
    muted: { type: Boolean, default: false },
    /** Thời điểm ghim hội thoại (per-user); null = không ghim. */
    pinnedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

classroomChatReadStateSchema.index({ classroomId: 1, userId: 1 }, { unique: true });

const ClassroomChatReadState = mongoose.model(
  'ClassroomChatReadState',
  classroomChatReadStateSchema
);
export default ClassroomChatReadState;
