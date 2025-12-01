import mongoose from 'mongoose';

const { Schema, model, Types } = mongoose;

// Schema con lưu chi tiết TỪNG câu trả lời
const AnswerSubSchema = new Schema({
  questionId: { type: Types.ObjectId, required: true },
  chosenIndex: { type: Number, required: true },
  isCorrect: { type: Boolean, required: true }
}, { _id: false });

const ReadingAttemptSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true, index: true },
    readingId: { type: Types.ObjectId, ref: 'Reading', required: true, index: true },
    answers: [AnswerSubSchema],
    score: { type: Number, required: true },
    correctCount: { type: Number, required: true },
    totalQuestions: { type: Number, required: true },
    durationInSeconds: { type: Number, default: 0, min: 0 } // <-- ĐÃ THÊM
  },
  {
    timestamps: true
  }
);

// ✍️ Sử dụng export default
const ReadingAttempt = model('ReadingAttempt', ReadingAttemptSchema);
export default ReadingAttempt;