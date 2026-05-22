import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';

const DAY_MS = 24 * 60 * 60 * 1000;

export const teacherDashboardService = {
  async getActionItems(teacherId) {
    const classrooms = await Classroom.find({ teacherId, archived: false }).select('_id name');
    const classIds = classrooms.map((c) => c._id);

    const pendingMembers = classIds.length
      ? await ClassroomMember.find({ classroomId: { $in: classIds }, status: 'pending' })
          .populate('userId', 'fullName email')
          .populate('classroomId', 'name')
          .limit(50)
      : [];

    const assignments = await ExamAssignment.find({ teacherId, status: 'active' })
      .populate('examId', 'title')
      .populate('classroomId', 'name')
      .sort({ updatedAt: -1 })
      .limit(100);

    const now = Date.now();
    const dueSoon = [];
    for (const a of assignments) {
      const due = a.config?.dueAt ? new Date(a.config.dueAt).getTime() : null;
      const closes = a.config?.closesAt ? new Date(a.config.closesAt).getTime() : null;
      const deadline = due ?? closes;
      if (deadline == null || deadline < now || deadline > now + 7 * DAY_MS) continue;
      const stats = await ExamAttempt.aggregate([
        { $match: { assignmentId: a._id } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]);
      const submitted = stats.find((s) => s._id === 'submitted')?.count || 0;
      const inProgress = stats.find((s) => s._id === 'in_progress')?.count || 0;
      dueSoon.push({
        assignmentId: a._id.toString(),
        examTitle: a.examId?.title || 'Exam',
        classroomName: a.classroomId?.name || null,
        deadline: new Date(deadline).toISOString(),
        submitted,
        inProgress,
      });
    }
    dueSoon.sort((x, y) => new Date(x.deadline).getTime() - new Date(y.deadline).getTime());

    const needsGradingAgg = await ExamAttempt.aggregate([
      {
        $lookup: {
          from: 'examassignments',
          localField: 'assignmentId',
          foreignField: '_id',
          as: 'assignment',
        },
      },
      { $unwind: '$assignment' },
      { $match: { 'assignment.teacherId': teacherId, status: 'submitted', gradingState: { $ne: 'finalized' } } },
      { $count: 'total' },
    ]);
    const needsGradingCount = needsGradingAgg[0]?.total || 0;

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
    };
  },

  async getAnalyticsSummary(teacherId) {
    const assignments = await ExamAssignment.find({ teacherId }).select('_id status audience');
    const assignmentIds = assignments.map((a) => a._id);
    const activeAssignments = assignments.filter((a) => a.status === 'active').length;

    const attemptAgg = assignmentIds.length
      ? await ExamAttempt.aggregate([
          { $match: { assignmentId: { $in: assignmentIds } } },
          { $group: { _id: '$status', count: { $sum: 1 } } },
        ])
      : [];

    const pendingGradingCount = assignmentIds.length
      ? await ExamAttempt.countDocuments({
          assignmentId: { $in: assignmentIds },
          gradingState: 'pending_manual',
        })
      : 0;

    const classrooms = await Classroom.countDocuments({ teacherId, archived: false });
    const classroomIds = (await Classroom.find({ teacherId, archived: false }).select('_id')).map(
      (c) => c._id
    );
    const students = classroomIds.length
      ? await ClassroomMember.countDocuments({
          classroomId: { $in: classroomIds },
          status: 'active',
        })
      : 0;

    const byStatus = Object.fromEntries(attemptAgg.map((r) => [r._id, r.count]));
    return {
      classroomCount: classrooms,
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
      .populate('classroomId', 'name');

    const events = [];
    for (const a of assignments) {
      const examTitle = a.examId?.title || 'Exam';
      const classroomName = a.classroomId?.name || '';
      const classroomId = a.classroomId?._id?.toString() || '';
      const examId = a.examId?._id?.toString() || '';
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
