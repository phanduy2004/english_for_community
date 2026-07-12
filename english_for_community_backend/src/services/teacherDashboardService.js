import mongoose from 'mongoose';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import { createTtlCache } from '../utils/ttlCache.js';
import { gradingAttentionMatch, teacherAnalyticsScope } from './teacherAnalyticsScope.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const gradingCountCache = createTtlCache(10_000);

const toObjectId = (id) =>
  id instanceof mongoose.Types.ObjectId ? id : new mongoose.Types.ObjectId(String(id));

async function getGradingQueue(teacherId, limit = 15) {
  const tid = toObjectId(teacherId);
  const docs = await ExamAttempt.aggregate([
    { $match: gradingAttentionMatch },
    {
      $lookup: {
        from: 'examassignments',
        localField: 'assignmentId',
        foreignField: '_id',
        as: 'assignment',
      },
    },
    { $unwind: '$assignment' },
    { $match: { 'assignment.teacherId': tid } },
    {
      $lookup: {
        from: 'users',
        localField: 'userId',
        foreignField: '_id',
        as: 'user',
      },
    },
    { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
    {
      $lookup: {
        from: 'exams',
        localField: 'assignment.examId',
        foreignField: '_id',
        as: 'exam',
      },
    },
    { $unwind: { path: '$exam', preserveNullAndEmptyArrays: true } },
    {
      $lookup: {
        from: 'classrooms',
        localField: 'assignment.classroomId',
        foreignField: '_id',
        as: 'classroom',
      },
    },
    { $unwind: { path: '$classroom', preserveNullAndEmptyArrays: true } },
    { $sort: { submittedAt: -1 } },
    { $limit: limit },
    {
      $project: {
        _id: 0,
        attemptId: { $toString: '$_id' },
        assignmentId: { $toString: '$assignmentId' },
        assignmentTitle: { $ifNull: ['$exam.title', 'Exam'] },
        classroomName: { $ifNull: ['$classroom.name', ''] },
        studentLabel: {
          $let: {
            vars: {
              name: { $trim: { input: { $ifNull: ['$user.fullName', ''] } } },
              email: { $trim: { input: { $ifNull: ['$user.email', ''] } } },
              username: { $trim: { input: { $ifNull: ['$user.username', ''] } } },
            },
            in: {
              $cond: [
                { $gt: [{ $strLenCP: '$$name' }, 0] },
                '$$name',
                {
                  $cond: [
                    { $gt: [{ $strLenCP: '$$email' }, 0] },
                    '$$email',
                    {
                      $cond: [
                        { $gt: [{ $strLenCP: '$$username' }, 0] },
                        '$$username',
                        'Student',
                      ],
                    },
                  ],
                },
              ],
            },
          },
        },
        gradingState: 1,
        resultsReleased: { $ifNull: ['$resultsReleased', false] },
        submittedAt: 1,
      },
    },
  ]);

  return docs.map((d) => ({
    ...d,
    submittedAt: d.submittedAt?.toISOString?.() ?? null,
  }));
}

async function countNeedsGrading(teacherId) {
  const cacheKey = String(teacherId);
  const cached = gradingCountCache.get(cacheKey);
  if (cached !== undefined) return cached;

  const tid = toObjectId(teacherId);
  const agg = await ExamAttempt.aggregate([
    { $match: gradingAttentionMatch },
    {
      $lookup: {
        from: 'examassignments',
        localField: 'assignmentId',
        foreignField: '_id',
        as: 'assignment',
      },
    },
    { $unwind: '$assignment' },
    { $match: { 'assignment.teacherId': tid } },
    { $count: 'total' },
  ]);
  const total = agg[0]?.total || 0;
  gradingCountCache.set(cacheKey, total);
  return total;
}

async function buildAttemptStatsByAssignment(assignmentIds) {
  if (!assignmentIds.length) return new Map();

  const rows = await ExamAttempt.aggregate([
    { $match: { assignmentId: { $in: assignmentIds } } },
    {
      $group: {
        _id: { assignmentId: '$assignmentId', status: '$status' },
        count: { $sum: 1 },
      },
    },
  ]);

  const map = new Map();
  for (const row of rows) {
    const aid = row._id.assignmentId.toString();
    if (!map.has(aid)) map.set(aid, { submitted: 0, inProgress: 0 });
    const bucket = map.get(aid);
    if (row._id.status === 'submitted') bucket.submitted = row.count;
    if (row._id.status === 'in_progress') bucket.inProgress = row.count;
  }
  return map;
}

export const teacherDashboardService = {
  async getActionItems(teacherId) {
    const classrooms = await Classroom.find({ teacherId, archived: false }).select('_id name');
    const classIds = classrooms.map((c) => c._id);

    const pendingMembers = classIds.length
      ? await ClassroomMember.find({ classroomId: { $in: classIds }, status: 'pending' })
          .populate('userId', 'fullName email')
          .populate('classroomId', 'name')
          .limit(50)
          .lean()
      : [];

    const assignments = await ExamAssignment.find({ teacherId, status: 'active' })
      .populate('examId', 'title')
      .populate('classroomId', 'name')
      .sort({ updatedAt: -1 })
      .limit(100)
      .lean();

    const assignmentIds = assignments.map((a) => a._id);
    const attemptStatsByAssignment = await buildAttemptStatsByAssignment(assignmentIds);

    const now = Date.now();
    const dueSoon = [];
    for (const a of assignments) {
      const due = a.config?.dueAt ? new Date(a.config.dueAt).getTime() : null;
      const closes = a.config?.closesAt ? new Date(a.config.closesAt).getTime() : null;
      const deadline = due ?? closes;
      if (deadline == null || deadline < now || deadline > now + 7 * DAY_MS) continue;
      const stats = attemptStatsByAssignment.get(a._id.toString()) || { submitted: 0, inProgress: 0 };
      dueSoon.push({
        assignmentId: a._id.toString(),
        examTitle: a.examId?.title || 'Exam',
        classroomName: a.classroomId?.name || null,
        deadline: new Date(deadline).toISOString(),
        submitted: stats.submitted,
        inProgress: stats.inProgress,
      });
    }
    dueSoon.sort((x, y) => new Date(x.deadline).getTime() - new Date(y.deadline).getTime());

    const [needsGradingCount, gradingQueue] = await Promise.all([
      countNeedsGrading(teacherId),
      getGradingQueue(teacherId, 15),
    ]);

    return {
      pendingJoins: pendingMembers.map((m) => ({
        classroomId: m.classroomId?._id?.toString() || m.classroomId?.toString(),
        classroomName: m.classroomId?.name || '',
        userId: m.userId?._id?.toString() || m.userId?.toString(),
        studentName: m.userId?.fullName || m.userId?.email || 'Student',
        requestedAt: m.createdAt?.toISOString?.() || null,
      })),
      dueSoon: dueSoon.slice(0, 20),
      needsGradingCount,
      gradingQueue,
    };
  },

  async getAnalyticsSummary(teacherId) {
    // Finding #8: scope GỒM cả lớp dạy-cùng — đồng bộ với teacherAnalyticsChartsService.
    const { classIds, assignments, assignmentIds } = await teacherAnalyticsScope(teacherId, '_id status');
    const activeAssignments = assignments.filter((a) => a.status === 'active').length;

    const attemptAgg = assignmentIds.length
      ? await ExamAttempt.aggregate([
          { $match: { assignmentId: { $in: assignmentIds } } },
          { $group: { _id: '$status', count: { $sum: 1 } } },
        ])
      : [];

    // Finding #6: "chờ chấm" dùng ĐỊNH NGHĨA CHUẨN (khớp inbox), không chỉ pending_manual.
    const pendingGradingCount = assignmentIds.length
      ? await ExamAttempt.countDocuments({
          assignmentId: { $in: assignmentIds },
          ...gradingAttentionMatch,
        })
      : 0;

    // Chỉ đếm HỌC SINH (trước đây thiếu roleInClass → gộp nhầm cả co_teacher vào activeStudentCount).
    const students = classIds.length
      ? await ClassroomMember.countDocuments({
          classroomId: { $in: classIds },
          status: 'active',
          roleInClass: 'student',
        })
      : 0;

    const byStatus = Object.fromEntries(attemptAgg.map((r) => [r._id, r.count]));
    return {
      classroomCount: classIds.length,
      activeStudentCount: students,
      totalAssignments: assignments.length,
      activeAssignments,
      pendingGradingCount,
      attempts: {
        submitted: byStatus.submitted || 0,
        inProgress: byStatus.in_progress || 0,
        total: Object.values(byStatus).reduce((s, n) => s + n, 0),
      },
    };
  },

  /** Calendar events from assignment schedules. Default window = 3 months. */
  async getCalendarEvents(teacherId, { from, to } = {}) {
    const now = new Date();
    const start = from ? new Date(from) : new Date(now.getFullYear(), now.getMonth(), 1);
    const end = to ? new Date(to) : new Date(start.getTime() + 90 * DAY_MS);

    const assignments = await ExamAssignment.find({ teacherId })
      .populate('examId', 'title')
      .populate('classroomId', 'name')
      .lean();

    const events = [];
    for (const a of assignments) {
      const examTitle = a.examId?.title || 'Exam';
      const classroomName = a.classroomId?.name || '';
      const classroomId = a.classroomId?._id?.toString() || String(a.classroomId ?? '');
      const examId = a.examId?._id?.toString() || String(a.examId ?? '');
      const label = classroomName ? `${examTitle} · ${classroomName}` : examTitle;
      const cfg = a.config || {};
      const base = {
        assignmentId: a._id.toString(),
        examId,
        classroomId,
        classroomName,
        title: label,
        examTitle,
        status: a.status,
        mode: a.mode,
      };

      const push = (kind, at) => {
        if (!at) return;
        const t = new Date(at).getTime();
        if (t < start.getTime() || t > end.getTime()) return;
        events.push({ ...base, kind, at: new Date(at).toISOString() });
      };

      push('opens', cfg.opensAt);
      push('due', cfg.dueAt);
      push('closes', cfg.closesAt);

      // Synthetic "live" event: assignment is currently open right now
      if (cfg.opensAt && cfg.closesAt) {
        const opensT = new Date(cfg.opensAt).getTime();
        const closesT = new Date(cfg.closesAt).getTime();
        const nowT = now.getTime();
        if (opensT <= nowT && nowT <= closesT) {
          // Anchor the live event at opensAt if it's in the range, else at now
          const liveAt = opensT >= start.getTime() ? new Date(cfg.opensAt) : now;
          if (liveAt.getTime() <= end.getTime()) {
            events.push({ ...base, kind: 'live', at: liveAt.toISOString() });
          }
        }
      }
    }
    events.sort((x, y) => new Date(x.at).getTime() - new Date(y.at).getTime());
    return { from: start.toISOString(), to: end.toISOString(), events };
  },
};
