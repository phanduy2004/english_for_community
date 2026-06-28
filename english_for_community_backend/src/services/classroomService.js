import crypto from 'crypto';
import { httpError } from '../utils/AppError.js';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import User from '../models/User.js';
import { cascadeDeleteService } from './cascadeDeleteService.js';
import { classroomActivityService } from './classroomActivityService.js';

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
    })
      .sort({ updatedAt: -1 })
      .lean();
    if (classrooms.length === 0) return [];
    const ids = classrooms.map((c) => c._id);
    const agg = await ClassroomMember.aggregate([
      { $match: { classroomId: { $in: ids }, status: 'active' } },
      { $group: { _id: '$classroomId', n: { $sum: 1 } } },
    ]);
    const countMap = Object.fromEntries(agg.map((x) => [String(x._id), x.n]));
    return classrooms.map((c) => {
      const j = { ...c, id: c._id.toString() };
      delete j.__v;
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
    const isOwner = teacherOid === userId.toString();
    const member = await ClassroomMember.findOne({
      classroomId,
      userId,
      status: 'active',
    });
    const isCoTeacher =
      member?.roleInClass === 'co_teacher' && member?.status === 'active';
    const isTeacher = isOwner || isCoTeacher;
    if (!isTeacher && !member) throw httpError(403, 'Not a member of this classroom');
    return { classroom, isTeacher, isOwner, isCoTeacher, member };
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

  async searchTeachersForCoTeacher(_requesterId, { q, limit = 10 } = {}) {
    const term = String(q || '').trim();
    if (term.length < 2) return [];
    const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(escaped, 'i');
    const cap = Math.min(Math.max(Number(limit) || 10, 1), 20);
    const users = await User.find({
      _destroy: { $ne: true },
      role: { $in: ['teacher', 'admin'] },
      $or: [{ username: regex }, { fullName: regex }, { email: regex }],
    })
      .select('fullName email username avatarUrl role')
      .sort({ username: 1 })
      .limit(cap)
      .lean();
    return users.map((u) => ({
      id: u._id.toString(),
      fullName: u.fullName || '',
      email: u.email || '',
      username: u.username || '',
      avatarUrl: u.avatarUrl || '',
      role: u.role || 'teacher',
    }));
  },

  async addCoTeacher(ownerId, classroomId, { email, username }) {
    const { classroom, isOwner } = await this.assertCanManageClassroom(ownerId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can add co-teachers');
    const usernameRaw = String(username || '').trim();
    let user;
    if (usernameRaw) {
      const escaped = usernameRaw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      user = await User.findOne({
        username: new RegExp(`^${escaped}$`, 'i'),
        _destroy: { $ne: true },
      });
      if (!user) throw httpError(404, 'Teacher not found');
    } else {
      const normalized = String(email || '').trim().toLowerCase();
      if (!normalized) throw httpError(400, 'username is required');
      user = await User.findOne({ email: normalized, _destroy: { $ne: true } });
      if (!user) throw httpError(404, 'Teacher not found');
    }
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
    if (member && member.status === 'pending' && member.roleInClass === 'co_teacher') {
      return member.populate('userId', 'fullName email username');
    }
    if (member && member.roleInClass === 'student') {
      throw httpError(400, 'User is already a student in this class');
    }
    if (!member) {
      member = await ClassroomMember.create({
        classroomId,
        userId: user._id,
        roleInClass: 'co_teacher',
        status: 'pending',
      });
    } else {
      member.roleInClass = 'co_teacher';
      member.status = 'pending';
      member.leftAt = null;
      await member.save();
    }
    try {
      const owner = await User.findById(ownerId).select('fullName username email');
      const { notifyCoTeacherInvite } = await import('./teacherNotificationHelper.js');
      await notifyCoTeacherInvite({
        coTeacherId: user._id,
        ownerId,
        classroomId,
        classroomName: classroom.name,
        memberId: member._id,
        ownerName: owner?.fullName || owner?.username || owner?.email,
      });
    } catch {
      /* optional */
    }
    await classroomActivityService.log({
      classroomId,
      actorId: ownerId,
      type: 'co_teacher_added',
      message: `Co-teacher invite sent: ${user.fullName || user.email}`,
      meta: { userId: user._id.toString(), pending: true },
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
    const classroom = await Classroom.findById(classroomId).select('name teacherId');
    const wasLinked = m.status === 'active' || m.status === 'pending';
    m.status = 'removed';
    m.leftAt = new Date();
    await m.save();
    if (wasLinked) {
      try {
        const { notifyCoTeacherRemoved } = await import('./teacherNotificationHelper.js');
        await notifyCoTeacherRemoved({
          coTeacherId: coTeacherUserId,
          ownerId,
          classroomId,
          classroomName: classroom?.name,
        });
      } catch {
        /* optional */
      }
    }
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
    const { isOwner } = await this.assertCanManageClassroom(teacherId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can archive');
    return cascadeDeleteService.softCascadeClassroom(classroomId);
  },

  async rotateInvite(teacherId, classroomId) {
    const { classroom, isOwner } = await this.assertCanManageClassroom(teacherId, classroomId);
    if (!isOwner) throw httpError(403, 'Only the class owner can rotate invite codes');
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
    try {
      const classroom = await Classroom.findById(classroomId).select('name teacherId');
      const { notifyStudentJoinApproved } = await import('./teacherNotificationHelper.js');
      await notifyStudentJoinApproved({
        studentId: studentUserId,
        teacherId,
        classroomId,
        classroomName: classroom?.name,
      });
    } catch {
      /* optional */
    }
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
    try {
      const classroom = await Classroom.findById(classroomId).select('name');
      const { notifyStudentJoinRejected } = await import('./teacherNotificationHelper.js');
      await notifyStudentJoinRejected({
        studentId: studentUserId,
        teacherId,
        classroomId,
        classroomName: classroom?.name,
      });
    } catch {
      /* optional */
    }
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

  /** Student self-leave — sets membership to removed (not teacher/co-teacher). */
  async leaveClassroom(userId, classroomId) {
    const { isTeacher } = await this.getByIdForUser(classroomId, userId);
    if (isTeacher) throw httpError(400, 'Teachers cannot leave as student');
    const m = await ClassroomMember.findOne({
      classroomId,
      userId,
      roleInClass: 'student',
      status: 'active',
    });
    if (!m) throw httpError(404, 'Not an active member');
    m.status = 'removed';
    m.leftAt = new Date();
    await m.save();
    return { ok: true };
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
