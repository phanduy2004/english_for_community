import { getIO } from './socketManager.js';

export function emitExamSessionEvent(sessionId, event, payload) {
  try {
    const io = getIO();
    io.to(`examSession_${sessionId}`).emit(event, payload);
  } catch {
    // Socket not initialized (tests)
  }
}

export function emitExamAssignmentProgress(assignmentId, payload) {
  try {
    const io = getIO();
    io.to(`examAssignment_${assignmentId}`).emit('exam_assignment_progress', payload);
  } catch {
    /* optional */
  }
}

export function emitExamSessionLiveScreen(sessionId, payload) {
  try {
    const io = getIO();
    io.to(`examSession_${sessionId}`).emit('exam_session_live_screen', payload);
  } catch {
    /* optional */
  }
}
