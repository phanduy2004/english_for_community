// src/models/Listening.js
import mongoose from 'mongoose';

const ListeningSchema = new mongoose.Schema(
  {
    lessonId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true },
    code:       { type: String, unique: true, index: true },    // ví dụ: 'p1_wakeup'
    title:      { type: String, required: true },

    audioUrl:   { type: String, required: true },               // '/assets/audio/p1_wakeup.mp3' hoặc CDN
    playbackPad:{ before: { type: Number, default: 200 }, after: { type: Number, default: 200 } },

    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    cefr:       { type: String },
    tags:       [{ type: String }],
    // tổng số cue (để hiển thị nhanh), transcript gộp (tuỳ chọn)
    totalCues:  { type: Number, default: 0 },
    transcript: { type: String },
  },
  { timestamps: true }
);

ListeningSchema.index({ lessonId: 1 });
let Listening = mongoose.model('Listening', ListeningSchema);
export default Listening;