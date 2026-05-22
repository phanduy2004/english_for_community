import mongoose from 'mongoose';

const reviewSchema = new mongoose.Schema(
  {
    reviewerAdminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    decisionAt: { type: Date, default: null },
    reason: { type: String, default: '' },
  },
  { _id: false }
);

const payloadSchema = new mongoose.Schema(
  {
    bio: { type: String, default: '' },
    organization: { type: String, default: '' },
    subjects: [{ type: String }],
    proofUrls: [{ type: String }],
  },
  { _id: false }
);

const teacherApplicationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'withdrawn'],
      default: 'pending',
      index: true,
    },
    payload: { type: payloadSchema, default: () => ({}) },
    review: { type: reviewSchema, default: () => ({}) },
  },
  { timestamps: true }
);

teacherApplicationSchema.index({ userId: 1, status: 1 });

teacherApplicationSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const TeacherApplication = mongoose.model('TeacherApplication', teacherApplicationSchema);
export default TeacherApplication;
