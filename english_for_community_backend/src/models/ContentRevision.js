const { Schema, model, Types } = require('mongoose');

const ContentRevisionSchema = new Schema(
  {
    resourceType: { type: String, required: true },
    resourceId: { type: Types.ObjectId, required: true },
    changes: Schema.Types.Mixed,
    createdBy: { type: Types.ObjectId, ref: 'User' },
    reason: String,
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('ContentRevision', ContentRevisionSchema);