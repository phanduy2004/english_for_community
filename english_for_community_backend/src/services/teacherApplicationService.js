import { z } from 'zod';
import { httpError } from '../utils/AppError.js';
import TeacherApplication from '../models/TeacherApplication.js';
import User from '../models/User.js';

const applicationPayloadSchema = z.object({
  bio: z.string().max(2000).optional().default(''),
  organization: z.string().max(500).optional().default(''),
  subjects: z.array(z.string().max(100)).max(20).optional().default([]),
  proofUrls: z.array(z.string().url()).max(10).optional().default([]),
});

const rejectBodySchema = z.object({
  reason: z.string().min(1).max(1000),
});

async function promoteUserToTeacher(userId, payload = {}, { source = 'application' } = {}) {
  const user = await User.findById(userId);
  if (!user || user._destroy) throw httpError(404, 'User not found');
  if (user.role === 'admin') throw httpError(400, 'Admins do not need teacher promotion');
  if (user.role === 'teacher') {
    const latest = await TeacherApplication.findOne({ userId }).sort({ createdAt: -1 });
    return { application: latest, user, alreadyTeacher: true };
  }

  const parsed = applicationPayloadSchema.parse(payload || {});
  if (parsed.bio) user.bio = String(parsed.bio).trim();

  user.role = 'teacher';
  await user.save();

  const pending = await TeacherApplication.findOne({ userId, status: 'pending' });
  if (pending) {
    pending.status = 'approved';
    pending.payload = { ...pending.payload, ...parsed };
    pending.review = {
      reviewerAdminId: null,
      decisionAt: new Date(),
      reason: source === 'register' ? 'Auto-approved at registration' : 'Auto-approved on submit',
    };
    await pending.save();
    return { application: pending, user, alreadyTeacher: false };
  }

  const doc = await TeacherApplication.create({
    userId,
    status: 'approved',
    payload: parsed,
    review: {
      reviewerAdminId: null,
      decisionAt: new Date(),
      reason: source === 'register' ? 'Auto-approved at registration' : 'Auto-approved on submit',
    },
  });
  return { application: doc, user, alreadyTeacher: false };
}

export const teacherApplicationService = {
  rejectBodySchema,
  promoteUserToTeacher,

  /** Học sinh đã có tài khoản → bật role teacher ngay (không chờ admin). */
  async createApplication(userId, body) {
    const { application, user, alreadyTeacher } = await promoteUserToTeacher(userId, body, {
      source: 'application',
    });
    if (alreadyTeacher) throw httpError(400, 'Already a teacher');
    return application;
  },

  async getMyLatest(userId) {
    const doc = await TeacherApplication.findOne({ userId }).sort({ createdAt: -1 });
    return doc;
  },

  async withdraw(userId) {
    const pending = await TeacherApplication.findOne({ userId, status: 'pending' });
    if (!pending) throw httpError(404, 'No pending application');
    pending.status = 'withdrawn';
    await pending.save();
    return pending;
  },

  async listForAdmin({ status = 'pending', page = 1, limit = 20 }) {
    const q = {};
    if (status) q.status = status;
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      TeacherApplication.find(q)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'fullName email username role avatarUrl'),
      TeacherApplication.countDocuments(q),
    ]);
    return { items, total, page, limit };
  },

  async approve(applicationId, adminId) {
    const app = await TeacherApplication.findById(applicationId);
    if (!app) throw httpError(404, 'Application not found');
    if (app.status !== 'pending') throw httpError(400, 'Application is not pending');

    const user = await User.findById(app.userId);
    if (!user) throw httpError(404, 'User not found');

    app.status = 'approved';
    app.review = {
      reviewerAdminId: adminId,
      decisionAt: new Date(),
      reason: '',
    };
    await app.save();

    user.role = 'teacher';
    await user.save();

    return { application: app, user };
  },

  async reject(applicationId, adminId, body) {
    const { reason } = rejectBodySchema.parse(body);
    const app = await TeacherApplication.findById(applicationId);
    if (!app) throw httpError(404, 'Application not found');
    if (app.status !== 'pending') throw httpError(400, 'Application is not pending');

    app.status = 'rejected';
    app.review = {
      reviewerAdminId: adminId,
      decisionAt: new Date(),
      reason,
    };
    await app.save();
    return app;
  },
};
