import crypto from 'crypto';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import User from '../models/User.js';
import { classroomActivityService } from './classroomActivityService.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

/** Works whether `teacherId` is an ObjectId or a populated User subdocument. */
function classroomTeacherIdString(classroom) {
  const t = classroom.teacherId;
  if (!t) return '';
  if (typeof t === 'object' && t._id) return t._id.toString();
  return t.toString();
}

const CODE_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

async function uniqueInviteCode() {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const bytes = crypto.randomBytes(8);
    let code = '';
    for (let i = 0; i < 6; i += 1) {
      code += CODE_CHARS[bytes[i] % CODE_CHARS.length];
    }
    const exists = await Classroom.findOne({ inviteCode: code });
    if (!exists) return code;
  }
  throw httpError(500, 'Could not generate invite code');
}

function uniqueInviteToken() {
  return crypto.randomBytes(24).toString('hex');
}

export const classroomService = {
  async assertTeacher(userId) {
    const user = await User.findById(userId);
    if (!user || user._destroy) throw httpError(404, 'User not found');
    if (user.role !== 'teacher' && user.role !== 'admin') {
      throw httpError(403, 'Teacher role required');
    }
    return user;
  },

  async createClassroom(teacherId, { name, description = '', joinPolicy = 'open' }) {
    await this.assertTeacher(teacherId);
    if (!name || !String(name).trim()) throw httpError(400, 'Name is required');

    const inviteCode = await uniqueInviteCode();
    const inviteToken = uniqueInviteToken();

    const classroom = await Classroom.create({
      teacherId,
      name: String(name).trim(),
      description: String(description || '').trim(),
      inviteCode,
      inviteToken,
      joinPolicy,
    });
    return classroom;
  },

  async assertCanManageClassroom(userId, classroomId) {
    const classroom = await Classroom.findById(classroomId);
    if (!classroom) throw httpError(404, 'Classroom not found');
    if (classroomTeacherIdString(classroom) === userId.toString()) {
      return { classroom, isOwner: true };
    }
    const co = await ClassroomMember.findOne({
      classroomId,
      userId,
      roleInClass: 'co_teacher',
      status: 'active',
    });
    if (co) return { classroom, isOwner: false };
    throw httpError(403, 'Forbidden');
  },

  async listMineAsTeacher(teacherId) {
    await this.assertTeacher(teacherId);
    const coMemberships = await ClassroomMember.find({
      userId: teacherId,
      roleInClass: 'co_teacher',
      status: 'active',
    }).select('classroomId');
    const coIds = coMemberships.map((m) => m.classroomId);
    const classrooms = await Classroom.find({
      archived: false,
      $or: [{ teacherId }, { _id: { $in: coIds } }],
    }).sort({ updatedAt: -1 });
    if (classrooms.length === 0) return [];
    const ids = classrooms.map((c) => c._id);
    const agg = await ClassroomMember.aggregate([
      { $match: { classroomId: { $in: ids }, status: 'active' } },
      { $group: { _id: '$classroomId', n: { $sum: 1 } } },
    ]);
    const countMap = Object.fromEntries(agg.map((x) => [String(x._id), x.n]));
    return classrooms.map((c) => {
      const j = c.toJSON();
      j.memberCountActive = countMap[String(c._id)] || 0;
      return j;
    });
  },

  async listEnrolledStudent(userId) {
    const memberships = await ClassroomMember.find({
      userId,
      status: 'active',
    }).populate({
      path: 'classroomId',
      match: { archived: false },
      populate: { path: 'teacherId', select: 'fullName username avatarUrl' },
    });
    return memberships.map((m) => m.classroomId).filter(Boolean);
  },

  async getByIdForUser(classroomId, userId) {
    const classroom = await Classroom.findById(classroomId).populate('teacherId', 'fullName email username avatarUrl');
    if (!classroom) throw httpError(404, 'Classroom not found');
    const teacherOid = classroomTeacherIdString(classroom);
    if (classroom.archived && teacherOid !== userId.toString()) {
      throw httpError(404, 'Classroom not found');
    }
    const isTeacher = teacherOid === userId.toString();
    const member = await ClassroomMember.findOne({
      classroomId,
      userId,
      status: 'active',
    });
    if (!isTeacher && !member) throw httpError(403, 'Not a member of this classroom');
    return { classroom, isTeacher, member };
  },

  /** Classroom JSON + member counts (for GET detail). */
  async getClassroomWithStats(classroomId, userId) {
    const { classroom } = await this.getByIdForUser(classroomId, userId);
    const j = classroom.toJSON();
    const active = await ClassroomMember.countDocuments({
      classroomId: classroom._id,
      status: 'active',
      roleInClass: 'student',
    });
    const pending = await ClassroomMember.countDocuments({ classroomId: classroom._id, status: 'pending' });
    j.memberCountActive = active;
    j.memberCountPending = pending;
    return j;
  },

  async addCoTeacher(ownerId, classroomId, { email }) {
    const { classroom, isOwner } = await this.assertCanManageClassroom(ownerId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can add co-teachers');
    const normalized = String(email || '').trim().toLowerCase();
    if (!normalized) throw httpError(400, 'email is required');
    const user = await User.findOne({ email: normalized, _destroy: { $ne: true } });
    if (!user) throw httpError(404, 'User not found');
    if (user.role !== 'teacher' && user.role !== 'admin') {
      throw httpError(400, 'Co-teacher must have teacher role');
    }
    if (user._id.toString() === classroomTeacherIdString(classroom)) {
      throw httpError(400, 'Owner is already the primary teacher');
    }
    let member = await ClassroomMember.findOne({ classroomId, userId: user._id });
    if (member && member.status === 'active' && member.roleInClass === 'co_teacher') {
      return member;
    }
    if (member && member.roleInClass === 'student') {
      throw httpError(400, 'User is already a student in this class');
    }
    if (!member) {
      member = await ClassroomMember.create({
        classroomId,
        userId: user._id,
        roleInClass: 'co_teacher',
        status: 'active',
      });
    } else {
      member.roleInClass = 'co_teacher';
      member.status = 'active';
      member.leftAt = null;
      await member.save();
    }
    await classroomActivityService.log({
      classroomId,
      actorId: ownerId,
      type: 'co_teacher_added',
      message: `Co-teacher added: ${user.fullName || user.email}`,
      meta: { userId: user._id.toString() },
    });
    return member.populate('userId', 'fullName email username');
  },

  async removeCoTeacher(ownerId, classroomId, coTeacherUserId) {
    const { isOwner } = await this.assertCanManageClassroom(ownerId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can remove co-teachers');
    const m = await ClassroomMember.findOne({
      classroomId,
      userId: coTeacherUserId,
      roleInClass: 'co_teacher',
    });
    if (!m) throw httpError(404, 'Co-teacher not found');
    m.status = 'removed';
    m.leftAt = new Date();
    await m.save();
    await classroomActivityService.log({
      classroomId,
      actorId: ownerId,
      type: 'co_teacher_removed',
      message: 'Co-teacher removed',
      meta: { userId: coTeacherUserId },
    });
    return m;
  },

  async updateClassroom(teacherId, classroomId, patch) {
    await this.assertCanManageClassroom(teacherId, classroomId);
    const classroom = await Classroom.findById(classroomId);
    if (!classroom) throw httpError(404, 'Classroom not found');
    if (patch.name != null) classroom.name = String(patch.name).trim();
    if (patch.description != null) classroom.description = String(patch.description);
    if (patch.joinPolicy != null) {
      if (!['open', 'approval_required'].includes(patch.joinPolicy)) throw httpError(400, 'Invalid joinPolicy');
      classroom.joinPolicy = patch.joinPolicy;
    }
    await classroom.save();
    return classroom;
  },

  async archive(teacherId, classroomId) {
    const { classroom, isOwner } = await this.assertCanManageClassroom(teacherId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can archive');
    classroom.archived = true;
    await classroom.save();
    return classroom;
  },

  async rotateInvite(teacherId, classroomId) {
    const classroom = await Classroom.findById(classroomId);
    if (!classroom) throw httpError(404, 'Classroom not found');
    if (classroom.teacherId.toString() !== teacherId.toString()) throw httpError(403, 'Forbidden');
    classroom.inviteCode = await uniqueInviteCode();
    classroom.inviteToken = uniqueInviteToken();
    await classroom.save();
    return classroom;
  },

  async listMembers(teacherId, classroomId) {
    await this.assertCanManageClassroom(teacherId, classroomId);
    return ClassroomMember.find({ classroomId, status: { $in: ['active', 'pending'] } }).populate(
      'userId',
      'fullName email username avatarUrl'
    );
  },

  async approveMember(teacherId, classroomId, studentUserId) {
    await this.assertCanManageClassroom(teacherId, classroomId);
    const m = await ClassroomMember.findOne({ classroomId, userId: studentUserId });
    if (!m) throw httpError(404, 'Member not found');
    if (m.status !== 'pending') throw httpError(400, 'Member is not pending approval');
    m.status = 'active';
    m.leftAt = null;
    m.joinedAt = new Date();
    await m.save();
    await classroomActivityService.log({
      classroomId,
      actorId: teacherId,
      type: 'member_approved',
      message: 'Student join approved',
      meta: { userId: studentUserId },
    });
    return m;
  },

  async rejectMember(teacherId, classroomId, studentUserId) {
    await this.assertCanManageClassroom(teacherId, classroomId);
    const m = await ClassroomMember.findOne({ classroomId, userId: studentUserId });
    if (!m) throw httpError(404, 'Member not found');
    if (m.status !== 'pending') throw httpError(400, 'Member is not pending approval');
    m.status = 'removed';
    m.leftAt = new Date();
    await m.save();
    return m;
  },

  async removeMember(teacherId, classroomId, studentUserId) {
    await this.assertCanManageClassroom(teacherId, classroomId);
    const m = await ClassroomMember.findOne({ classroomId, userId: studentUserId });
    if (!m) throw httpError(404, 'Member not found');
    m.status = 'removed';
    m.leftAt = new Date();
    await m.save();
    return m;
  },

  async joinByCode(userId, inviteCode) {
    const code = String(inviteCode || '').trim().toUpperCase();
    const classroom = await Classroom.findOne({ inviteCode: code, archived: false });
    if (!classroom) throw httpError(404, 'Invalid invite code');
    return this._joinClassroom(userId, classroom);
  },

  async joinByToken(userId, token) {
    const classroom = await Classroom.findOne({ inviteToken: String(token || '').trim(), archived: false });
    if (!classroom) throw httpError(404, 'Invalid invite link');
    return this._joinClassroom(userId, classroom);
  },

  async _joinClassroom(userId, classroom) {
    if (classroom.teacherId.toString() === userId.toString()) {
      throw httpError(400, 'Teacher cannot join own classroom as student');
    }

    let member = await ClassroomMember.findOne({ classroomId: classroom._id, userId });
    if (member && member.status === 'active') {
      return { classroom, member, alreadyMember: true };
    }

    if (classroom.joinPolicy === 'approval_required') {
      if (!member) {
        member = await ClassroomMember.create({
          classroomId: classroom._id,
          userId,
          status: 'pending',
        });
      } else {
        member.status = 'pending';
        member.leftAt = null;
        await member.save();
      }
      try {
        const student = await User.findById(userId).select('fullName email');
        const { notifyClassroomJoinRequest } = await import('./teacherNotificationHelper.js');
        await notifyClassroomJoinRequest({
          teacherId: classroom.teacherId,
          studentId: userId,
          classroomId: classroom._id,
          classroomName: classroom.name,
          studentName: student?.fullName || student?.email,
        });
      } catch {
        /* optional notification */
      }
      return { classroom, member, pendingApproval: true };
    }

    if (!member) {
      member = await ClassroomMember.create({
        classroomId: classroom._id,
        userId,
        status: 'active',
      });
    } else {
      member.status = 'active';
      member.leftAt = null;
      member.joinedAt = new Date();
      await member.save();
    }
    return { classroom, member, pendingApproval: false };
  },
};
