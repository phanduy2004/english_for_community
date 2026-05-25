import mongoose from 'mongoose';
import ClassroomMember from '../models/ClassroomMember.js';
import User from '../models/User.js';
import { createNotification } from './notificationService.js';

async function activeStudentIdsInClassroom(classroomId, { excludeUserId } = {}) {
  const cid =
    classroomId instanceof mongoose.Types.ObjectId
      ? classroomId
      : new mongoose.Types.ObjectId(String(classroomId));
  const members = await ClassroomMember.find({
    classroomId: cid,
    status: 'active',
    roleInClass: 'student',
  })
    .select('userId')
    .lean();
  const exclude = excludeUserId ? String(excludeUserId) : null;
  return members.map((m) => String(m.userId)).filter((id) => id !== exclude);
}

async function notifyRecipients({ recipientIds, senderId, type, title, message, data }) {
  const unique = [...new Set(recipientIds.map(String).filter(Boolean))];
  const sent = [];
  for (const recipientId of unique) {
    const doc = await createNotification({
      recipientId,
      senderId,
      type,
      title,
      message,
      data: { ...(data || {}), type },
    });
    if (doc) sent.push(doc);
  }
  return sent;
}

export async function notifyClassroomJoinRequest({
  teacherId,
  studentId,
  classroomId,
  classroomName,
  studentName,
}) {
  if (!teacherId) return null;
  return createNotification({
    recipientId: teacherId,
    senderId: studentId,
    type: 'CLASSROOM_JOIN_REQUEST',
    title: 'New class join request',
    message: `${studentName || 'A student'} requested to join ${classroomName || 'your class'}`,
    data: {
      type: 'CLASSROOM_JOIN_REQUEST',
      classroomId: String(classroomId),
      url: `/teacher/classroom/${classroomId}`,
    },
  });
}

export async function notifyStudentJoinApproved({ studentId, teacherId, classroomId, classroomName }) {
  if (!studentId) return null;
  return createNotification({
    recipientId: studentId,
    senderId: teacherId,
    type: 'CLASSROOM_JOIN_APPROVED',
    title: 'Joined class',
    message: `You were approved to join ${classroomName || 'the class'}`,
    data: {
      type: 'CLASSROOM_JOIN_APPROVED',
      classroomId: String(classroomId),
      url: `/student/classroom/${classroomId}`,
    },
  });
}

export async function notifyStudentJoinRejected({ studentId, teacherId, classroomId, classroomName }) {
  if (!studentId) return null;
  return createNotification({
    recipientId: studentId,
    senderId: teacherId,
    type: 'CLASSROOM_JOIN_REJECTED',
    title: 'Join request declined',
    message: `Your request to join ${classroomName || 'the class'} was not approved`,
    data: {
      type: 'CLASSROOM_JOIN_REJECTED',
      classroomId: String(classroomId),
    },
  });
}

export async function notifyStudentsExamAssigned({
  teacherId,
  classroomId,
  assignmentId,
  examTitle,
  classroomName,
}) {
  const recipientIds = await activeStudentIdsInClassroom(classroomId, { excludeUserId: teacherId });
  if (!recipientIds.length) {
    console.warn(
      `[Notify] EXAM_ASSIGNED: no active students in classroom ${classroomId} (check ClassroomMember status/role)`
    );
    return [];
  }
  return notifyRecipients({
    recipientIds,
    senderId: teacherId,
    type: 'EXAM_ASSIGNED',
    title: 'New assignment',
    message: `"${examTitle || 'Exam'}" was assigned in ${classroomName || 'your class'}`,
    data: {
      classroomId: String(classroomId),
      assignmentId: String(assignmentId),
      examTitle: examTitle || '',
      classroomName: classroomName || '',
    },
  });
}

export async function notifyStudentsExamAssignmentUpdated({
  teacherId,
  classroomId,
  assignmentId,
  examTitle,
  classroomName,
}) {
  const recipientIds = await activeStudentIdsInClassroom(classroomId, { excludeUserId: teacherId });
  if (!recipientIds.length) return [];
  return notifyRecipients({
    recipientIds,
    senderId: teacherId,
    type: 'EXAM_ASSIGNMENT_UPDATED',
    title: 'Assignment updated',
    message: `"${examTitle || 'Exam'}" schedule or settings changed in ${classroomName || 'your class'}`,
    data: {
      classroomId: String(classroomId),
      assignmentId: String(assignmentId),
      examTitle: examTitle || '',
    },
  });
}

export async function notifyStudentsExamAssignmentClosed({
  teacherId,
  classroomId,
  assignmentId,
  examTitle,
  classroomName,
}) {
  const recipientIds = await activeStudentIdsInClassroom(classroomId, { excludeUserId: teacherId });
  if (!recipientIds.length) return [];
  return notifyRecipients({
    recipientIds,
    senderId: teacherId,
    type: 'EXAM_ASSIGNMENT_CLOSED',
    title: 'Assignment closed',
    message: `"${examTitle || 'Exam'}" is no longer open in ${classroomName || 'your class'}`,
    data: {
      classroomId: String(classroomId),
      assignmentId: String(assignmentId),
      examTitle: examTitle || '',
    },
  });
}

export async function notifyStudentsExamSessionLive({
  teacherId,
  classroomId,
  assignmentId,
  sessionId,
  examTitle,
  recipientIds,
}) {
  let ids = recipientIds;
  if (!ids?.length && classroomId) {
    ids = await activeStudentIdsInClassroom(classroomId, { excludeUserId: teacherId });
  }
  if (!ids?.length) return [];
  return notifyRecipients({
    recipientIds: ids,
    senderId: teacherId,
    type: 'EXAM_SESSION_LIVE',
    title: 'Live exam started',
    message: `Join now: "${examTitle || 'Exam'}" is live`,
    data: {
      classroomId: classroomId ? String(classroomId) : '',
      assignmentId: String(assignmentId),
      sessionId: String(sessionId),
      examTitle: examTitle || '',
    },
  });
}

export async function notifyTeacherExamSubmission({
  teacherId,
  studentId,
  studentName,
  assignmentId,
  attemptId,
  examTitle,
  classroomId,
}) {
  if (!teacherId) return null;
  const data = {
    type: 'EXAM_SUBMISSION_RECEIVED',
    assignmentId: String(assignmentId),
    attemptId: String(attemptId),
    examTitle: examTitle || '',
    studentName: studentName || '',
  };
  if (classroomId) {
    data.classroomId = String(classroomId);
    data.url = `/teacher/classroom/${classroomId}`;
  } else {
    data.url = `/teacher/exam-grading/${assignmentId}`;
  }
  return createNotification({
    recipientId: teacherId,
    senderId: studentId,
    type: 'EXAM_SUBMISSION_RECEIVED',
    title: 'New submission',
    message: `${studentName || 'A student'} submitted "${examTitle || 'an exam'}"`,
    data,
  });
}

export async function notifyStudentResultsReleased({
  studentId,
  teacherId,
  examTitle,
  attemptId,
  assignmentId,
  classroomId,
}) {
  if (!studentId) return null;
  return createNotification({
    recipientId: studentId,
    senderId: teacherId,
    type: 'EXAM_RESULTS_RELEASED',
    title: 'Exam results available',
    message: `Your results for "${examTitle || 'an exam'}" are ready to view`,
    data: {
      type: 'EXAM_RESULTS_RELEASED',
      attemptId: String(attemptId),
      assignmentId: String(assignmentId),
      classroomId: classroomId ? String(classroomId) : '',
      examTitle: examTitle || '',
      url: `/student/exam-run/${attemptId}`,
    },
  });
}

/** Load display names for assignment notifications. */
export async function assignmentNotificationContext(assignment) {
  const examTitle =
    assignment.examId?.title ||
    (typeof assignment.examId === 'object' ? assignment.examId?.title : null) ||
    'Exam';
  const classroomName =
    assignment.classroomId?.name ||
    (typeof assignment.classroomId === 'object' ? assignment.classroomId?.name : null) ||
    '';
  return { examTitle, classroomName };
}

export async function studentDisplayName(userId) {
  const u = await User.findById(userId).select('fullName username email').lean();
  return u?.fullName || u?.username || u?.email || 'A student';
}
