// src/models/SpeakingAttempt.js
import mongoose from "mongoose";

const SpeakingAttemptSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    speakingSetId: { type: String, ref: 'SpeakingSet', index: true },
    sentenceId: { type: String, index: true },

    // Dùng để lưu kết quả của Bước 4 (Google STT)
    userTranscript: { type: String }, // "Hello how are you doing"

    // Dùng để lưu file thu âm của Bước 3
    userAudioUrl: { type: String }, // Link tới file S3/Firebase Storage
    audioDurationSeconds: { type: Number, default: 0, min: 0 }, // <-- ĐÃ THÊM
    // Dùng để lưu kết quả của Bước 5 (So sánh)
    score: {
      wer: { type: Number }, // Word Error Rate
      confidence: { type: Number }, // Độ tự tin của STT
    },

    submittedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const SpeakingAttempt = mongoose.model('SpeakingAttempt', SpeakingAttemptSchema);
export default SpeakingAttempt;