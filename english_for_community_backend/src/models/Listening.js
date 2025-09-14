const { Schema, model, Types } = require('mongoose');

const ListeningSchema = new Schema(
  {
    lessonId: { type: Types.ObjectId, ref: 'Lesson', required: true },
    title: { type: String, required: true },
    audioUrl: { type: String, required: true },
    transcript: { type: String, required: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'] },
  },
  { timestamps: true }
);

module.exports = model('Listening', ListeningSchema);