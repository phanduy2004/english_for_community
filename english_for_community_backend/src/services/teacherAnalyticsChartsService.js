import mongoose from 'mongoose';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';

const DAY_MS = 24 * 60 * 60 * 1000;

async function classroomIdsForTeacher(teacherId) {
  const owned = await Classroom.find({ teacherId, archived: false }).select('_id');
  const co = await ClassroomMember.find({
    userId: teacherId,
    roleInClass: 'co_teacher',
    status: 'active',
  }).select('classroomId');
  const ids = new Set(owned.map((c) => c._id.toString()));
  for (const m of co) ids.add(m.classroomId.toString());
  return [...ids].map((id) => new mongoose.Types.ObjectId(id));
}

function trendPct(current, prev) {
  if (prev === 0 && current === 0) return 0;
  if (prev === 0) return 100;
  return Math.round(((current - prev) / prev) * 100 * 10) / 10;
}

export const teacherAnalyticsChartsService = {
  async getCharts(teacherId, { days = 14 } = {}) {
    const nDays = Math.min(30, Math.max(7, Number(days) || 14));
    const now = Date.now();
    const since = new Date(now - nDays * DAY_MS);
    const prevSince = new Date(now - nDays * 2 * DAY_MS);

    const assignments = await ExamAssignment.find({
      $or: [{ teacherId }, { teacherId: new mongoose.Types.ObjectId(teacherId) }],
    }).select('_id examId mode status classroomId');
    const assignmentIds = assignments.map((a) => a._id);

    // ── Submissions per day ──────────────────────────────────────────────────
    const submissionsByDay = await ExamAttempt.aggregate([
      {
        $match: {
          assignmentId: { $in: assignmentIds },
          status: 'submitted',
          submittedAt: { $gte: since },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$submittedAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Fill gaps so every day in the range has a bar (even 0)
    const dayMap = Object.fromEntries(submissionsByDay.map((r) => [r._id, r.count]));
    const filledDays = [];
    for (let d = 0; d < nDays; d++) {
      const dt = new Date(since.getTime() + d * DAY_MS);
      const key = dt.toISOString().slice(0, 10);
      filledDays.push({ date: key, count: dayMap[key] ?? 0 });
    }

    // ── Score distribution (10-scale integrated + legacy pct buckets) ───────
    const integratedAttempts = await ExamAttempt.find({
      assignmentId: { $in: assignmentIds },
      status: 'submitted',
      'scores.examFormat': { $exists: true },
      'scores.finalScore': { $ne: null },
    }).select('scores.finalScore');

    let scoreDistribution;
    if (integratedAttempts.length > 0) {
      const buckets = [0, 0, 0, 0, 0]; // 0-2, 2-4, 4-6, 6-8, 8-10
      for (const a of integratedAttempts) {
        const s = a.scores?.finalScore ?? 0;
        const idx = Math.min(4, Math.floor(s / 2));
        buckets[idx]++;
      }
      const labels = ['0–2', '2–4', '4–6', '6–8', '8–10'];
      scoreDistribution = labels.map((range, i) => ({ range, count: buckets[i] }));
    } else {
      const scoreBuckets = await ExamAttempt.aggregate([
        {
          $match: {
            assignmentId: { $in: assignmentIds },
            status: 'submitted',
            'scores.totalMax': { $gt: 0 },
          },
        },
        {
          $project: {
            pct: {
              $multiply: [{ $divide: ['$scores.totalAwarded', '$scores.totalMax'] }, 100],
            },
          },
        },
        {
          $bucket: {
            groupBy: '$pct',
            boundaries: [0, 50, 70, 85, 100.01],
            default: 'other',
            output: { count: { $sum: 1 } },
          },
        },
      ]);
      const bucketLabel = { 0: '<50%', 50: '50–70%', 70: '70–85%', 85: '≥85%' };
      scoreDistribution = scoreBuckets.map((b) => ({
        range: bucketLabel[b._id] ?? String(b._id),
        count: b.count,
      }));
    }

    // ── Per-skill average for integrated exams ───────────────────────────────
    const skillNames = ['listening', 'reading', 'writing', 'speaking', 'grammar'];
    const skillSums = Object.fromEntries(skillNames.map((k) => [k, { sum: 0, count: 0 }]));

    const integratedWithSkills = await ExamAttempt.find({
      assignmentId: { $in: assignmentIds },
      status: 'submitted',
      'scores.skillScores': { $exists: true },
      submittedAt: { $gte: since },
    }).select('scores.skillScores');

    for (const a of integratedWithSkills) {
      const ss = a.scores?.skillScores ?? {};
      for (const skill of skillNames) {
        const entry = ss[skill];
        if (entry?.status === 'finalized' && entry.score != null) {
          skillSums[skill].sum += entry.score;
          skillSums[skill].count++;
        }
      }
    }

    const skillScoreAvg = {};
    for (const skill of skillNames) {
      const { sum, count } = skillSums[skill];
      if (count > 0) {
        skillScoreAvg[skill] = Math.round((sum / count) * 10) / 10;
      }
    }
    const hasSkillData = Object.keys(skillScoreAvg).length > 0;

    // ── Integrity ────────────────────────────────────────────────────────────
    const integrityAgg = await ExamAttempt.aggregate([
      { $match: { assignmentId: { $in: assignmentIds } } },
      {
        $group: {
          _id: '$integrity.riskLevel',
          count: { $sum: 1 },
        },
      },
    ]);

    // ── Mode breakdown ───────────────────────────────────────────────────────
    const modeBreakdown = assignments.reduce((acc, a) => {
      acc[a.mode] = (acc[a.mode] || 0) + 1;
      return acc;
    }, {});

    // ── Active students ───────────────────────────────────────────────────────
    const classIds = await classroomIdsForTeacher(teacherId);
    const activeStudents = classIds.length
      ? await ClassroomMember.countDocuments({
          classroomId: { $in: classIds },
          status: 'active',
          roleInClass: 'student',
        })
      : 0;

    // ── Pending grading ───────────────────────────────────────────────────────
    const pendingGradingCount = assignmentIds.length
      ? await ExamAttempt.countDocuments({
          assignmentId: { $in: assignmentIds },
          gradingState: 'pending_manual',
        })
      : 0;

    // ── Avg final score ────────────────────────────────────────────────────
    const avgScoreAgg = await ExamAttempt.aggregate([
      {
        $match: {
          assignmentId: { $in: assignmentIds },
          status: 'submitted',
          submittedAt: { $gte: since },
          'scores.finalScore': { $ne: null },
        },
      },
      { $group: { _id: null, avg: { $avg: '$scores.finalScore' }, count: { $sum: 1 } } },
    ]);
    const avgScore =
      avgScoreAgg.length > 0
        ? Math.round((avgScoreAgg[0].avg ?? 0) * 10) / 10
        : null;

    // ── Trend vs previous period ──────────────────────────────────────────
    const prevSubmissions = await ExamAttempt.countDocuments({
      assignmentId: { $in: assignmentIds },
      status: 'submitted',
      submittedAt: { $gte: prevSince, $lt: since },
    });
    const currentSubmissions = filledDays.reduce((s, d) => s + d.count, 0);

    return {
      rangeDays: nDays,
      submissionsByDay: filledDays,
      scoreDistribution,
      skillScoreAvg: hasSkillData ? skillScoreAvg : null,
      integrityByRisk: Object.fromEntries(integrityAgg.map((r) => [r._id || 'unknown', r.count])),
      assignmentsByMode: modeBreakdown,
      activeStudents,
      totalAssignments: assignments.length,
      pendingGradingCount,
      avgScore,
      trend: {
        submissions: trendPct(currentSubmissions, prevSubmissions),
      },
    };
  },
};
