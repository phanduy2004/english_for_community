import mongoose from 'mongoose';

const classroomActivityLogSchema = new mongoose.Schema(
  {
    classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
    actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    type: {
      type: String,
      enum: [
        'member_joined',
        'member_pending',
        'member_approved',
        'member_removed',
        'co_teacher_added',
        'co_teacher_removed',
        'assignment_created',
        'assignment_closed',
        'attempt_submitted',
        'results_released',
        'integrity_flag',
      ],
      required: true,
    },
    message: { type: String, default: '' },
    meta: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
  },
  { timestamps: true }
);

classroomActivityLogSchema.index({ classroomId: 1, createdAt: -1 });

classroomActivityLogSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const ClassroomActivityLog = mongoose.model('ClassroomActivityLog', classroomActivityLogSchema);
export default ClassroomActivityLog;
