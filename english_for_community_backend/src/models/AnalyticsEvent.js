const { Schema, model, Types } = require('mongoose');

const AnalyticsEventSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User' },
    name: { type: String, required: true }, // app_open, lesson_start, srs_review, quiz_answered
    props: Schema.Types.Mixed,
    occurredAt: { type: Date, default: Date.now, index: true },
  },
  { timestamps: false }
);

AnalyticsEventSchema.index({ userId: 1, occurredAt: -1 });
module.exports = model('AnalyticsEvent', AnalyticsEventSchema);