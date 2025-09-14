const { Schema, model, Types } = require('mongoose');

const SrsReviewSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    cardId: { type: Types.ObjectId, ref: 'SrsCard', required: true },
    quality: { type: Number, min: 0, max: 5 },
    timeTaken: Number,
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('SrsReview', SrsReviewSchema);