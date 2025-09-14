const { Schema, model, Types } = require('mongoose');

const TutorMessageSchema = new Schema(
  {
    conversationId: { type: Types.ObjectId, ref: 'TutorConversation', required: true },
    senderId: { type: Types.ObjectId, ref: 'User', required: true },
    content: { type: String, required: true },
    attachments: [{ type: String }],
    isRead: { type: Boolean, default: false },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('TutorMessage', TutorMessageSchema);