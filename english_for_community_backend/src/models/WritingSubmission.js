// src/models/WritingSubmission.js
import mongoose from 'mongoose';

const { Schema, Types } = mongoose;

const FeedbackSchema = new Schema({
  overall: Number, tr: Number, cc: Number, lr: Number, gra: Number,
  trBullets: [String], ccBullets: [String], lrBullets: [String], graBullets: [String],
  trNote: String, ccNote: String, lrNote: String, graNote: String,
  paragraphs: [{ title: String, comment: String, rewrite: String }],
  taskType: String, keyTips: [String], outline: [String],
  vocab: [{ word: String, type: String, def: String }],
  grammarRows: [{ structure: String, original: String, rephrased: String }],
  coherenceRows: [{ original: String, improved: String, explain: String }],
  sampleMid: String, sampleHigh: String,
  modelInfo: { provider: String, model: String },
  evaluatedAt: { type: Date, default: Date.now },
}, { _id: false });

const WritingSubmissionSchema = new Schema({
  userId:  { type: Types.ObjectId, ref: 'User', required: true, index: true },
  topicId: { type: Types.ObjectId, ref: 'WritingTopic', required: true, index: true },

  // ĐỀ ĐƯỢC SINH BỞI AI (snapshot để hiển thị & lưu vết)
  generatedPrompt: {
    title:   String,   // "Art Exhibitions Debate"
    text:    String,   // đề bài đầy đủ (Task 2)
    taskType:String,   // dạng đề
    level:   String,   // Beginner/Intermediate/Advanced (nếu dùng)
  },

  // BÀI LÀM
  content:   { type: String, default: '' },
  wordCount: Number,

  // TRẠNG THÁI
  status:      { type: String, enum: ['draft','submitted','reviewed'], default: 'draft' },
  startedAt:   { type: Date, default: Date.now },
  submittedAt: Date,

  // KẾT QUẢ CHẤM
  feedback:   FeedbackSchema,
  score:      Number,     // = feedback.overall (để query nhanh)
  reviewedAt: Date,
}, {
  timestamps: true,
  versionKey: false
});

WritingSubmissionSchema.index({ userId: 1, topicId: 1, createdAt: -1 });

const WritingSubmission = mongoose.model('WritingSubmission', WritingSubmissionSchema, 'writing_submissions');
export default WritingSubmission;
