import mongoose from 'mongoose';
import { toJsonIdPlugin } from '../lib/mongoosePlugins.js';

/**
 * ClassroomMessage — tin nhắn nhóm lớp học.
 *
 * Hỗ trợ: text | image | video | file
 * Tính năng: reply, reaction (emoji), @mention, soft-delete, edit.
 */

const reactionSchema = new mongoose.Schema(
  {
    emoji: { type: String, required: true },         // "❤️" | "👍" | …
    userIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { _id: false }
);

const mediaSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    name: { type: String, default: '' },              // original filename
    size: { type: Number, default: 0 },               // bytes
    mimeType: { type: String, default: '' },
    thumbnailUrl: { type: String, default: '' },      // for image/video preview
    width: Number,
    height: Number,
    durationSeconds: Number,                          // for video
  },
  { _id: false }
);

const replySnapshotSchema = new mongoose.Schema(
  {
    messageId: { type: mongoose.Schema.Types.ObjectId },
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    senderName: { type: String, default: '' },
    contentPreview: { type: String, default: '' },    // first 120 chars of text / filename
    messageType: { type: String, default: 'text' },
  },
  { _id: false }
);

const classroomMessageSchema = new mongoose.Schema(
  {
    classroomId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Classroom',
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    type: {
      type: String,
      enum: ['text', 'image', 'video', 'file'],
      default: 'text',
    },

    content: { type: String, default: '' },           // plain text (with @mention markup)
    media: { type: mediaSchema, default: null },

    /** Embedded snapshot so reply preview works even if original is deleted. */
    replyTo: { type: replySnapshotSchema, default: null },

    /** List of mentioned user IDs (for push notification targeting). */
    mentions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    reactions: { type: [reactionSchema], default: [] },

    /** Soft-delete: keep record for reply previews; hide content in clients. */
    deletedAt: { type: Date, default: null },

    editedAt: { type: Date, default: null },

    /** Client-generated idempotency key to avoid duplicate sends on retry. */
    clientId: { type: String, default: null, index: true, sparse: true },
  },
  { timestamps: true }
);

// Pagination: newest first for a classroom
classroomMessageSchema.index({ classroomId: 1, createdAt: -1 });
classroomMessageSchema.index({ senderId: 1, createdAt: -1 });

toJsonIdPlugin(classroomMessageSchema);

classroomMessageSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const ClassroomMessage = mongoose.model('ClassroomMessage', classroomMessageSchema);
export default ClassroomMessage;
