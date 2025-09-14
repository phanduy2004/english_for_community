const { Schema, model, Types } = require('mongoose');

const SpeakingAttemptSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    lessonId: { type: Types.ObjectId, ref: 'Lesson', required: true },
    audioUrl: { type: String, required: true },
    transcript: String,
    feedback: String,
    score: Number,
    reviewedBy: { type: Types.ObjectId, ref: 'User' },
    reviewedAt: Date,
  },
  { timestamps: true }
);

module.exports = model('SpeakingAttempt', SpeakingAttemptSchema);