import mongoose from 'mongoose';

const classroomMemberSchema = new mongoose.Schema(
  {
    classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    roleInClass: { type: String, enum: ['student', 'co_teacher'], default: 'student' },
    status: { type: String, enum: ['active', 'pending', 'removed'], default: 'active', index: true },
    joinedAt: { type: Date, default: Date.now },
    leftAt: { type: Date, default: null },
  },
  { timestamps: true }
);

classroomMemberSchema.index({ classroomId: 1, userId: 1 }, { unique: true });

classroomMemberSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const ClassroomMember = mongoose.model('ClassroomMember', classroomMemberSchema);
export default ClassroomMember;
