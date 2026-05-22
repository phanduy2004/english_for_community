import ExamSession from '../models/ExamSession.js';
import ExamAttempt from '../models/ExamAttempt.js';
import {
  buildAttemptLiveProgressRow,
  buildLiveScreenPayloadAsync,
} from './examAttemptProgress.js';
import {
  emitExamAssignmentProgress,
  emitExamSessionEvent,
  emitExamSessionLiveScreen,
} from '../socket/examSocketEmit.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

function summarizeStudents(students) {
  const total = students.length;
  const inProgress = students.filter((s) => s.status === 'in_progress').length;
  const submitted = students.filter((s) => ['submitted', 'expired', 'void'].includes(s.status)).length;
  const flagged = students.filter((s) => s.integrityRiskLevel === 'high' || s.integrityRiskLevel === 'medium').length;
  const avgProgressPercent =
    total > 0
      ? Math.round((students.reduce((sum, s) => sum + (s.progressPercent || 0), 0) / total) * 10) / 10
      : 0;
  return { total, inProgress, submitted, flagged, avgProgressPercent };
}

export async function broadcastAttemptProgress(attemptDoc) {
  const attempt =
    attemptDoc?.populate && typeof attemptDoc.populate === 'function'
      ? await attemptDoc.populate('userId', 'fullName email username')
      : attemptDoc;
  const lean = attempt?.toObject ? attempt.toObject() : attempt;
  const screenPayload = await buildLiveScreenPayloadAsync(lean, lean.userId);
  const assignmentId = screenPayload.assignmentId;
  if (assignmentId) {
    emitExamAssignmentProgress(assignmentId, screenPayload);
  }
  if (screenPayload.sessionId) {
    emitExamSessionEvent(screenPayload.sessionId, 'exam_session_live_progress', screenPayload);
    emitExamSessionLiveScreen(screenPayload.sessionId, screenPayload);
  }
}

export async function syncLiveViewForStudent(userId, attemptId, liveViewPatch = {}) {
  const attempt = await ExamAttempt.findById(attemptId);
  if (!attempt) throw httpError(404, 'Attempt not found');
  if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
  if (attempt.status !== 'in_progress') throw httpError(400, 'Attempt is not in progress');

  const prev = attempt.meta && typeof attempt.meta === 'object' ? attempt.meta : {};
  const prevLv = prev.liveView && typeof prev.liveView === 'object' ? prev.liveView : {};
  attempt.meta = {
    ...prev,
    liveView: {
      ...prevLv,
      ...liveViewPatch,
      updatedAt: new Date().toISOString(),
    },
  };
  await attempt.save();
  await broadcastAttemptProgress(attempt);
  return attempt;
}

export async function broadcastAllSessionAttempts(sessionId) {
  const attempts = await ExamAttempt.find({ sessionId })
    .populate('userId', 'fullName email username')
    .lean();
  for (const att of attempts) {
    const payload = await buildLiveScreenPayloadAsync(att, att.userId);
    emitExamAssignmentProgress(payload.assignmentId, payload);
    emitExamSessionEvent(sessionId.toString(), 'exam_session_live_progress', payload);
    emitExamSessionLiveScreen(sessionId.toString(), payload);
  }
}

export const examLiveMonitorService = {
  async buildSnapshotForTeacher(teacherId, sessionId) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    const assignment = session.assignmentId;
    if (!assignment || assignment.teacherId.toString() !== teacherId.toString()) {
      throw httpError(403, 'Forbidden');
    }

    const attempts = await ExamAttempt.find({ sessionId: session._id })
      .populate('userId', 'fullName email username')
      .sort({ updatedAt: -1 })
      .lean();

    const students = await Promise.all(
      attempts.map((att) => buildLiveScreenPayloadAsync(att, att.userId))
    );
    return {
      sessionId: session._id.toString(),
      assignmentId: assignment._id.toString(),
      sessionStatus: session.status,
      serverNow: new Date().toISOString(),
      summary: summarizeStudents(students),
      students,
    };
  },

  async getLiveScreenForTeacher(teacherId, attemptId) {
    const attempt = await ExamAttempt.findById(attemptId)
      .populate('userId', 'fullName email username')
      .populate({
        path: 'assignmentId',
        select: 'teacherId',
      });
    if (!attempt) throw httpError(404, 'Attempt not found');
    const assignment = attempt.assignmentId;
    if (!assignment || assignment.teacherId.toString() !== teacherId.toString()) {
      throw httpError(403, 'Forbidden');
    }
    return buildLiveScreenPayloadAsync(
      attempt.toObject ? attempt.toObject() : attempt,
      attempt.userId
    );
  },
};
