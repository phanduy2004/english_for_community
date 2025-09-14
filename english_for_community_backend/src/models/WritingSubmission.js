const { Schema, model, Types } = require('mongoose');

const WritingSubmissionSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    lessonId: { type: Types.ObjectId, ref: 'Lesson', required: true },
    content: { type: String, required: true },
    feedback: String,
    score: Number,
    reviewedBy: { type: Types.ObjectId, ref: 'User' },
    reviewedAt: Date,
  },
  { timestamps: true }
);

module.exports = model('WritingSubmission', WritingSubmissionSchema);