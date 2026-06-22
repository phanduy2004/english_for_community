import ClassroomActivityLog from '../models/ClassroomActivityLog.js';
import { httpError } from '../utils/AppError.js';
import { classroomService } from './classroomService.js';

export const classroomActivityService = {
  async log({ classroomId, actorId = null, type, message = '', meta = {} }) {
    if (!classroomId || !type) return null;
    return ClassroomActivityLog.create({
      classroomId,
      actorId,
      type,
      message: String(message).slice(0, 500),
      meta,
    });
  },

  async listForClassroom(userId, classroomId, { limit = 50 } = {}) {
    await classroomService.assertCanManageClassroom(userId, classroomId);
    const rows = await ClassroomActivityLog.find({ classroomId })
      .sort({ createdAt: -1 })
      .limit(Math.min(100, limit))
      .populate('actorId', 'fullName email username');
    return rows;
  },
};
