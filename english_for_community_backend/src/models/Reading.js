import mongoose from 'mongoose';
const { Schema, model, Types } = mongoose;

const QuestionTranslationSubSchema = new Schema({
  questionText: { type: String, required: true },
  options: [String]
}, { _id: false });

const TranslationSubSchema = new Schema({
  title: { type: String, required: true },
  content: { type: String, required: true }
}, { _id: false });

const FeedbackSubSchema = new Schema({
  reasoning: { type: String, required: true },
  paragraphIndex: { type: Number },
  keySentence: { type: String }
}, { _id: false });

const QuestionSubSchema = new Schema({
  _id: { type: Types.ObjectId, auto: true },
  questionText: { type: String, required: true },
  options: [String],
  correctAnswerIndex: { type: Number, required: true },
  feedback: { type: FeedbackSubSchema },
  translation: { type: QuestionTranslationSubSchema } // 👈 3. THÊM VÀO QUESTION
});

const ReadingSchema = new Schema(
  {
    title: { type: String, required: true },
    summary: { type: String, required: true },
    content: { type: String, required: true },
    translation: { type: TranslationSubSchema }, // 👈 4. THÊM VÀO BÀI ĐỌC
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    imageUrl: String,
    minutesToRead: { type: Number, default: 5 },
    questions: [QuestionSubSchema]
  },
  { timestamps: true }
);

const Reading = model('Reading', ReadingSchema);
export default Reading;