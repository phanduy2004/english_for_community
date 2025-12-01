import mongoose from 'mongoose';

const UserDailyProgressSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: String, required: true }, // Format: "YYYY-MM-DD"

  studySeconds: { type: Number, default: 0 },
  vocabLearned: { type: Number, default: 0 },

  lessonsCompleted: {
    listening: { type: Number, default: 0 },
    reading: { type: Number, default: 0 },
    speaking: { type: Number, default: 0 },
    writing: { type: Number, default: 0 },
  },

  stats: {
    readingAccuracy: { total: { type: Number, default: 0 }, count: { type: Number, default: 0 } },
    dictationAccuracy: { total: { type: Number, default: 0 }, count: { type: Number, default: 0 } }, // Lưu 1 - WER
    speakingScore: { total: { type: Number, default: 0 }, count: { type: Number, default: 0 } },     // Lưu 1 - WER
    writingScore: { total: { type: Number, default: 0 }, count: { type: Number, default: 0 } },
    readingWpm: { total: { type: Number, default: 0 }, count: { type: Number, default: 0 } },
  }
}, { timestamps: true });

// Index quan trọng để query nhanh
UserDailyProgressSchema.index({ userId: 1, date: 1 }, { unique: true });

const UserDailyProgress = mongoose.model('UserDailyProgress', UserDailyProgressSchema);
export default UserDailyProgress;