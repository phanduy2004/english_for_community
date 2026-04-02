import mongoose from 'mongoose';

const AnswerPayloadSubSchema = new mongoose.Schema({
  questionId: { type: mongoose.Schema.Types.ObjectId, required: true },
  chosenIndex: { type: Number, required: true }, // -1 nếu không chọn
  isCorrect: { type: Boolean, required: true }
}, { _id: false });

const ListeningCompAttemptSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'ListeningComprehension', required: true },

    answers: [AnswerPayloadSubSchema],

    score: { type: Number, default: 0 }, // Theo % (0 - 100)
    correctCount: { type: Number, default: 0 },
    totalQuestions: { type: Number, default: 0 },

    durationInSeconds: { type: Number, default: 0 }, // Thời gian làm bài
  },
  { timestamps: true }
);

// ⭐️ Index CỰC KỲ QUAN TRỌNG khi bỏ bảng Progress ⭐️
// Giúp backend lấy ra điểm cao nhất hoặc check xem user đã làm bài chưa cực nhanh
// Cú pháp query sau này sẽ là: find({ userId, listeningId }).sort({ score: -1 }).limit(1)
ListeningCompAttemptSchema.index({ userId: 1, listeningId: 1, score: -1 });

const ListeningCompAttempt = mongoose.model('ListeningCompAttempt', ListeningCompAttemptSchema);
export default ListeningCompAttempt;