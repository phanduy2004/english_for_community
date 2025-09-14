const { Schema, model, Types } = require('mongoose');

const UnitSchema = new Schema(
  {
    trackId: { type: Types.ObjectId, ref: 'Track', required: true },
    name: { type: String, required: true },
    description: String,
    order: { type: Number, default: 0 },
    imageUrl: String,
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = model('Unit', UnitSchema);