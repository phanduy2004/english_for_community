// src/models/Lesson.js

import mongoose from "mongoose";

const LessonSchema = new mongoose.Schema(
  {
    unitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Unit', required: true },
    name: { type: String, required: true },
    description: String,
    order: { type: Number, default: 0 },
    type: { type: String, enum: ['vocabulary', 'grammar', 'reading', 'listening', 'speaking', 'writing'] },
    content: mongoose.Schema.Types.Mixed,     // { listeningCode: '...' } cho listening
    imageUrl: String,
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);
let Lesson = mongoose.model('Lesson', LessonSchema);
export default Lesson;
