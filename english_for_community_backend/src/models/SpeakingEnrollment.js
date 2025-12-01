// src/models/SpeakingEnrollment.js
import mongoose from 'mongoose';

const SpeakingEnrollmentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  speakingSetId: { type: String, ref: 'SpeakingSet', required: true },

  // Lưu 'id' (String) của các câu đã hoàn thành
  completedSentenceIds: [{ type: String }],

  progress: { type: Number, default: 0 }, // 0..1
  averageWer: { type: Number }, // Điểm WER trung bình
  lastAccessedAt: { type: Date, default: Date.now },
  isCompleted: { type: Boolean, default: false },
}, { timestamps: true });

SpeakingEnrollmentSchema.index({ userId: 1, speakingSetId: 1 }, { unique: true });

const SpeakingEnrollment = mongoose.model('SpeakingEnrollment', SpeakingEnrollmentSchema);
export default SpeakingEnrollment;