/** Realtime assignment schedule: manual (in-class) vs fixed calendar times. */

export function resolveRealtimeScheduleMode(cfg = {}) {
  if (cfg.realtimeScheduleMode === 'manual' || cfg.realtimeScheduleMode === 'scheduled') {
    return cfg.realtimeScheduleMode;
  }
  return cfg.scheduledStartAt ? 'scheduled' : 'manual';
}

function parseMs(raw) {
  if (!raw) return null;
  const t = new Date(raw).getTime();
  return Number.isFinite(t) ? t : null;
}

/** When students may enter the lobby (optional early open before scheduled start). */
export function realtimeLobbyOpensAtMs(cfg = {}) {
  return parseMs(cfg.lobbyOpensAt) ?? parseMs(cfg.scheduledStartAt);
}

export function realtimeScheduledStartAtMs(cfg = {}) {
  return parseMs(cfg.scheduledStartAt);
}

/** Before lobby open time — students should not join yet. */
export function isRealtimeLobbyClosedForStudent(assignment) {
  if (assignment?.mode !== 'realtime') return false;
  if (resolveRealtimeScheduleMode(assignment.config || {}) !== 'scheduled') return false;
  const openMs = realtimeLobbyOpensAtMs(assignment.config || {});
  if (openMs == null) return false;
  return Date.now() < openMs;
}

export function assertRealtimeLobbyOpenForStudent(assignment) {
  if (isRealtimeLobbyClosedForStudent(assignment)) {
    const e = new Error('The exam lobby is not open yet');
    e.statusCode = 403;
    throw e;
  }
}
