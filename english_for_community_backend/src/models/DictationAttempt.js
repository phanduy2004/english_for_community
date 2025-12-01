// src/models/DictationAttempt.js
import mongoose from "mongoose";

const DictationAttemptSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', index: true },
    cueIdx: { type: Number, index: true },

    userText: { type: String },
    userTextNorm: { type: String },

    // ⭐️ BẮT ĐẦU SỬA Ở ĐÂY ⭐️
    score: {
      wer: { type: Number },
      cer: { type: Number },
      correctWords: { type: Number },
      totalWords: { type: Number },
      // Thêm 2 trường mà controller (File 3) đang lưu
      passed: { type: Boolean, default: false },
      thresholdWer: { type: Number },
    },
    // ⭐️ KẾT THÚC SỬA ⭐️
    attemptsCount: { type: Number, default: 0 },
    durationInSeconds: { type: Number, default: 0, min: 0 },
    playedMs: { type: Number },
    submittedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

DictationAttemptSchema.index({ userId: 1, listeningId: 1, cueIdx: 1 }, { unique: true });
const DictationAttempt = mongoose.model('DictationAttempt', DictationAttemptSchema);
export default DictationAttempt;