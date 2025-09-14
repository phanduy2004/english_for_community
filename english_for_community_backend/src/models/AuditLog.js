const { Schema, model, Types } = require('mongoose');

const AuditLogSchema = new Schema(
  {
    actorId: { type: Types.ObjectId, ref: 'User' },
    action: { type: String, required: true },
    resource: String,
    meta: Schema.Types.Mixed,
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

module.exports = model('AuditLog', AuditLogSchema);