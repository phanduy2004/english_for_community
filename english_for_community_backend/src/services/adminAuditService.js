import AdminAuditLog from '../models/AdminAuditLog.js';

export async function writeAdminAudit({
  actorId,
  actorRole,
  action,
  targetType,
  targetId,
  metadata = {},
  ip = '',
  userAgent = '',
}) {
  if (!actorId || !action || !targetType || !targetId) return;
  try {
    await AdminAuditLog.create({
      actorId,
      actorRole: actorRole || 'unknown',
      action,
      targetType,
      targetId,
      metadata,
      ip,
      userAgent,
    });
  } catch (error) {
    console.error('Admin audit write failed:', error?.message || error);
  }
}

export async function listAdminAudits({ page = 1, limit = 20, action, targetType, actorId }) {
  const filter = {};
  if (action) filter.action = action;
  if (targetType) filter.targetType = targetType;
  if (actorId) filter.actorId = actorId;

  const p = Math.max(1, parseInt(page, 10) || 1);
  const l = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));

  const [data, total] = await Promise.all([
    AdminAuditLog.find(filter)
      .populate('actorId', 'fullName email role')
      .sort({ createdAt: -1 })
      .skip((p - 1) * l)
      .limit(l)
      .lean(),
    AdminAuditLog.countDocuments(filter),
  ]);

  return {
    data,
    pagination: {
      page: p,
      limit: l,
      total,
      totalPages: Math.ceil(total / l),
    },
  };
}
