const { Schema, model, Types } = require('mongoose');

const UserBadgeSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    badgeId: { type: Types.ObjectId, ref: 'Badge', required: true },
    awardedAt: { type: Date, default: Date.now },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('UserBadge', UserBadgeSchema);