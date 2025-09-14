const { Schema, model, Types } = require('mongoose');

const StreakSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true, unique: true },
    current: { type: Number, default: 0 },
    longest: { type: Number, default: 0 },
    lastActivityDate: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = model('Streak', StreakSchema);