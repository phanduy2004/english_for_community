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
      if (!socket.examUserId) return;
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

    socket.on('classroom_chat_typing', ({ classroomId, isTyping } = {}) => {
      if (!classroomId || !socket.userId) return;
      socket.to(`classroom_chat_${classroomId}`).emit('classroom_typing', {
        classroomId: String(classroomId),
        userId: String(socket.userId),
        isTyping: isTyping === true,
      });
    });
    // ─────────────────────────────────────────────────────────────────────────

    socket.on('disconnect', async (reason) => {
      console.log(`❌ Disconnected: ${socket.id} | Reason: ${reason}`);

      if (socket.userId) {
        console.log(`📉 Removing socket from online set: ${socket.userId}`);
        await removeUserSocket(socket.userId, socket.id);
      }

      if (socket.examUserId) {
        const rooms = [...socket.rooms].filter((r) => String(r).startsWith('examSession_'));
        const sessionIds = rooms.map((r) => String(r).replace('examSession_', ''));
        if (sessionIds.length > 0) {
          for (const sid of sessionIds) {
            await cleanupExamLeave(sid, socket.examUserId);
          }
        }
      }
    });
  });
};

export const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized!');
  return io;
};
