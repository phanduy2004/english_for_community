import { z } from 'zod';
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

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

export const teacherApplicationService = {
  rejectBodySchema,

  async createApplication(userId, body) {
    const user = await User.findById(userId);
    if (!user || user._destroy) throw httpError(404, 'User not found');
    if (user.role === 'teacher') throw httpError(400, 'Already a teacher');
    if (user.role === 'admin') throw httpError(400, 'Admins do not need teacher applications');

    const pending = await TeacherApplication.findOne({ userId, status: 'pending' });
    if (pending) throw httpError(409, 'You already have a pending application');

    const payload = applicationPayloadSchema.parse(body || {});

    const doc = await TeacherApplication.create({
      userId,
      status: 'pending',
      payload,
    });
    return doc;
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
