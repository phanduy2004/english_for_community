const { Schema, model, Types } = require('mongoose');

const LessonSchema = new Schema(
  {
    unitId: { type: Types.ObjectId, ref: 'Unit', required: true },
    name: { type: String, required: true },
    description: String,
    order: { type: Number, default: 0 },
    type: { type: String, enum: ['vocabulary', 'grammar', 'reading', 'listening', 'speaking', 'writing'] },
    content: Schema.Types.Mixed,
    imageUrl: String,
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = model('Lesson', LessonSchema);