/**
 * RBAC Permission constants — single source of truth.
 *
 * ROLES:
 *   user    — learner (default at registration)
 *   teacher — classroom + exam authoring (see ROLE_PERMISSIONS)
 *   admin   — full access (wildcard)
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

  TEACHER_CLASSROOM_MANAGE: 'teacher.classroom.manage',
  TEACHER_CLASSROOM_MEMBERS_MANAGE: 'teacher.classroom.members.manage',
  TEACHER_EXAM_MANAGE: 'teacher.exam.manage',
  TEACHER_EXAM_SESSION_RUN: 'teacher.exam.session.run',
  TEACHER_EXAM_ASSIGN: 'teacher.exam.assign',
  TEACHER_GRADING_READ: 'teacher.grading.read',
  TEACHER_GRADING_WRITE: 'teacher.grading.write',

});

export const ALL_KNOWN_PERMISSIONS = Object.freeze(
  Object.values(Permission).filter((p) => p !== Permission.WILDCARD)
);

export const VALID_ROLES = Object.freeze(['user', 'admin', 'teacher']);

/**
 * Default permission grants per role.
 *   admin → wildcard (all routes)
 *   user  → empty (no admin routes)
 */
export const ROLE_PERMISSIONS = Object.freeze({
  admin: [Permission.WILDCARD],
  user: [],
  teacher: [
    Permission.TEACHER_CLASSROOM_MANAGE,
    Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE,
    Permission.TEACHER_EXAM_MANAGE,
    Permission.TEACHER_EXAM_SESSION_RUN,
    Permission.TEACHER_EXAM_ASSIGN,
    Permission.TEACHER_GRADING_READ,
    Permission.TEACHER_GRADING_WRITE,
  ],
});
