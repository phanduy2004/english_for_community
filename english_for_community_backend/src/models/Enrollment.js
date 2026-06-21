import mongoose from 'mongoose';
import { toJsonIdPlugin } from '../lib/mongoosePlugins.js';

const EnrollmentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', required: true },
  completedCueIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cue' }],
  progress: { type: Number, default: 0 },          // 0..1
  lastAccessedAt: { type: Date, default: Date.now },
  isCompleted: { type: Boolean, default: false },
}, { timestamps: true });

EnrollmentSchema.index({ userId: 1, listeningId: 1 }, { unique: true });
EnrollmentSchema.index({ userId: 1, isCompleted: 1, updatedAt: -1 });
EnrollmentSchema.index({ userId: 1, lastAccessedAt: -1 });
EnrollmentSchema.index({ updatedAt: -1 });

toJsonIdPlugin(EnrollmentSchema);

let Enrollment = mongoose.model('Enrollment', EnrollmentSchema);
export default Enrollment;