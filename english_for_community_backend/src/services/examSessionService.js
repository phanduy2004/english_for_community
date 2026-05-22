import crypto from 'crypto';
import ExamSession from '../models/ExamSession.js';
import ExamAttempt from '../models/ExamAttempt.js';
import User from '../models/User.js';
import { teacherExamAssignmentService } from './teacherExamAssignmentService.js';
import { computeAttemptDeadline, examAttemptService } from './examAttemptService.js';
import { emitExamSessionEvent } from '../socket/examSocketEmit.js';
import { buildAssignmentCardFields } from './assignmentCardEnrichment.js';
import { broadcastAllSessionAttempts, examLiveMonitorService } from './examLiveMonitorService.js';

function mapJoinedUsersToParticipants(joinedUserIds, readyUserIds = []) {
  const readySet = new Set((readyUserIds || []).map((id) => id.toString()));
  const raw = joinedUserIds || [];
  return raw.map((u) => {
    if (u && typeof u === 'object' && u._id) {
      const userId = u._id.toString();
      return {
        userId,
        fullName: u.fullName || '',
        email: u.email || '',
        username: u.username || '',
        ready: readySet.has(userId),
      };
    }
    const userId = String(u);
    return { userId, fullName: '', email: '', username: '', ready: readySet.has(userId) };
  });
}

async function buildSessionContext(session) {
  const assignment = session.assignmentId;
  if (!assignment || typeof assignment !== 'object') return null;
  const exam = assignment.examId;
  const classroom = assignment.classroomId;
  const teacher = await User.findById(session.leaderTeacherId).select('fullName email username').lean();
  const teacherName =
    teacher?.fullName?.trim() || teacher?.username?.trim() || teacher?.email?.trim() || '';
  return {
    assignmentId: assignment._id?.toString(),
    examTitle: exam?.title || '',
    examDescription: exam?.description || '',
    classroomName: classroom?.name || '',
    classroomId: classroom?._id?.toString() || null,
    teacherName,
    mode: assignment.mode,
    ...buildAssignmentCardFields(assignment, {}),
  };
}

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

const CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function randomRoomCode() {
  const bytes = crypto.randomBytes(6);
  let code = '';
  for (let i = 0; i < 6; i += 1) {
    code += CODE_CHARS[bytes[i] % CODE_CHARS.length];
  }
  return code;
}

function isoDate(d) {
  if (!d) return null;
  const t = new Date(d).getTime();
  if (Number.isNaN(t)) return null;
  return new Date(t).toISOString();
}

/** Earliest auto-end for a live realtime session (time limit and/or hardEndAt). */
function computeSessionScheduledEnd(session, assignment) {
  if (!session || !assignment) return null;
  const cfg = assignment.config || {};
  const hard = cfg.hardEndAt ? new Date(cfg.hardEndAt) : null;
  const started = session.startedAt ? new Date(session.startedAt) : null;
  const limitSec = cfg.timeLimitSeconds;
  let fromLimit = null;
  if (started && !Number.isNaN(started.getTime()) && limitSec && Number(limitSec) > 0) {
    fromLimit = new Date(started.getTime() + Number(limitSec) * 1000);
  }
  const hardOk = hard && !Number.isNaN(hard.getTime());
  if (hardOk && fromLimit) return new Date(Math.min(hard.getTime(), fromLimit.getTime()));
  if (hardOk) return hard;
  return fromLimit;
}

export const examSessionService = {
  /**
   * Payload for Socket.IO `exam_session_state` + teacher GET lobby (participants = students in lobby, no teacher row).
   */
  async buildRealtimePayload(sessionId, { includeContext = false } = {}) {
    const sid = sessionId?.toString?.() ?? String(sessionId);
    const session = await ExamSession.findById(sid)
      .populate({ path: 'joinedUserIds', select: 'fullName email username' })
      .populate({
        path: 'assignmentId',
        populate: [{ path: 'examId', select: 'title description settings' }, { path: 'classroomId', select: 'name' }],
      })
      .lean();
    if (!session) return null;
    const participants = mapJoinedUsersToParticipants(session.joinedUserIds, session.readyUserIds);
    const readyCount = participants.filter((p) => p.ready).length;
    const assignment =
      session.assignmentId && typeof session.assignmentId === 'object' ? session.assignmentId : null;
    const scheduledEnd = assignment ? computeSessionScheduledEnd(session, assignment) : null;
    const cfg = assignment?.config || {};
    const payload = {
      sessionId: session._id.toString(),
      status: session.status,
      roomCode: session.roomCode || '',
      joinedCount: participants.length,
      readyCount,
      participants,
      startedAt: isoDate(session.startedAt),
      endedAt: isoDate(session.endedAt),
      createdAt: isoDate(session.createdAt),
      scheduledEndAt: isoDate(scheduledEnd),
      hardEndAt: isoDate(cfg.hardEndAt),
      timeLimitSeconds:
        cfg.timeLimitSeconds != null && Number(cfg.timeLimitSeconds) > 0
          ? Number(cfg.timeLimitSeconds)
          : null,
    };
    if (includeContext) {
      payload.context = await buildSessionContext(session);
    }
    return payload;
  },

  async removeParticipantFromSession(sessionId, userId) {
    const sid = sessionId?.toString?.() ?? String(sessionId);
    const uid = userId?.toString?.() ?? String(userId);
    await ExamSession.updateOne(
      { _id: sid },
      { $pull: { joinedUserIds: uid, readyUserIds: uid } }
    );
    await ExamAttempt.updateMany(
      { sessionId: sid, userId: uid, status: 'in_progress' },
      { $set: { status: 'void', submittedAt: new Date() } }
    );
  },

  async kickParticipant(teacherId, sessionId, studentUserId) {
    const session = await ExamSession.findById(sessionId);
    if (!session) throw httpError(404, 'Session not found');
    if (session.leaderTeacherId.toString() !== teacherId.toString()) throw httpError(403, 'Forbidden');
    if (!['lobby', 'live'].includes(session.status)) {
      throw httpError(400, 'Cannot remove students after the session has ended');
    }
    const uid = studentUserId.toString();
    if (uid === session.leaderTeacherId.toString()) throw httpError(400, 'Cannot remove the session leader');
    const joined = (session.joinedUserIds || []).map((x) => x.toString());
    if (!joined.includes(uid)) throw httpError(404, 'Student is not in this session');

    await this.removeParticipantFromSession(session._id, uid);
    emitExamSessionEvent(session._id.toString(), 'exam_session_kicked', {
      sessionId: session._id.toString(),
      userId: uid,
      reason: 'teacher_kicked',
    });
    await this.emitSessionStateBroadcast(session._id);
    return this.buildRealtimePayload(session._id, { includeContext: true });
  },

  async setParticipantReady(userId, sessionId, ready) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    if (session.status !== 'lobby') throw httpError(400, 'Ready status only applies in lobby');
    const uid = userId.toString();
    if (session.leaderTeacherId.toString() === uid) {
      throw httpError(400, 'Teacher cannot set ready status');
    }
    await teacherExamAssignmentService.assertStudentEntitled(userId, session.assignmentId._id.toString());
    const joined = (session.joinedUserIds || []).map((x) => x.toString());
    if (!joined.includes(uid)) throw httpError(400, 'Join the lobby first');
    if (ready) {
      await ExamSession.updateOne({ _id: session._id }, { $addToSet: { readyUserIds: userId } });
    } else {
      await ExamSession.updateOne({ _id: session._id }, { $pull: { readyUserIds: userId } });
    }
    await this.emitSessionStateBroadcast(session._id);
    return this.buildRealtimePayload(session._id, { includeContext: true });
  },

  async getSessionConsoleForTeacher(teacherId, assignmentId) {
    const assignment = await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);
    await assignment.populate([
      { path: 'examId', select: 'title description settings' },
      { path: 'classroomId', select: 'name description' },
    ]);
    const teacher = await User.findById(teacherId).select('fullName email username').lean();
    const assignmentContext = {
      assignmentId: assignment._id.toString(),
      examTitle: assignment.examId?.title || '',
      examDescription: assignment.examId?.description || '',
      classroomName: assignment.classroomId?.name || '',
      classroomId: assignment.classroomId?._id?.toString() || null,
      teacherName: teacher?.fullName?.trim() || teacher?.username?.trim() || teacher?.email?.trim() || '',
      mode: assignment.mode,
      assignedAt: assignment.createdAt ? new Date(assignment.createdAt).toISOString() : null,
      ...buildAssignmentCardFields(assignment, {}),
    };

    const session = await ExamSession.findOne({ assignmentId: assignment._id }).sort({ updatedAt: -1 });
    let liveState = null;
    let sessionDoc = null;
    if (session) {
      sessionDoc = session.toJSON ? session.toJSON() : session;
      liveState = await this.buildRealtimePayload(session._id, { includeContext: true });
      if (sessionDoc && liveState) {
        sessionDoc.scheduledEndAt = liveState.scheduledEndAt ?? null;
        sessionDoc.hardEndAt = liveState.hardEndAt ?? null;
        sessionDoc.timeLimitSeconds = liveState.timeLimitSeconds ?? null;
      }
    }
    return { assignment: assignmentContext, session: sessionDoc, liveState };
  },

  async emitSessionStateBroadcast(sessionId) {
    const payload = await this.buildRealtimePayload(sessionId);
    if (payload) {
      emitExamSessionEvent(sessionId, 'exam_session_state', payload);
    }
  },

  async getSessionLobbyForTeacher(teacherId, sessionId) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    const assignment = session.assignmentId;
    if (!assignment || assignment.teacherId.toString() !== teacherId.toString()) {
      throw httpError(403, 'Forbidden');
    }
    const payload = await this.buildRealtimePayload(sessionId, { includeContext: true });
    if (!payload) throw httpError(404, 'Session not found');
    return payload;
  },

  async createSession(teacherId, assignmentId) {
    const assignment = await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);
    if (assignment.mode !== 'realtime') throw httpError(400, 'Assignment must be realtime mode');
    const exam = assignment.examId;
    if (!exam) throw httpError(500, 'Exam not populated');
    const snapshot = exam.toObject ? exam.toObject() : exam;
    delete snapshot._id;

    const existing = await ExamSession.findOne({ assignmentId: assignment._id, status: 'lobby' });
    if (existing) {
      await this.emitSessionStateBroadcast(existing._id);
      return existing;
    }

    const session = await ExamSession.create({
      assignmentId: assignment._id,
      leaderTeacherId: teacherId,
      examSnapshot: snapshot,
      status: 'lobby',
      roomCode: randomRoomCode(),
      joinedUserIds: [],
    });
    await this.emitSessionStateBroadcast(session._id);
    return session;
  },

  async joinSession(userId, sessionId) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    const assignment = session.assignmentId;
    if (!assignment) throw httpError(500, 'Assignment missing');
    const isLeader = session.leaderTeacherId.toString() === userId.toString();
    const uid = userId.toString();

    if (!isLeader) {
      await teacherExamAssignmentService.assertStudentEntitled(userId, assignment._id.toString());

      const voidLeft = await ExamAttempt.findOne({
        sessionId: session._id,
        userId,
        status: 'void',
        'meta.voluntaryExit': true,
      }).lean();
      if (voidLeft) {
        throw httpError(403, 'You cannot rejoin this exam after leaving');
      }

      if (session.status !== 'lobby') {
        const active = await ExamAttempt.findOne({
          sessionId: session._id,
          userId,
          status: 'in_progress',
        }).lean();
        if (!active) {
          if (session.status === 'live') {
            throw httpError(
              400,
              'The exam has already started. You were not in the lobby when it began.'
            );
          }
          throw httpError(400, 'Session is not accepting joins');
        }
        const ids = (session.joinedUserIds || []).map((x) => x.toString());
        if (!ids.includes(uid)) {
          session.joinedUserIds = [...(session.joinedUserIds || []), userId];
          await session.save();
        }
        await this.emitSessionStateBroadcast(session._id);
        return session;
      }

      const ids = (session.joinedUserIds || []).map((x) => x.toString());
      if (!ids.includes(uid)) {
        session.joinedUserIds = [...(session.joinedUserIds || []), userId];
        await session.save();
      }
    }
    await this.emitSessionStateBroadcast(session._id);
    return session;
  },

  /**
   * Student voluntarily leaves an in-progress realtime attempt (cannot re-enter).
   */
  async abandonStudentAttempt(userId, attemptId) {
    const attempt = await ExamAttempt.findById(attemptId);
    if (!attempt) throw httpError(404, 'Attempt not found');
    if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
    if (attempt.status !== 'in_progress') throw httpError(400, 'Attempt is not in progress');
    if (!attempt.sessionId) throw httpError(400, 'Not a live session attempt');

    const session = await ExamSession.findById(attempt.sessionId);
    if (!session) throw httpError(404, 'Session not found');
    if (!['lobby', 'live'].includes(session.status)) {
      throw httpError(400, 'Session has ended');
    }

    attempt.status = 'void';
    attempt.submittedAt = new Date();
    attempt.meta = {
      ...(attempt.meta && typeof attempt.meta === 'object' ? attempt.meta : {}),
      canAnswer: false,
      voluntaryExit: true,
      exitReason: 'student_left',
    };
    await attempt.save();

    await this.removeParticipantFromSession(session._id, userId);
    await broadcastAllSessionAttempts(session._id);
    await this.emitSessionStateBroadcast(session._id);

    return examAttemptService.buildStudentAttemptJson(attempt);
  },

  async startSession(teacherId, sessionId) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    if (session.leaderTeacherId.toString() !== teacherId.toString()) throw httpError(403, 'Forbidden');
    if (session.status !== 'lobby') throw httpError(400, 'Session already started or closed');

    const assignment = session.assignmentId;
    const exam = session.examSnapshot;
    const startedAt = new Date();
    const attemptDeadlineAt = computeAttemptDeadline(assignment, startedAt);
    session.status = 'live';
    session.startedAt = startedAt;
    session.readyUserIds = [];
    await session.save();

    const joined = session.joinedUserIds || [];
    for (const uid of joined) {
      if (uid.toString() === session.leaderTeacherId.toString()) continue;
      const existing = await ExamAttempt.findOne({
        assignmentId: assignment._id,
        userId: uid,
        sessionId: session._id,
        status: 'in_progress',
      });
      if (existing) continue;
      await ExamAttempt.create({
        assignmentId: assignment._id,
        sessionId: session._id,
        userId: uid,
        examSnapshot: exam,
        status: 'in_progress',
        startedAt,
        attemptDeadlineAt,
        meta: { realtime: true, canAnswer: true },
        answers: {},
        gradingState: 'pending_auto',
      });
    }

    await this.emitSessionStateBroadcast(session._id);
    await broadcastAllSessionAttempts(session._id);
    return session;
  },

  async endSession(teacherId, sessionId) {
    const session = await ExamSession.findById(sessionId).populate('assignmentId');
    if (!session) throw httpError(404, 'Session not found');
    if (session.leaderTeacherId.toString() !== teacherId.toString()) throw httpError(403, 'Forbidden');
    if (session.status === 'closed' || session.status === 'canceled') return session;

    const endedAt = new Date();
    session.status = 'grading';
    session.endedAt = endedAt;
    await session.save();

    const attempts = await ExamAttempt.find({ sessionId: session._id, status: 'in_progress' });
    for (const att of attempts) {
      att.meta = { ...(att.meta || {}), canAnswer: false, sessionEndedByTeacher: true };
      await att.save();
      try {
        await examAttemptService.submit(att.userId.toString(), att._id.toString(), {
          force: true,
          forceEnd: true,
        });
      } catch {
        att.status = 'void';
        att.submittedAt = endedAt;
        att.scores = {};
        att.gradingState = 'pending_auto';
        att.resultsReleased = false;
        await att.save();
      }
    }

    session.joinedUserIds = [];
    session.readyUserIds = [];
    session.status = 'closed';
    await session.save();

    await this.emitSessionStateBroadcast(session._id);
    emitExamSessionEvent(session._id.toString(), 'exam_session_ended', {
      sessionId: session._id.toString(),
      status: 'closed',
      reason: 'teacher_ended',
      endedAt: endedAt.toISOString(),
    });
    return session;
  },

  async getMyAttempt(userId, sessionId) {
    const att = await ExamAttempt.findOne({ sessionId, userId, status: 'in_progress' });
    if (att) return examAttemptService.buildStudentAttemptJson(att);

    const submitted = await ExamAttempt.findOne({ sessionId, userId, status: 'submitted' })
      .sort({ submittedAt: -1 })
      .lean();
    if (submitted) return examAttemptService.buildStudentAttemptJson(submitted);

    const voidAtt = await ExamAttempt.findOne({ sessionId, userId, status: 'void' })
      .sort({ updatedAt: -1 })
      .lean();
    if (voidAtt?.meta?.voluntaryExit === true) {
      return {
        blocked: true,
        code: 'voluntary_exit',
        message: 'You left this exam and cannot re-enter.',
      };
    }
    return null;
  },
};
