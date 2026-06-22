import mongoose from 'mongoose';
import { toJsonIdPlugin, softDeletePlugin } from '../lib/mongoosePlugins.js';

const examSessionSchema = new mongoose.Schema(
  {
    assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamAssignment', required: true, index: true },
    leaderTeacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  /** Resolved at runtime from ExamAssignment.examSnapshot (D4 contract — not stored per session). */
    examSnapshot: { type: mongoose.Schema.Types.Mixed, default: null },
    status: {
      type: String,
      enum: ['lobby', 'live', 'grading', 'closed', 'canceled'],
      default: 'lobby',
      index: true,
    },
    roomCode: { type: String, default: '' },
    joinedUserIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    /** Students who toggled "ready" in lobby (realtime). */
    readyUserIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    startedAt: { type: Date, default: null },
    endedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

examSessionSchema.index({ assignmentId: 1, status: 1 });

toJsonIdPlugin(examSessionSchema);
softDeletePlugin(examSessionSchema, { useDestroyFlag: false });

examSessionSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const ExamSession = mongoose.model('ExamSession', examSessionSchema);
export default ExamSession;
