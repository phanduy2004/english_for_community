const { Schema, model, Types } = require('mongoose');

const QuizOptionSchema = new Schema(
  {
    questionId: { type: Types.ObjectId, ref: 'QuizQuestion', required: true },
    text: { type: String, required: true },
    isCorrect: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = model('QuizOption', QuizOptionSchema);