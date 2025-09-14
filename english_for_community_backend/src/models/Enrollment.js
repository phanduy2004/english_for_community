const { Schema, model, Types } = require('mongoose');

const EnrollmentSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    trackId: { type: Types.ObjectId, ref: 'Track', required: true },
    progress: { type: Number, default: 0 },
    lastAccessedAt: { type: Date, default: Date.now },
    isCompleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = model('Enrollment', EnrollmentSchema);