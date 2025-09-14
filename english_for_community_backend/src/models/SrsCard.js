const { Schema, model, Types } = require('mongoose');

const SrsCardSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    vocabItemId: { type: Types.ObjectId, ref: 'VocabItem', required: true },
    interval: { type: Number, default: 0 },
    ease: { type: Number, default: 2.5 },
    nextReviewDate: { type: Date, default: Date.now },
    reviewCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = model('SrsCard', SrsCardSchema);