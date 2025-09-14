const { Schema, model, Types } = require('mongoose');

const UserPointsSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true, unique: true },
    total: { type: Number, default: 0 },
    history: [{
      amount: Number,
      reason: String,
      timestamp: { type: Date, default: Date.now }
    }]
  },
  { timestamps: true }
);

module.exports = model('UserPoints', UserPointsSchema);