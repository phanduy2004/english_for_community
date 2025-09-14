const { Schema, model, Types } = require('mongoose');

const VocabSetSchema = new Schema(
  {
    lessonId: { type: Types.ObjectId, ref: 'Lesson' },
    name: { type: String, required: true },
    description: String,
    level: { type: String, enum: ['beginner', 'intermediate', 'advanced'] },
  },
  { timestamps: true }
);

module.exports = model('VocabSet', VocabSetSchema);