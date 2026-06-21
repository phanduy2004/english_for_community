/**
 * Soft-cascade khi xoá Exam / Assignment / Classroom — tránh orphan (D3).
 * Expand-contract: set deletedAt + _destroy, không hard-delete.
 */
import Classroom from '../models/Classroom.js';
import Exam from '../models/Exam.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ClassroomMessage from '../models/ClassroomMessage.js';
import ClassroomActivityLog from '../models/ClassroomActivityLog.js';
import ClassroomChatReadState from '../models/ClassroomChatReadState.js';
import Notification from '../models/Notification.js';
import { softSetMany } from '../lib/mongoosePlugins.js';

function nowSet() {
  return { deletedAt: new Date(), _destroy: true };
}

export const cascadeDeleteService = {
  async softCascadeAssignment(assignmentId) {
    const aid = assignmentId;
    await softSetMany(ExamAttempt, { assignmentId: aid });
    await softSetMany(ExamSession, { assignmentId: aid });
    return softSetMany(ExamAssignment, { _id: aid });
  },

  async softCascadeExam(examId) {
    const assignments = await ExamAssignment.find({ examId })
      .select('_id')
      .setOptions({ includeDeleted: true });
    for (const a of assignments) {
      await this.softCascadeAssignment(a._id);
    }
    return Exam.findByIdAndUpdate(examId, { $set: { ...nowSet(), status: 'archived' } }, { new: true });
  },

  async softCascadeClassroom(classroomId) {
    const cid = classroomId;
    const assignments = await ExamAssignment.find({ classroomId: cid, audience: 'classroom' }).select('_id');
    for (const a of assignments) {
      await this.softCascadeAssignment(a._id);
    }
    await softSetMany(ClassroomMember, { classroomId: cid });
    await softSetMany(ClassroomMessage, { classroomId: cid });
    await softSetMany(ClassroomActivityLog, { classroomId: cid });
    await softSetMany(ClassroomChatReadState, { classroomId: cid });
    return Classroom.findByIdAndUpdate(
      cid,
      { $set: { ...nowSet(), archived: true } },
      { new: true }
    );
  },

  async softCascadeUser(userId) {
    await softSetMany(Notification, { recipientId: userId });
    await softSetMany(Notification, { senderId: userId });
    return null;
  },
};
