import { z } from 'zod';
import crypto from 'crypto';
import mongoose from 'mongoose';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ClassroomMember from '../models/ClassroomMember.js';
import { classroomService } from './classroomService.js';
import { teacherExamService } from './teacherExamService.js';
import {
  applyStudentAttemptGate,
  buildAssignmentCardFields,
  latestAttemptsByAssignmentForUser,
  attemptStatsByAssignment,
  serializeActiveSession,
} from './assignmentCardEnrichment.js';
import { isRealtimeLobbyClosedForStudent } from './realtimeSchedule.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

export function normalizeAssignmentConfig(raw = {}) {
  const c = { ...raw };
  const ap = c.attemptPolicy;
  if (ap !== 'single' && ap !== 'unlimited' && ap !== 'limited') {
    c.attemptPolicy = 'single';
  }
  if (c.attemptPolicy === 'limited') {
    const n = Number(c.maxAttempts);
    c.maxAttempts = Number.isFinite(n) && n > 1 ? Math.min(99, Math.floor(n)) : 2;
  } else {
    delete c.maxAttempts;
  }
  const sr = c.showResultsPolicy;
  if (sr !== 'after_submit' && sr !== 'after_release' && sr !== 'never') {
    delete c.showResultsPolicy;
  }
  const rd = c.resultsDetailLevel;
  if (rd !== 'score_only' && rd !== 'full_detail') {
    delete c.resultsDetailLevel;
  }
  if (c.timeLimitSeconds !== undefined) {
    const n = Number(c.timeLimitSeconds);
    c.timeLimitSeconds = Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
  }
  if (c.realtimeScheduleMode !== 'manual' && c.realtimeScheduleMode !== 'scheduled') {
    delete c.realtimeScheduleMode;
  }
  return c;
}

const assignmentCreateSchema = z.object({
  examId: z.string().min(1),
  audience: z.enum(['classroom', 'public_link']),
  classroomId: z.string().optional().nullable(),
  mode: z.enum(['self_paced', 'scheduled', 'realtime', 'practice']),
  config: z.record(z.string(), z.any()).optional().default({}),
  publicJoin: z
    .object({
      maxUses: z.number().int().positive().optional().nullable(),
      expiresAt: z.string().datetime().optional().nullable(),
    })
    .optional()
    .nullable(),
});

function nowInWindowForScheduled(a) {
  const opens = a.config?.opensAt ? new Date(a.config.opensAt).getTime() : null;
  const closes = a.config?.closesAt ? new Date(a.config.closesAt).getTime() : null;
  const t = Date.now();
  if (opens != null && t < opens) return false;
  if (closes != null && t > closes) return false;
  return true;
}

function selfPacedNotPastDue(a) {
  if (a.mode === 'practice') return true;
  const due = a.config?.dueAt ? new Date(a.config.dueAt).getTime() : null;
  if (due != null && Date.now() > due) return false;
  return true;
}

async function latestSessionMapForAssignments(assignments, statuses = ['lobby', 'live']) {
  const ids = assignments.map((a) => a._id);
  if (ids.length === 0) return new Map();
  const sessions = await ExamSession.find({
    assignmentId: { $in: ids },
    status: { $in: statuses },
  }).sort({ updatedAt: -1 });
  const map = new Map();
  for (const s of sessions) {
    const aid = s.assignmentId.toString();
    if (!map.has(aid)) map.set(aid, s);
  }
  return map;
}

/** Latest ended session per assignment (for class history). */
async function latestClosedSessionMapForAssignments(assignments) {
  return latestSessionMapForAssignments(assignments, ['closed', 'canceled', 'grading']);
}

function teacherListSegmentForAssignment(assignment, activeSessionMap, closedSessionMap) {
  if (assignment.mode !== 'realtime') return 'active';
  const aid = assignment._id.toString();
  if (activeSessionMap.has(aid)) return 'active';
  if (closedSessionMap.has(aid)) return 'history';
  return 'active';
}

/** Classroom list: show every active assignment; gate "start" via studentCanStart + studentStatusHint. */
function enrichStudentAssignmentView(a, activeSessionMap, closedSessionMap) {
  const plain = a.toJSON ? a.toJSON() : { ...a };
  let studentCanStart = false;
  let studentStatusHint = 'available';

  if (a.mode === 'practice') {
    studentCanStart = true;
    studentStatusHint = 'practice';
  } else if (a.mode === 'self_paced') {
    studentCanStart = selfPacedNotPastDue(a);
    if (!studentCanStart) studentStatusHint = 'past_due';
  } else if (a.mode === 'scheduled') {
    const opens = a.config?.opensAt ? new Date(a.config.opensAt).getTime() : null;
    const closes = a.config?.closesAt ? new Date(a.config.closesAt).getTime() : null;
    const t = Date.now();
    if (closes != null && t > closes) {
      studentCanStart = false;
      studentStatusHint = 'closed';
    } else if (opens != null && t < opens) {
      studentCanStart = false;
      studentStatusHint = 'not_yet_open';
    } else {
      studentCanStart = true;
    }
  } else if (a.mode === 'realtime') {
    const aid = a._id.toString();
    const active = activeSessionMap.get(aid);
    const closed = closedSessionMap.get(aid);
    if (active) {
      plain.activeSession = serializeActiveSession(active);
      if (isRealtimeLobbyClosedForStudent(a)) {
        studentCanStart = false;
        studentStatusHint = 'not_yet_open';
      } else {
        studentCanStart = active.status === 'lobby' || active.status === 'live';
        studentStatusHint = active.status;
      }
    } else if (closed) {
      plain.latestClosedSession = serializeActiveSession(closed);
      studentCanStart = false;
      studentStatusHint = 'session_ended';
    } else if (isRealtimeLobbyClosedForStudent(a)) {
      studentCanStart = false;
      studentStatusHint = 'not_yet_open';
    } else {
      studentCanStart = false;
      studentStatusHint = 'waiting_for_teacher';
    }
  }

  plain.studentCanStart = studentCanStart;
  plain.studentStatusHint = studentStatusHint;
  return plain;
}

function enrichTeacherAssignmentView(a, activeSessionMap, closedSessionMap, attemptStatsMap) {
  const plain = a.toJSON ? a.toJSON() : { ...a };
  const sessionDoc = activeSessionMap.get(a._id.toString());
  const closedDoc = closedSessionMap.get(a._id.toString());
  const stats = attemptStatsMap.get(a._id.toString()) || null;
  Object.assign(
    plain,
    buildAssignmentCardFields(a, {
      activeSession: sessionDoc,
      attemptStats: stats,
    })
  );
  if (closedDoc) {
    plain.latestClosedSession = serializeActiveSession(closedDoc);
  }
  plain.teacherListSegment = teacherListSegmentForAssignment(a, activeSessionMap, closedSessionMap);
  return plain;
}

export const teacherExamAssignmentService = {
  async assertTeacherOwnsAssignment(teacherId, assignmentId) {
    const a = await ExamAssignment.findById(assignmentId).populate('examId');
    if (!a) throw httpError(404, 'Assignment not found');
    if (a.teacherId.toString() === teacherId.toString()) return a;
    if (a.classroomId) {
      await classroomService.assertCanManageClassroom(teacherId, a.classroomId);
      return a;
    }
    throw httpError(403, 'Forbidden');
  },

  async create(teacherId, body) {
    const parsed = assignmentCreateSchema.parse(body);
    const exam = await teacherExamService.assertTeacherOwnsExam(teacherId, parsed.examId);
    if (exam.status !== 'published') throw httpError(400, 'Exam must be published before assignment');

    if (parsed.audience === 'classroom') {
      if (!parsed.classroomId) throw httpError(400, 'classroomId is required for classroom audience');
      const { isTeacher } = await classroomService.getByIdForUser(parsed.classroomId, teacherId);
      if (!isTeacher) throw httpError(403, 'Not your classroom');
    }

    const incomingConfig = normalizeAssignmentConfig(parsed.config || {});
    const isPractice = parsed.mode === 'practice';
    const doc = {
      examId: exam._id,
      teacherId,
      audience: parsed.audience,
      classroomId: parsed.classroomId || null,
      mode: parsed.mode,
      config: {
        allowPartialSubmit: true,
        partialSubmitConfirm: true,
        attemptPolicy: isPractice ? 'unlimited' : 'single',
        showResultsPolicy: isPractice ? 'after_submit' : 'after_release',
        countsInGradebook: !isPractice,
        practiceMode: isPractice,
        ...incomingConfig,
      },
      status: 'active',
    };

    if (parsed.audience === 'public_link') {
      doc.publicJoin = {
        token: crypto.randomBytes(18).toString('hex'),
        maxUses: parsed.publicJoin?.maxUses ?? null,
        expiresAt: parsed.publicJoin?.expiresAt ? new Date(parsed.publicJoin.expiresAt) : null,
        usesCount: 0,
      };
    }

    const assignment = await ExamAssignment.create(doc);
    if (parsed.audience === 'classroom' && parsed.classroomId) {
      try {
        const populated = await ExamAssignment.findById(assignment._id)
          .populate('examId', 'title')
          .populate('classroomId', 'name');
        const { notifyStudentsExamAssigned, assignmentNotificationContext } = await import(
          './teacherNotificationHelper.js'
        );
        const { examTitle, classroomName } = await assignmentNotificationContext(populated);
        const sent = await notifyStudentsExamAssigned({
          teacherId,
          classroomId: parsed.classroomId,
          assignmentId: assignment._id,
          examTitle,
          classroomName,
        });
        console.log(
          `📢 [Notify] EXAM_ASSIGNED → ${sent.length} student(s) (classroom ${parsed.classroomId})`
        );
      } catch (err) {
        console.error('[Notify] EXAM_ASSIGNED failed:', err?.message || err);
      }
    }
    return assignment;
  },

  async listForTeacher(teacherId) {
    const assignments = await ExamAssignment.find({ teacherId })
      .sort({ updatedAt: -1 })
      .populate('examId')
      .populate('classroomId');

    const activeSessionMap = await latestSessionMapForAssignments(assignments);
    const closedSessionMap = await latestClosedSessionMapForAssignments(assignments);
    const ids = assignments.map((a) => a._id);
    const statsMap = await attemptStatsByAssignment(ids);

    return assignments.map((a) => enrichTeacherAssignmentView(a, activeSessionMap, closedSessionMap, statsMap));
  },

  async findByPublicToken(token) {
    return ExamAssignment.findOne({ 'publicJoin.token': token, status: 'active' }).populate('examId');
  },

  async previewPublicByToken(token) {
    const a = await this.findByPublicToken(token);
    if (!a) throw httpError(404, 'Link not found');
    const pj = a.publicJoin || {};
    if (pj.expiresAt && new Date(pj.expiresAt).getTime() < Date.now()) throw httpError(400, 'Link expired');
    if (pj.maxUses != null && (pj.usesCount || 0) >= pj.maxUses) throw httpError(400, 'Link has reached maximum uses');
    const exam = a.examId;
    return {
      assignmentId: a._id.toString(),
      mode: a.mode,
      examTitle: exam?.title || 'Exam',
      expiresAt: pj.expiresAt || null,
    };
  },

  async assertPublicTokenValid(assignment, publicToken) {
    if (assignment.audience !== 'public_link') throw httpError(400, 'Not a public assignment');
    if (!assignment.publicJoin?.token) throw httpError(400, 'Invalid public assignment');
    if (!publicToken || publicToken !== assignment.publicJoin.token) throw httpError(403, 'Invalid join link');
    if (assignment.publicJoin.expiresAt && new Date(assignment.publicJoin.expiresAt).getTime() < Date.now()) {
      throw httpError(400, 'Link expired');
    }
    if (assignment.publicJoin.maxUses != null && (assignment.publicJoin.usesCount || 0) >= assignment.publicJoin.maxUses) {
      throw httpError(400, 'Link has reached maximum uses');
    }
  },

  /**
   * Atomically reserve one public "start" slot when creating a new attempt.
   */
  async consumePublicStartSlot(assignmentId) {
    const filter = {
      _id: assignmentId,
      audience: 'public_link',
      status: 'active',
      $or: [{ 'publicJoin.maxUses': null }, { $expr: { $lt: ['$publicJoin.usesCount', '$publicJoin.maxUses'] } }],
    };
    const updated = await ExamAssignment.findOneAndUpdate(filter, { $inc: { 'publicJoin.usesCount': 1 } }, { new: true });
    if (!updated) throw httpError(400, 'Cannot start: link expired or fully used');
    return updated;
  },

  async listAvailableForStudent(userId) {
    const memberships = await ClassroomMember.find({ userId, status: 'active' }).select('classroomId');
    const classIds = memberships.map((m) => m.classroomId);

    const assignments = await ExamAssignment.find({
      status: 'active',
      audience: 'classroom',
      classroomId: { $in: classIds },
      mode: { $in: ['self_paced', 'scheduled', 'realtime', 'practice'] },
    })
      .sort({ updatedAt: -1 })
      .populate('examId')
      .populate('classroomId');

    const ids = assignments.map((a) => a._id);
    const sessions = await ExamSession.find({
      assignmentId: { $in: ids },
      status: { $in: ['lobby', 'live'] },
    }).sort({ updatedAt: -1 });

    const latestSessionByAssignment = new Map();
    for (const s of sessions) {
      const aid = s.assignmentId.toString();
      if (!latestSessionByAssignment.has(aid)) latestSessionByAssignment.set(aid, s);
    }

    return assignments
      .filter((a) => {
        if (a.mode === 'self_paced') return selfPacedNotPastDue(a);
        if (a.mode === 'scheduled') return nowInWindowForScheduled(a);
        if (a.mode === 'realtime') return latestSessionByAssignment.has(a._id.toString());
        return false;
      })
      .map((a) => {
        const plain = a.toJSON ? a.toJSON() : a;
        if (a.mode === 'realtime') {
          const s = latestSessionByAssignment.get(a._id.toString());
          if (s) {
            plain.activeSession = {
              id: s._id.toString(),
              status: s.status,
              roomCode: s.roomCode,
            };
          }
        }
        return plain;
      });
  },

  async listAvailableForStudentInClassroom(userId, classroomId) {
    if (!mongoose.Types.ObjectId.isValid(classroomId)) {
      throw httpError(400, 'Invalid classroom id');
    }
    const classOid = new mongoose.Types.ObjectId(classroomId);

    const m = await ClassroomMember.findOne({
      userId,
      classroomId: classOid,
      status: 'active',
    });
    if (!m) throw httpError(403, 'Not a member of this classroom');

    const assignments = await ExamAssignment.find({
      status: 'active',
      audience: 'classroom',
      classroomId: classOid,
      mode: { $in: ['self_paced', 'scheduled', 'realtime', 'practice'] },
    })
      .sort({ updatedAt: -1 })
      .populate('examId')
      .populate('classroomId');

    const activeSessionMap = await latestSessionMapForAssignments(assignments);
    const closedSessionMap = await latestClosedSessionMapForAssignments(assignments);
    const ids = assignments.map((a) => a._id);
    const assignmentById = new Map(assignments.map((a) => [a._id.toString(), a]));
    const myAttemptMap = await latestAttemptsByAssignmentForUser(userId, ids, { assignmentById });

    return assignments.map((a) => {
      const plain = enrichStudentAssignmentView(a, activeSessionMap, closedSessionMap);
      const att = myAttemptMap.get(a._id.toString());
      Object.assign(
        plain,
        buildAssignmentCardFields(a, {
          activeSession: activeSessionMap.get(a._id.toString()),
          myAttempt: att,
        })
      );
      return applyStudentAttemptGate(plain, a, att);
    });
  },

  async listForTeacherInClassroom(teacherId, classroomId) {
    if (!mongoose.Types.ObjectId.isValid(classroomId)) {
      throw httpError(400, 'Invalid classroom id');
    }
    const classOid = new mongoose.Types.ObjectId(classroomId);
    const { isTeacher } = await classroomService.getByIdForUser(classroomId, teacherId);
    if (!isTeacher) throw httpError(403, 'Not your classroom');

    const assignments = await ExamAssignment.find({
      teacherId,
      audience: 'classroom',
      classroomId: classOid,
    })
      .sort({ updatedAt: -1 })
      .populate('examId')
      .populate('classroomId');

    const activeSessionMap = await latestSessionMapForAssignments(assignments);
    const closedSessionMap = await latestClosedSessionMapForAssignments(assignments);
    const ids = assignments.map((a) => a._id);
    const statsMap = await attemptStatsByAssignment(ids);

    return assignments.map((a) => enrichTeacherAssignmentView(a, activeSessionMap, closedSessionMap, statsMap));
  },

  async duplicateAssignment(teacherId, assignmentId, body = {}) {
    const src = await this.assertTeacherOwnsAssignment(teacherId, assignmentId);
    const examId = src.examId?._id?.toString() || src.examId?.toString();
    return this.create(teacherId, {
      examId,
      audience: body.audience ?? src.audience,
      classroomId: body.classroomId ?? (src.classroomId ? src.classroomId.toString() : null),
      mode: body.mode ?? src.mode,
      config: { ...(src.config || {}), ...(body.config || {}) },
      publicJoin: body.publicJoin ?? null,
    });
  },

  async patchAssignment(teacherId, assignmentId, body = {}) {
    const a = await this.assertTeacherOwnsAssignment(teacherId, assignmentId);
    if (a.status !== 'active') throw httpError(400, 'Only active assignments can be updated');

    const cfg = { ...(a.config || {}) };
    const patchCfg = body.config;
    if (patchCfg && typeof patchCfg === 'object') {
      const dateFields = [
        'dueAt',
        'opensAt',
        'closesAt',
        'lobbyOpensAt',
        'scheduledStartAt',
        'hardEndAt',
      ];
      for (const k of dateFields) {
        if (patchCfg[k] !== undefined) {
          cfg[k] = patchCfg[k] ? new Date(patchCfg[k]) : null;
        }
      }
      if (patchCfg.realtimeScheduleMode !== undefined) {
        cfg.realtimeScheduleMode = patchCfg.realtimeScheduleMode;
        if (patchCfg.realtimeScheduleMode === 'manual') {
          cfg.lobbyOpensAt = null;
          cfg.scheduledStartAt = null;
        }
      }
      if (patchCfg.timeLimitSeconds !== undefined) {
        const n = Number(patchCfg.timeLimitSeconds);
        cfg.timeLimitSeconds = Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
      }
      if (patchCfg.allowPartialSubmit !== undefined) cfg.allowPartialSubmit = !!patchCfg.allowPartialSubmit;
      if (patchCfg.attemptPolicy !== undefined) cfg.attemptPolicy = patchCfg.attemptPolicy;
      if (patchCfg.maxAttempts !== undefined) cfg.maxAttempts = patchCfg.maxAttempts;
      if (patchCfg.showResultsPolicy !== undefined) cfg.showResultsPolicy = patchCfg.showResultsPolicy;
      if (patchCfg.resultsDetailLevel !== undefined) cfg.resultsDetailLevel = patchCfg.resultsDetailLevel;
      a.config = normalizeAssignmentConfig(cfg);
    }
    await a.save();
    if (a.audience === 'classroom' && a.classroomId) {
      try {
        await a.populate([{ path: 'examId', select: 'title' }, { path: 'classroomId', select: 'name' }]);
        const { notifyStudentsExamAssignmentUpdated, assignmentNotificationContext } = await import(
          './teacherNotificationHelper.js'
        );
        const { examTitle, classroomName } = await assignmentNotificationContext(a);
        await notifyStudentsExamAssignmentUpdated({
          teacherId,
          classroomId: a.classroomId._id || a.classroomId,
          assignmentId: a._id,
          examTitle,
          classroomName,
        });
      } catch {
        /* optional */
      }
    }
    return a;
  },

  async closeAssignment(teacherId, assignmentId) {
    const a = await this.assertTeacherOwnsAssignment(teacherId, assignmentId);
    if (a.status !== 'active') throw httpError(400, 'Assignment is already closed');
    a.status = 'closed';
    await a.save();
    if (a.audience === 'classroom' && a.classroomId) {
      try {
        await a.populate([{ path: 'examId', select: 'title' }, { path: 'classroomId', select: 'name' }]);
        const { notifyStudentsExamAssignmentClosed, assignmentNotificationContext } = await import(
          './teacherNotificationHelper.js'
        );
        const { examTitle, classroomName } = await assignmentNotificationContext(a);
        await notifyStudentsExamAssignmentClosed({
          teacherId,
          classroomId: a.classroomId._id || a.classroomId,
          assignmentId: a._id,
          examTitle,
          classroomName,
        });
      } catch {
        /* optional */
      }
    }
    return a;
  },

  async deleteAssignment(teacherId, assignmentId) {
    const a = await this.assertTeacherOwnsAssignment(teacherId, assignmentId);
    const submitted = await ExamAttempt.countDocuments({
      assignmentId: a._id,
      status: 'submitted',
    });
    if (submitted > 0) {
      throw httpError(
        400,
        'Cannot delete this assignment: students have submitted attempts. Close it instead.'
      );
    }
    await ExamAttempt.deleteMany({ assignmentId: a._id });
    await ExamSession.deleteMany({ assignmentId: a._id });
    await a.deleteOne();
    return { deleted: true, assignmentId: assignmentId.toString() };
  },

  /** Invalidate old public URLs: new token, usesCount reset. */
  async rotatePublicJoinToken(teacherId, assignmentId) {
    const a = await this.assertTeacherOwnsAssignment(teacherId, assignmentId);
    if (a.audience !== 'public_link') throw httpError(400, 'Not a public link assignment');
    if (!a.publicJoin) a.publicJoin = {};
    a.publicJoin.token = crypto.randomBytes(18).toString('hex');
    a.publicJoin.usesCount = 0;
    await a.save();
    return a;
  },

  async assertStudentEntitled(userId, assignmentId, { publicToken } = {}) {
    const a = await ExamAssignment.findById(assignmentId).populate('examId');
    if (!a || a.status !== 'active') throw httpError(404, 'Assignment not found');

    if (a.audience === 'classroom') {
      const m = await ClassroomMember.findOne({
        classroomId: a.classroomId,
        userId,
        status: 'active',
      });
      if (!m) throw httpError(403, 'Not assigned to you');
      return a;
    }

    if (a.audience === 'public_link') {
      await this.assertPublicTokenValid(a, publicToken);
      return a;
    }

    throw httpError(400, 'Unsupported audience');
  },
};
