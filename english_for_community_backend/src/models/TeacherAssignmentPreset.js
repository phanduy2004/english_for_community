import mongoose from 'mongoose';

const teacherAssignmentPresetSchema = new mongoose.Schema(
  {
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true, maxlength: 120 },
    config: {
      mode: { type: String, enum: ['self_paced', 'scheduled', 'realtime'], default: 'self_paced' },
      attemptPolicy: { type: String, enum: ['single', 'unlimited', 'limited'], default: 'single' },
      maxAttempts: { type: Number, min: 2, max: 99 },
      showResultsPolicy: {
        type: String,
        enum: ['after_submit', 'after_release', 'never'],
        default: 'after_release',
      },
      allowPartialSubmit: { type: Boolean, default: true },
      timeLimitSeconds: { type: Number, min: 0, default: null },
    },
  },
  { timestamps: true }
);

teacherAssignmentPresetSchema.index({ teacherId: 1, updatedAt: -1 });

const TeacherAssignmentPreset = mongoose.model('TeacherAssignmentPreset', teacherAssignmentPresetSchema);
export default TeacherAssignmentPreset;
