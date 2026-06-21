import mongoose from 'mongoose';
import { toJsonIdPlugin, softDeletePlugin } from '../lib/mongoosePlugins.js';

const examAssignmentSchema = new mongoose.Schema(
  {
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true, index: true },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    audience: { type: String, enum: ['classroom', 'public_link'], required: true },
    classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', default: null, index: true },
    mode: {
      type: String,
      enum: ['self_paced', 'scheduled', 'realtime', 'practice'],
      required: true,
    },
    config: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
    publicJoin: {
      type: new mongoose.Schema(
        {
          token: { type: String, sparse: true },
          maxUses: { type: Number, default: null },
          expiresAt: { type: Date, default: null },
          usesCount: { type: Number, default: 0 },
        },
        { _id: false }
      ),
      default: null,
    },
    status: { type: String, enum: ['active', 'closed'], default: 'active' },
    /** D4: frozen exam copy once per assignment (dedup storage). */
    examSnapshot: { type: mongoose.Schema.Types.Mixed, default: null },
    examSnapshotFrozenAt: { type: Date, default: null },
  },
  { timestamps: true }
);

examAssignmentSchema.index({ teacherId: 1, updatedAt: -1 });
examAssignmentSchema.index({ 'publicJoin.token': 1 }, { sparse: true });
// P0-B3: classroom assignment list/filter (see doc 21 §3C).
examAssignmentSchema.index({ classroomId: 1, audience: 1, status: 1 });

toJsonIdPlugin(examAssignmentSchema);
softDeletePlugin(examAssignmentSchema, { useDestroyFlag: false });

examAssignmentSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    delete ret.examSnapshot;
    delete ret.examSnapshotFrozenAt;
    return ret;
  },
});

const ExamAssignment = mongoose.model('ExamAssignment', examAssignmentSchema);
export default ExamAssignment;
