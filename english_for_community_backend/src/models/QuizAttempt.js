const { Schema, model, Types } = require('mongoose');

const QuizAttemptSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    questionId: { type: Types.ObjectId, ref: 'QuizQuestion', required: true },
    selectedOptionId: { type: Types.ObjectId, ref: 'QuizOption' },
    isCorrect: { type: Boolean, required: true },
    timeTaken: Number,
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('QuizAttempt', QuizAttemptSchema);