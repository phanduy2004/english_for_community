// src/models/DictationAttempt.js


import mongoose from "mongoose";

const DictationAttemptSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', index: true },
    cueIdx: { type: Number, index: true },

    userText: { type: String },
    userTextNorm: { type: String },

    score: {
      wer: { type: Number },          // 0..1
      cer: { type: Number },          // 0..1 (tuỳ dùng)
      correctWords: { type: Number },
      totalWords: { type: Number },
    },

    playedMs: { type: Number },       // tổng ms đã nghe (tuỳ chọn)
    submittedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

DictationAttemptSchema.index({ userId: 1, listeningId: 1, cueIdx: 1 }, { unique: true });
let  DictationAttempt = mongoose.model('DictationAttemptSchema', DictationAttemptSchema)
export default DictationAttempt;
