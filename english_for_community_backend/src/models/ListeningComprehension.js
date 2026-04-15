import mongoose from 'mongoose';
const { Schema, model, Types } = mongoose;

const FeedbackSubSchema = new Schema({
  reasoning: { type: String, required: true },
  hintTimestampSeconds: { type: Number }, // Nhảy đến đúng số giây chứa đáp án
  keySentence: { type: String }
}, { _id: false });

const QuestionSubSchema = new Schema({
  _id: { type: Types.ObjectId, auto: true },
  questionText: { type: String, required: true },
  options: [{ type: String, required: true }],
  correctAnswerIndex: { type: Number, required: true },
  feedback: { type: FeedbackSubSchema }
});

const ListeningComprehensionSchema = new Schema(
  {
    title: { type: String, required: true },
    summary: { type: String },

    audioUrl: { type: String, required: true },
    transcript: { type: String, required: true },

    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    imageUrl: { type: String },
    minutesToComplete: { type: Number, default: 5 },

    questions: [QuestionSubSchema],
    _destroy: { type: Boolean, default: false, index: true },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

ListeningComprehensionSchema.virtual('totalQuestions').get(function() {
  return this.questions ? this.questions.length : 0;
});

ListeningComprehensionSchema.set('toJSON', { virtuals: true });
ListeningComprehensionSchema.set('toObject', { virtuals: true });

const ListeningComprehension = model('ListeningComprehension', ListeningComprehensionSchema);
export default ListeningComprehension;