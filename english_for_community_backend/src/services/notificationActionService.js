import mongoose from 'mongoose';
import Notification from '../models/Notification.js';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import { classroomService } from './classroomService.js';
import {
  notifyCoTeacherInviteAccepted,
  notifyCoTeacherInviteDeclined,
} from './teacherNotificationHelper.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

function actionPending(data) {
  const status = data?.actionStatus;
  return !status || status === 'pending';
}

async function markNotificationResolved(notification, actionStatus) {
  const data = {
    ...(notification.data && typeof notification.data === 'object' ? notification.data : {}),
    actionStatus,
    actionable: false,
  };
  notification.data = data;
  notification.isRead = true;
  await notification.save();
  return notification;
}

async function handleCoTeacherInvite(recipientId, notification, action) {
  const memberId = notification.data?.memberId;
  const classroomId = notification.data?.classroomId;
  if (!memberId || !classroomId) throw httpError(400, 'Invalid invite payload');

  const member = await ClassroomMember.findById(memberId);
  if (!member || member.roleInClass !== 'co_teacher') {
    throw httpError(404, 'Invite no longer valid');
  }
  if (member.userId.toString() !== recipientId.toString()) {
    throw httpError(403, 'Forbidden');
  }
  if (member.status !== 'pending') {
    throw httpError(400, 'Invite already handled');
  }

  const classroom = await Classroom.findById(classroomId).populate('teacherId', 'fullName');
  if (!classroom) throw httpError(404, 'Classroom not found');

  const ownerId = classroom.teacherId?._id?.toString() || classroom.teacherId?.toString();

  if (action === 'accept') {
    member.status = 'active';
    member.leftAt = null;
    member.joinedAt = new Date();
    await member.save();
    await markNotificationResolved(notification, 'accepted');
    await notifyCoTeacherInviteAccepted({
      ownerId,
      coTeacherId: recipientId,
      classroomId,
      classroomName: classroom.name,
    });
    return { ok: true, action: 'accept', classroomId: String(classroomId) };
  }

  if (action === 'decline') {
    member.status = 'removed';
    member.leftAt = new Date();
    await member.save();
    await markNotificationResolved(notification, 'declined');
    await notifyCoTeacherInviteDeclined({
      ownerId,
      coTeacherId: recipientId,
      classroomId,
      classroomName: classroom.name,
    });
    return { ok: true, action: 'decline' };
  }

  throw httpError(400, 'Invalid action');
}

async function handleClassroomJoinRequest(recipientId, notification, action) {
  const classroomId = notification.data?.classroomId;
  const studentId = notification.data?.studentId;
  if (!classroomId || !studentId) throw httpError(400, 'Invalid join request payload');

  const classroom = await Classroom.findById(classroomId);
  if (!classroom) throw httpError(404, 'Classroom not found');
  await classroomService.assertCanManageClassroom(recipientId, classroomId);

  if (action === 'accept') {
    await classroomService.approveMember(recipientId, classroomId, studentId);
    await markNotificationResolved(notification, 'accepted');
    return { ok: true, action: 'accept', classroomId: String(classroomId) };
  }
  if (action === 'decline') {
    await classroomService.rejectMember(recipientId, classroomId, studentId);
    await markNotificationResolved(notification, 'declined');
    return { ok: true, action: 'decline', classroomId: String(classroomId) };
  }
  throw httpError(400, 'Invalid action');
}

export const notificationActionService = {
  async respond(userId, notificationId, action) {
    const normalized = String(action || '').trim().toLowerCase();
    if (!['accept', 'decline'].includes(normalized)) {
      throw httpError(400, 'action must be accept or decline');
    }
    if (!mongoose.Types.ObjectId.isValid(notificationId)) {
      throw httpError(400, 'Invalid notification id');
    }

    const notification = await Notification.findOne({
      _id: notificationId,
      recipientId: userId,
    });
    if (!notification) throw httpError(404, 'Notification not found');
    if (!actionPending(notification.data)) {
      throw httpError(400, 'This notification was already handled');
    }

    switch (notification.type) {
      case 'CO_TEACHER_INVITE':
        return handleCoTeacherInvite(userId, notification, normalized);
      case 'CLASSROOM_JOIN_REQUEST':
        return handleClassroomJoinRequest(userId, notification, normalized);
      default:
        throw httpError(400, 'This notification cannot be answered from here');
    }
  },
};
