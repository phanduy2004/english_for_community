import { z } from 'zod';
import ExamAttempt from '../models/ExamAttempt.js';
import { httpError } from '../utils/AppError.js';
import { classroomActivityService } from './classroomActivityService.js';
import { broadcastAttemptProgress } from './examLiveMonitorService.js';

const RISK_TAB_SWITCHES = 5;
const RISK_FOCUS_LOSS_SEC = 120;

// Trần trên per-request để chống spam số khổng lồ (A1/A8). Delta/absolute đều clamp.
const MAX_DELTA = 1000;
const MAX_FOCUS_DELTA = 3600; // 1h/lần report là dư

// Zod: chấp nhận delta HOẶC absolute; số không âm, có trần. Field lạ bị strip. (A1/A8)
const integrityPatchSchema = z
  .object({
    tabSwitchDelta: z.number().int().min(0).max(MAX_DELTA).optional(),
    focusLossDelta: z.number().int().min(0).max(MAX_FOCUS_DELTA).optional(),
    copyPasteDelta: z.number().int().min(0).max(MAX_DELTA).optional(),
    tabSwitchCount: z.number().int().min(0).optional(),
    focusLossSeconds: z.number().int().min(0).optional(),
    copyPasteAttempts: z.number().int().min(0).optional(),
    fullscreenExited: z.boolean().optional(),
    lastEventAt: z.string().optional(),
  })
  .strip();

// Hàm THUẦN (export để test) — công thức risk KHỚP spec §5, đã đưa fullscreenExited vào medium (A2).
export function computeRiskLevel({
  tabSwitchCount = 0,
  focusLossSeconds = 0,
  copyPasteAttempts = 0,
  fullscreenExited = false,
} = {}) {
  const tabs = Number(tabSwitchCount) || 0;
  const focus = Number(focusLossSeconds) || 0;
  const copy = Number(copyPasteAttempts) || 0;
  if (tabs >= RISK_TAB_SWITCHES || focus >= RISK_FOCUS_LOSS_SEC || copy >= 3) return 'high';
  if (tabs >= 2 || focus >= 45 || copy >= 1 || !!fullscreenExited) return 'medium';
  return 'low';
}

// MONOTONIC merge (A1): counter chỉ tăng; absolute -> max(cũ, mới); fullscreen latch OR. Export để test.
export function mergeIntegrity(prev = {}, patch = {}) {
  const out = { ...prev };
  const prevTab = Number(out.tabSwitchCount) || 0;
  const prevFocus = Number(out.focusLossSeconds) || 0;
  const prevCopy = Number(out.copyPasteAttempts) || 0;

  if (patch.tabSwitchDelta != null) {
    out.tabSwitchCount = prevTab + Math.max(0, Number(patch.tabSwitchDelta) || 0);
  } else if (patch.tabSwitchCount != null) {
    out.tabSwitchCount = Math.max(prevTab, Math.max(0, Number(patch.tabSwitchCount) || 0));
  }

  if (patch.focusLossDelta != null) {
    out.focusLossSeconds = prevFocus + Math.max(0, Number(patch.focusLossDelta) || 0);
  } else if (patch.focusLossSeconds != null) {
    out.focusLossSeconds = Math.max(prevFocus, Math.max(0, Number(patch.focusLossSeconds) || 0));
  }

  if (patch.copyPasteDelta != null) {
    out.copyPasteAttempts = prevCopy + Math.max(0, Number(patch.copyPasteDelta) || 0);
  } else if (patch.copyPasteAttempts != null) {
    out.copyPasteAttempts = Math.max(prevCopy, Math.max(0, Number(patch.copyPasteAttempts) || 0));
  }

  // Latch: đã thoát fullscreen thì giữ true (§5). Không cho set về false.
  if (patch.fullscreenExited === true) out.fullscreenExited = true;
  else out.fullscreenExited = !!out.fullscreenExited;

  out.lastEventAt = patch.lastEventAt != null ? patch.lastEventAt : new Date().toISOString();
  out.riskLevel = computeRiskLevel(out);
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

    const parsed = integrityPatchSchema.safeParse(patch || {});
    if (!parsed.success) throw httpError(400, 'Invalid integrity payload');
    const prevRaw = attempt.integrity;
    const prev = prevRaw && typeof prevRaw.toObject === 'function'
      ? prevRaw.toObject()
      : prevRaw && typeof prevRaw === 'object'
        ? prevRaw
        : {};
    attempt.integrity = mergeIntegrity(prev, parsed.data);
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
