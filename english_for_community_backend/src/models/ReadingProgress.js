import mongoose from 'mongoose';

const { Schema, model, Types } = mongoose;

const ReadingProgressSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    readingId: { type: Types.ObjectId, ref: 'Reading', required: true },
    status: {
      type: String,
      enum: ['not_started', 'in_progress', 'completed'],
      default: 'not_started'
    },
    highScore: { type: Number, default: 0 },
    attemptsCount: { type: Number, default: 0 },
    lastAttemptedAt: { type: Date }
  },
  {
    timestamps: true
  }
);

ReadingProgressSchema.index({ userId: 1, readingId: 1 }, { unique: true });

// ✍️ Sử dụng export default
const ReadingProgress = model('ReadingProgress', ReadingProgressSchema);
export default ReadingProgress;