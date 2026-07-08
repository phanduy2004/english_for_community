import ExamAttempt from '../models/ExamAttempt.js';
import { httpError } from '../utils/AppError.js';
import { classroomActivityService } from './classroomActivityService.js';
import { broadcastAttemptProgress } from './examLiveMonitorService.js';

const RISK_TAB_SWITCHES = 5;
const RISK_FOCUS_LOSS_SEC = 120;

function mergeIntegrity(prev = {}, patch = {}) {
  const out = { ...prev };
  if (patch.tabSwitchCount != null) {
    out.tabSwitchCount = Math.max(0, Number(patch.tabSwitchCount) || 0);
  } else if (patch.tabSwitchDelta != null) {
    out.tabSwitchCount = (Number(out.tabSwitchCount) || 0) + Math.max(0, Number(patch.tabSwitchDelta) || 0);
  }
  if (patch.focusLossSeconds != null) {
    out.focusLossSeconds = Math.max(0, Number(patch.focusLossSeconds) || 0);
  } else if (patch.focusLossDelta != null) {
    out.focusLossSeconds = (Number(out.focusLossSeconds) || 0) + Math.max(0, Number(patch.focusLossDelta) || 0);
  }
  if (patch.copyPasteAttempts != null) {
    out.copyPasteAttempts = Math.max(0, Number(patch.copyPasteAttempts) || 0);
  } else if (patch.copyPasteDelta != null) {
    out.copyPasteAttempts = (Number(out.copyPasteAttempts) || 0) + Math.max(0, Number(patch.copyPasteDelta) || 0);
  }
  if (patch.fullscreenExited != null) out.fullscreenExited = !!patch.fullscreenExited;
  if (patch.lastEventAt != null) out.lastEventAt = patch.lastEventAt;
  else out.lastEventAt = new Date().toISOString();

  const tabs = Number(out.tabSwitchCount) || 0;
  const focus = Number(out.focusLossSeconds) || 0;
  const copy = Number(out.copyPasteAttempts) || 0;
  out.riskLevel =
    tabs >= RISK_TAB_SWITCHES || focus >= RISK_FOCUS_LOSS_SEC || copy >= 3
      ? 'high'
      : tabs >= 2 || focus >= 45 || copy >= 1
        ? 'medium'
        : 'low';
  return out;
}

export const examIntegrityService = {
  async reportForStudent(userId, attemptId, patch = {}) {
    const attempt = await ExamAttempt.findById(attemptId).populate({
      path: 'assignmentId',
      select: 'classroomId teacherId audience',
    });
    if (!attempt) throw httpError(404, 'Attempt not found');
    if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
    if (attempt.status !== 'in_progress') throw httpError(400, 'Attempt is not in progress');

    const prev = attempt.integrity && typeof attempt.integrity === 'object' ? attempt.integrity : {};
    attempt.integrity = mergeIntegrity(prev, patch);
    await attempt.save();

    if (attempt.integrity.riskLevel === 'high' && attempt.assignmentId?.classroomId) {
      await classroomActivityService.log({
        classroomId: attempt.assignmentId.classroomId,
        actorId: userId,
        type: 'integrity_flag',
        message: 'High integrity risk during exam',
        meta: {
          attemptId: attempt._id.toString(),
          integrity: attempt.integrity,
        },
      });
    }
    await broadcastAttemptProgress(attempt);
    return attempt;
  },

  async summaryForAssignment(teacherId, assignmentId) {
    const { teacherExamAssignmentService } = await import('./teacherExamAssignmentService.js');
    await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);
    const attempts = await ExamAttempt.find({ assignmentId }).select('integrity status userId');
    let high = 0;
    let medium = 0;
    for (const a of attempts) {
      const r = a.integrity?.riskLevel;
      if (r === 'high') high += 1;
      else if (r === 'medium') medium += 1;
    }
    return { high, medium, total: attempts.length };
  },
};
