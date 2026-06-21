import mongoose from 'mongoose';
import { toJsonIdPlugin, ttlIndexPlugin } from '../lib/mongoosePlugins.js';

const AdminAuditLogSchema = new mongoose.Schema(
  {
    actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    actorRole: { type: String, required: true },
    action: { type: String, required: true, index: true },
    targetType: { type: String, required: true, index: true },
    targetId: { type: String, required: true, index: true },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
    ip: { type: String, default: '' },
    userAgent: { type: String, default: '' },
  },
  { timestamps: true, versionKey: false }
);

AdminAuditLogSchema.index({ targetType: 1, targetId: 1, createdAt: -1 });
AdminAuditLogSchema.index({ actorId: 1, createdAt: -1 });

toJsonIdPlugin(AdminAuditLogSchema);
ttlIndexPlugin(AdminAuditLogSchema, { field: 'createdAt', expireAfterSeconds: 365 * 24 * 3600 });

const AdminAuditLog = mongoose.model('AdminAuditLog', AdminAuditLogSchema, 'admin_audit_logs');
export default AdminAuditLog;
