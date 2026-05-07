export const ReleaseStatus = Object.freeze({
  pendingApproval: 'pending_approval',
  approved: 'approved',
  scheduled: 'scheduled',
  published: 'published',
  rejected: 'rejected',
  archived: 'archived',
});

const transitionMap = Object.freeze({
  [ReleaseStatus.pendingApproval]: [ReleaseStatus.approved, ReleaseStatus.rejected],
  [ReleaseStatus.approved]: [ReleaseStatus.scheduled, ReleaseStatus.published, ReleaseStatus.rejected],
  [ReleaseStatus.scheduled]: [ReleaseStatus.published, ReleaseStatus.rejected],
  [ReleaseStatus.published]: [ReleaseStatus.archived],
  [ReleaseStatus.rejected]: [],
  [ReleaseStatus.archived]: [],
});

export function canTransition(fromStatus, toStatus) {
  const allowed = transitionMap[fromStatus] || [];
  return allowed.includes(toStatus);
}

export function assertTransition(fromStatus, toStatus) {
  if (!canTransition(fromStatus, toStatus)) {
    const error = new Error(`Invalid transition from status: ${fromStatus} -> ${toStatus}`);
    error.statusCode = 400;
    throw error;
  }
}
