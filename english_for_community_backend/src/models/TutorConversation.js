const { Schema, model, Types } = require('mongoose');

const TutorConversationSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    tutorId: { type: Types.ObjectId, ref: 'User' },
    topic: String,
    status: { type: String, enum: ['active', 'closed'], default: 'active' },
    lastMessageAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = model('TutorConversation', TutorConversationSchema);