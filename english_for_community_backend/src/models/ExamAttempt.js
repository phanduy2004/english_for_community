import mongoose from 'mongoose';

const examAttemptSchema = new mongoose.Schema(
  {
    assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamAssignment', required: true, index: true },
    sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamSession', default: null, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    examSnapshot: { type: mongoose.Schema.Types.Mixed, required: true },
    status: { type: String, enum: ['in_progress', 'submitted', 'expired', 'void'], default: 'in_progress' },
    startedAt: { type: Date, default: Date.now },
    submittedAt: { type: Date, default: null },
    attemptDeadlineAt: { type: Date, default: null },
    meta: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    answers: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    gradingState: {
      type: String,
      enum: ['pending_auto', 'pending_ai', 'pending_manual', 'finalized'],
      default: 'pending_auto',
    },
    scores: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    resultsReleased: { type: Boolean, default: false },
    integrity: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
  },
  { timestamps: true }
);

examAttemptSchema.index({ assignmentId: 1, userId: 1, status: 1 });

examAttemptSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const ExamAttempt = mongoose.model('ExamAttempt', examAttemptSchema);
export default ExamAttempt;
