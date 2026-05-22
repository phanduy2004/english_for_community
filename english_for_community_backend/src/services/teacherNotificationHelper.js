import { createNotification } from './notificationService.js';

export async function notifyClassroomJoinRequest({ teacherId, studentId, classroomId, classroomName, studentName }) {
  if (!teacherId) return null;
  return createNotification({
    recipientId: teacherId,
    senderId: studentId,
    type: 'CLASSROOM_JOIN_REQUEST',
    title: 'New class join request',
    message: `${studentName || 'A student'} requested to join ${classroomName || 'your class'}`,
    data: {
      classroomId: String(classroomId),
      url: `/teacher/classroom/${classroomId}`,
    },
  });
}

export async function notifyStudentResultsReleased({ studentId, teacherId, examTitle, attemptId, assignmentId }) {
  if (!studentId) return null;
  return createNotification({
    recipientId: studentId,
    senderId: teacherId,
    type: 'EXAM_RESULTS_RELEASED',
    title: 'Exam results available',
    message: `Your results for "${examTitle || 'an exam'}" are ready to view`,
    data: {
      attemptId: String(attemptId),
      assignmentId: String(assignmentId),
      url: `/exams/attempts/${attemptId}`,
    },
  });
}
