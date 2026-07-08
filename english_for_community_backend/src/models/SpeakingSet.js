// src/models/SpeakingSet.js
import mongoose from 'mongoose';

const SentenceSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
  },
  order: {
    type: Number,
    required: true,
  },
  speaker: {
    type: String,
    required: true,
  },
  script: {
    type: String,
    required: true,
  },
  phonetic_script: {
    type: String,
    required: false, // UI đánh dấu "Optional" → cho phép trống (trước đây required → 500 khi tạo)
    default: '',
  },
}, { _id: false }); // Không cần _id cho sub-document

const SpeakingSetSchema = new mongoose.Schema({
  // ⬇️ ĐÃ XÓA TRƯỜNG 'id' (String) KHỎI ĐÂY
  // Mongo sẽ tự động tạo '_id' (ObjectId)

  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  level: {
    type: String,
    enum: ['Beginner', 'Intermediate', 'Advanced'],
    required: true,
  },
  mode: {
    type: String,
    enum: ['readAloud', 'Shadowing', 'Pronunciation', 'FreeSpeaking'],
    required: true,
    index: true,
  },
  sentences: [SentenceSchema],
  _destroy: { type: Boolean, default: false, index: true },
  deletedAt: { type: Date, default: null },
}, { timestamps: true });

const SpeakingSet = mongoose.model('SpeakingSet', SpeakingSetSchema);

export default SpeakingSet;