import mongoose from 'mongoose';
import { toJsonIdPlugin, softDeletePlugin } from '../lib/mongoosePlugins.js';

const examSchema = new mongoose.Schema(
  {
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    status: { type: String, enum: ['draft', 'published', 'archived'], default: 'draft', index: true },
    contentVersion: { type: Number, default: 1 },
    sections: { type: [mongoose.Schema.Types.Mixed], default: [] },
    settings: { type: mongoose.Schema.Types.Mixed, default: () => ({}) },
  },
  { timestamps: true }
);

examSchema.index({ teacherId: 1, status: 1, updatedAt: -1 });

toJsonIdPlugin(examSchema);
softDeletePlugin(examSchema, { useDestroyFlag: false });

examSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const Exam = mongoose.model('Exam', examSchema);
export default Exam;
