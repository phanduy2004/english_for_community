/**
 * RBAC Permission constants — single source of truth.
 *
 * ROLES (simple):
 *   user  — normal learner, no admin access
 *   admin — full access to admin console + all management features
 *
 * The Permission enum is kept so routes are type-safe and future-proof
 * (e.g. if you add a "moderator" role later, just add a new entry to ROLE_PERMISSIONS).
 */

export const Permission = Object.freeze({
  WILDCARD: '*',

  REPORTS_READ: 'reports.read',
  REPORTS_UPDATE: 'reports.update',
  REPORTS_BULK_UPDATE: 'reports.bulk_update',

  MODERATION_QUEUE_READ: 'moderation.queue.read',

  USERS_READ: 'users.read',
  USERS_RESTORE: 'users.restore',

  EXPORTS_READ: 'exports.read',

  CONTENT_READ: 'content.read',
  CONTENT_UPDATE: 'content.update',
  CONTENT_VERSION_READ: 'content.version.read',
  CONTENT_VERSION_ROLLBACK: 'content.version.rollback',
  CONTENT_APPROVE: 'content.approve',
});

export const ALL_KNOWN_PERMISSIONS = Object.freeze(
  Object.values(Permission).filter((p) => p !== Permission.WILDCARD)
);

export const VALID_ROLES = Object.freeze(['user', 'admin']);

/**
 * Default permission grants per role.
 *   admin → wildcard (all routes)
 *   user  → empty (no admin routes)
 */
export const ROLE_PERMISSIONS = Object.freeze({
  admin: [Permission.WILDCARD],
  user: [],
});
