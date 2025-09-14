const { Schema, model } = require('mongoose');

const TrackSchema = new Schema(
  {
    name: { type: String, required: true },
    description: String,
    level: { type: String, enum: ['beginner', 'intermediate', 'advanced'] },
    imageUrl: String,
    order: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = model('Track', TrackSchema);