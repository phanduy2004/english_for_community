const { Schema, model, Types } = require('mongoose');

const ReadingSchema = new Schema(
  {
    lessonId: { type: Types.ObjectId, ref: 'Lesson', required: true },
    title: { type: String, required: true },
    content: { type: String, required: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'] },
    imageUrl: String,
  },
  { timestamps: true }
);

module.exports = model('Reading', ReadingSchema);