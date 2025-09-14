const { Schema, model, Types } = require('mongoose');

const QuizQuestionSchema = new Schema(
  {
    lessonId: { type: Types.ObjectId, ref: 'Lesson', required: true },
    question: { type: String, required: true },
    type: { type: String, enum: ['multiple-choice', 'true-false', 'fill-in-blank'], default: 'multiple-choice' },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'] },
    explanation: String,
  },
  { timestamps: true }
);

module.exports = model('QuizQuestion', QuizQuestionSchema);