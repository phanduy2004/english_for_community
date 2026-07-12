import { Server } from 'socket.io';
import User from '../models/User.js';
import ExamSession from '../models/ExamSession.js';
import ExamAttempt from '../models/ExamAttempt.js';
import { verifyAccessToken } from '../lib/jwt_token.js';
import { teacherExamAssignmentService } from '../services/teacherExamAssignmentService.js';

let io;

/** userId -> Set<socketId> — only mark offline when no active sockets remain. */
const onlineSocketIdsByUser = new Map();
const OFFLINE_GRACE_MS = 20000;
const pendingOffline = new Map();

/**
 * Per-(session,user) live exam sockets. Presence in the lobby roster
 * (`ExamSession.joinedUserIds`) is only cleared once a user has NO socket left in
 * the room, after a short grace so a reload / brief reconnect doesn't flicker them out.
 */
const examSessionSocketsByUser = new Map(); // `${sessionId}::${userId}` -> Set<socketId>
const LOBBY_PRESENCE_GRACE_MS = 10000;
const pendingLobbyRemoval = new Map(); // `${sessionId}::${userId}` -> timeout

/** Schedule a presence-only lobby cleanup; cancelled if the user rejoins within the grace window. */
function scheduleLobbyPresenceCleanup(sessionId, userId) {
  const key = `${sessionId}::${userId}`;
  if (pendingLobbyRemoval.has(key)) return;
  const t = setTimeout(async () => {
    pendingLobbyRemoval.delete(key);
    // Rejoined during grace (reload / reconnect / another tab)? Keep them.
    if (examSessionSocketsByUser.has(key)) return;
    try {
      const { examSessionService } = await import('../services/examSessionService.js');
      const removed = await examSessionService.removeLobbyParticipant(sessionId, userId);
      if (removed) await examSessionService.emitSessionStateBroadcast(sessionId);
    } catch (e) {
      console.error('[examLobbyCleanup]', e);
    }
  }, LOBBY_PRESENCE_GRACE_MS);
  pendingLobbyRemoval.set(key, t);
}

function addExamSessionSocket(sessionId, userId, socketId) {
  const key = `${sessionId}::${userId}`;
  const pending = pendingLobbyRemoval.get(key);
  if (pending) {
    clearTimeout(pending);
    pendingLobbyRemoval.delete(key);
  }
  if (!examSessionSocketsByUser.has(key)) {
    examSessionSocketsByUser.set(key, new Set());
  }
  examSessionSocketsByUser.get(key).add(socketId);
}

/**
 * Drop a socket from a user's session set. When it's the LAST socket and [schedule]
 * is true (socket dropped), schedule the graced lobby cleanup. Explicit `leave_exam_session`
 * passes schedule:false because it already removed presence via `cleanupExamLeave`.
 */
function removeExamSessionSocket(sessionId, userId, socketId, { schedule = true } = {}) {
  const key = `${sessionId}::${userId}`;
  const set = examSessionSocketsByUser.get(key);
  if (set) {
    set.delete(socketId);
    if (set.size > 0) return; // another tab/socket still holds this user in the room
    examSessionSocketsByUser.delete(key);
  }
  if (schedule) scheduleLobbyPresenceCleanup(sessionId, userId);
}

const updateUserStatus = async (userId, isOnline) => {
  try {
    await User.findByIdAndUpdate(userId, {
      isOnline: isOnline,
      lastActivityDate: new Date(),
    });
    io.to('admin_room').emit('user_status_change', {
      userId: String(userId),
      isOnline,
    });
  } catch (error) {
    console.error(`Error updating status for ${userId}:`, error);
  }
};

const addUserSocket = async (userId, socketId) => {
  const key = String(userId);
  const pending = pendingOffline.get(key);
  if (pending) {
    clearTimeout(pending);
    pendingOffline.delete(key);
  }
  if (!onlineSocketIdsByUser.has(key)) {
    onlineSocketIdsByUser.set(key, new Set());
  }
  const set = onlineSocketIdsByUser.get(key);
  const wasOffline = set.size === 0;
  set.add(socketId);
  if (wasOffline) {
    await updateUserStatus(userId, true);
  }
};

const removeUserSocket = async (userId, socketId) => {
  const key = String(userId);
  const set = onlineSocketIdsByUser.get(key);
  if (!set) return;
  set.delete(socketId);
  if (set.size === 0) {
    onlineSocketIdsByUser.delete(key);
    const t = setTimeout(async () => {
      pendingOffline.delete(key);
      if (!onlineSocketIdsByUser.has(key)) {
        await updateUserStatus(userId, false);
      }
    }, OFFLINE_GRACE_MS);
    pendingOffline.set(key, t);
  }
};

/** HTTP logout / force offline — disconnect all sockets for user. */
export const setUserOfflineAndNotify = async (userId) => {
  if (!io) return;
  const key = String(userId);
  const pending = pendingOffline.get(key);
  if (pending) {
    clearTimeout(pending);
    pendingOffline.delete(key);
  }
  const set = onlineSocketIdsByUser.get(key);
  if (set) {
    for (const socketId of [...set]) {
      const sock = io.sockets.sockets.get(socketId);
      if (sock) {
        sock.userId = null;
        sock.disconnect(true);
      }
    }
    onlineSocketIdsByUser.delete(key);
  }
  await updateUserStatus(userId, false);
};

export const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  io.on('connection', (socket) => {
    console.log(`⚡ Client connected: ${socket.id}`);

    socket.on('user_login', async (userId) => {
      console.log(`👤 User Login: ${userId} (Socket: ${socket.id})`);
      socket.userId = String(userId);
      socket.join(String(userId));
      await addUserSocket(userId, socket.id);
    });

    socket.on('user_logout', async (payload) => {
      const userId = payload ? String(payload) : socket.userId;
      console.log(`👋 User Logout: ${userId} (Socket: ${socket.id})`);
      if (userId) {
        await removeUserSocket(userId, socket.id);
        socket.userId = null;
      }
    });

    socket.on('admin_join', () => {
      console.log(`🛡️ Admin joined: ${socket.id}`);
      socket.join('admin_room');
    });
    socket.on('join_listening_room', (listeningId) => {
      const roomName = `listening_${listeningId}`;
      socket.join(roomName);
      console.log(`🎧 Socket ${socket.id} joined room: ${roomName}`);
    });

    socket.on('leave_listening_room', (listeningId) => {
      const roomName = `listening_${listeningId}`;
      socket.leave(roomName);
      console.log(`🔇 Socket ${socket.id} left room: ${roomName}`);
    });

    socket.on('exam_register', (payload) => {
      const token = typeof payload === 'string' ? payload : payload?.accessToken;
      const v = verifyAccessToken(token || '');
      if (!v.valid || !v.userId) {
        socket.emit('exam_register_error', { message: 'Invalid or expired token' });
        socket.examUserId = null;
        return;
      }
      socket.examUserId = v.userId;
      socket.emit('exam_registered', { ok: true });
    });

    socket.on('join_exam_session', async ({ sessionId } = {}) => {
      try {
        if (!socket.examUserId) {
          socket.emit('exam_session_error', { message: 'Register exam token first (exam_register)' });
          return;
        }
        if (!sessionId) {
          socket.emit('exam_session_error', { message: 'sessionId required' });
          return;
        }
        const session = await ExamSession.findById(sessionId).populate('assignmentId');
        if (!session) {
          socket.emit('exam_session_error', { message: 'Session not found' });
          return;
        }
        const leader = session.leaderTeacherId.toString() === String(socket.examUserId);
        if (!leader) {
          await teacherExamAssignmentService.assertStudentEntitled(
            socket.examUserId,
            session.assignmentId._id.toString()
          );
        }
        socket.join(`examSession_${sessionId}`);
        const sid = String(sessionId);
        if (!socket.examSessionIds) socket.examSessionIds = new Set();
        socket.examSessionIds.add(sid);
        addExamSessionSocket(sid, String(socket.examUserId), socket.id);
        socket.emit('exam_session_joined', { sessionId });
        const { examSessionService } = await import('../services/examSessionService.js');
        await examSessionService.emitSessionStateBroadcast(sessionId);
      } catch (e) {
        socket.emit('exam_session_error', { message: e.message || 'Join failed' });
      }
    });

    const cleanupExamLeave = async (sessionId, userId) => {
      if (!sessionId || !userId) return;
      const sid = sessionId.toString();
      const uid = userId.toString();
      const { examSessionService } = await import('../services/examSessionService.js');
      await examSessionService.removeParticipantFromSession(sid, uid, {
        exitReason: 'disconnected',
      });
      await examSessionService.emitSessionStateBroadcast(sid);
    };

    socket.on('exam_session_set_ready', async ({ sessionId, ready } = {}) => {
      try {
        if (!socket.examUserId) {
          socket.emit('exam_session_error', { message: 'Register exam token first (exam_register)' });
          return;
        }
        if (!sessionId) {
          socket.emit('exam_session_error', { message: 'sessionId required' });
          return;
        }
        const { examSessionService } = await import('../services/examSessionService.js');
        await examSessionService.setParticipantReady(socket.examUserId, sessionId, ready === true);
      } catch (e) {
        socket.emit('exam_session_error', { message: e.message || 'Ready update failed' });
      }
    });

    // Teacher (session leader) sends a live reminder/warning that pops up on one
    // student's exam screen. Delivered to the student's personal room (user_login).
    socket.on('teacher_exam_warn_student', async ({ sessionId, studentUserId, message } = {}) => {
      try {
        if (!socket.examUserId) {
          socket.emit('exam_session_error', { message: 'Register exam token first (exam_register)' });
          return;
        }
        if (!sessionId || !studentUserId) {
          socket.emit('exam_session_error', { message: 'sessionId and studentUserId required' });
          return;
        }
        const text = typeof message === 'string' ? message.trim().slice(0, 500) : '';
        if (!text) {
          socket.emit('exam_session_error', { message: 'message required' });
          return;
        }
        const session = await ExamSession.findById(sessionId);
        if (!session) {
          socket.emit('exam_session_error', { message: 'Session not found' });
          return;
        }
        if (session.leaderTeacherId.toString() !== String(socket.examUserId)) {
          socket.emit('exam_session_error', { message: 'Only the session teacher can warn students' });
          return;
        }
        io.to(String(studentUserId)).emit('exam_session_warning', {
          sessionId: String(sessionId),
          studentUserId: String(studentUserId),
          message: text,
        });
      } catch (e) {
        socket.emit('exam_session_error', { message: e.message || 'Warn failed' });
      }
    });

    socket.on('join_exam_assignment_progress', async ({ assignmentId } = {}) => {
      try {
        if (!socket.examUserId) {
          socket.emit('exam_session_error', { message: 'Register exam token first (exam_register)' });
          return;
        }
        if (!assignmentId) {
          socket.emit('exam_session_error', { message: 'assignmentId required' });
          return;
        }
        await teacherExamAssignmentService.assertTeacherOwnsAssignment(socket.examUserId, assignmentId);
        socket.join(`examAssignment_${assignmentId}`);
        socket.emit('exam_assignment_progress_joined', { assignmentId });
      } catch (e) {
        socket.emit('exam_session_error', { message: e.message || 'Join failed' });
      }
    });

    socket.on('leave_exam_assignment_progress', ({ assignmentId } = {}) => {
      if (!assignmentId) return;
      socket.leave(`examAssignment_${assignmentId}`);
    });

    socket.on('exam_live_view_sync', async ({ attemptId, sessionId, liveView } = {}) => {
      try {
        if (!socket.examUserId) {
          socket.emit('exam_session_error', { message: 'Register exam token first (exam_register)' });
          return;
        }
        if (!attemptId) {
          socket.emit('exam_session_error', { message: 'attemptId required' });
          return;
        }
        const { examLiveMonitorService } = await import('../services/examLiveMonitorService.js');
        await examLiveMonitorService.syncLiveViewForStudent(
          socket.examUserId,
          attemptId,
          liveView && typeof liveView === 'object' ? liveView : {}
        );
      } catch (e) {
        socket.emit('exam_session_error', { message: e.message || 'Live view sync failed' });
      }
    });

    socket.on('leave_exam_session', async ({ sessionId } = {}) => {
      if (!sessionId) return;
      const sid = sessionId.toString();
      socket.leave(`examSession_${sid}`);
      socket.examSessionIds?.delete(sid);
      if (!socket.examUserId) return;
      // Explicit leave already removes presence below — just untrack, don't re-schedule.
      removeExamSessionSocket(sid, String(socket.examUserId), socket.id, { schedule: false });
      await cleanupExamLeave(sid, socket.examUserId);
    });

    // ── Classroom Group Chat ───────────────────────────────────────────────────
    socket.on('classroom_chat_join', ({ classroomId } = {}) => {
      if (!classroomId || !socket.userId) return;
      socket.join(`classroom_chat_${classroomId}`);
    });

    socket.on('classroom_chat_leave', ({ classroomId } = {}) => {
      if (!classroomId) return;
      socket.leave(`classroom_chat_${classroomId}`);
    });

    socket.on('classroom_chat_typing', async ({ classroomId, isTyping } = {}) => {
      if (!classroomId || !socket.userId) return;
      socket.to(`classroom_chat_${classroomId}`).emit('classroom_typing', {
        classroomId: String(classroomId),
        userId: String(socket.userId),
        isTyping: isTyping === true,
      });
      // Fanout "đang nhập…" cho danh sách inbox của mọi thành viên.
      try {
        const { emitInboxTyping } = await import('../services/classroomChatService.js');
        await emitInboxTyping(classroomId, socket.userId, isTyping === true);
      } catch (_) {}
    });
    // ─────────────────────────────────────────────────────────────────────────

    socket.on('disconnect', async (reason) => {
      console.log(`❌ Disconnected: ${socket.id} | Reason: ${reason}`);

      if (socket.userId) {
        console.log(`📉 Removing socket from online set: ${socket.userId}`);
        await removeUserSocket(socket.userId, socket.id);
      }

      // NOTE: read tracked session ids, NOT `socket.rooms` — by the time `disconnect`
      // fires, socket.io has already emptied `socket.rooms`, so the old room-derived
      // cleanup never ran and left ghost participants in the lobby (reload / kill app).
      if (socket.examUserId && socket.examSessionIds && socket.examSessionIds.size > 0) {
        for (const sid of socket.examSessionIds) {
          removeExamSessionSocket(sid, String(socket.examUserId), socket.id);
        }
      }
    });
  });
};

export const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized!');
  return io;
};
