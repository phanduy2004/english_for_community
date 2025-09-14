const { Schema, model, Types } = require('mongoose');

const ScheduledNotificationSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    scheduledFor: { type: Date, required: true },
    sent: { type: Boolean, default: false },
    sentAt: Date,
    data: Schema.Types.Mixed,
  },
  { timestamps: true }
);

module.exports = model('ScheduledNotification', ScheduledNotificationSchema);