import mongoose from 'mongoose';

const EnrollmentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', required: true },
  completedCueIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Cue' }],
  progress: { type: Number, default: 0 },          // 0..1
  lastAccessedAt: { type: Date, default: Date.now },
  isCompleted: { type: Boolean, default: false },
}, { timestamps: true });
let Enrollment = mongoose.model('Enrollment', EnrollmentSchema);
export default Enrollment;