import mongoose from 'mongoose';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';

const DAY_MS = 24 * 60 * 60 * 1000;

async function classroomIdsForTeacher(teacherId) {
  const [owned, co] = await Promise.all([
    Classroom.find({ teacherId, archived: false }).select('_id').lean(),
    ClassroomMember.find({
      userId: teacherId,
      roleInClass: 'co_teacher',
      status: 'active',
    })
      .select('classroomId')
      .lean(),
  ]);
  const ids = new Set(owned.map((c) => c._id.toString()));
  for (const m of co) ids.add(m.classroomId.toString());
  return [...ids].map((id) => new mongoose.Types.ObjectId(id));
}

function trendPct(current, prev) {
  if (prev === 0 && current === 0) return 0;
  if (prev === 0) return 100;
  return Math.round(((current - prev) / prev) * 100 * 10) / 10;
}

function fillSubmissionDays(nDays, since, dayMap) {
  const filledDays = [];
  for (let d = 0; d < nDays; d++) {
    const dt = new Date(since.getTime() + d * DAY_MS);
    const key = dt.toISOString().slice(0, 10);
    filledDays.push({ date: key, count: dayMap[key] ?? 0 });
  }
  return filledDays;
}

export const teacherAnalyticsChartsService = {
  async getCharts(teacherId, { days = 14 } = {}) {
    const nDays = Math.min(30, Math.max(7, Number(days) || 14));
    const now = Date.now();
    const since = new Date(now - nDays * DAY_MS);
    const prevSince = new Date(now - nDays * 2 * DAY_MS);

    const [assignments, classIds] = await Promise.all([
      ExamAssignment.find({
        $or: [{ teacherId }, { teacherId: new mongoose.Types.ObjectId(teacherId) }],
      })
        .select('_id examId mode status classroomId')
        .lean(),
      classroomIdsForTeacher(teacherId),
    ]);

    const assignmentIds = assignments.map((a) => a._id);
    const modeBreakdown = assignments.reduce((acc, a) => {
      acc[a.mode] = (acc[a.mode] || 0) + 1;
      return acc;
    }, {});

    if (!assignmentIds.length) {
      const activeStudents = classIds.length
        ? await ClassroomMember.countDocuments({
            classroomId: { $in: classIds },
            status: 'active',
            roleInClass: 'student',
          })
        : 0;
      return {
        rangeDays: nDays,
        submissionsByDay: fillSubmissionDays(nDays, since, {}),
        scoreDistribution: [],
        skillScoreAvg: null,
        integrityByRisk: {},
        assignmentsByMode: modeBreakdown,
        activeStudents,
        totalAssignments: 0,
        pendingGradingCount: 0,
        avgScore: null,
        trend: { submissions: 0 },
      };
    }

    const [
      submissionsByDay,
      integratedBucketAgg,
      integratedWithSkills,
      integrityAgg,
      activeStudents,
      pendingGradingCount,
      avgScoreAgg,
      prevSubmissions,
      legacyScoreBuckets,
    ] = await Promise.all([
      ExamAttempt.aggregate([
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
      ]),
      ExamAttempt.aggregate([
        {
          $match: {
            assignmentId: { $in: assignmentIds },
            status: 'submitted',
            'scores.examFormat': { $exists: true },
            'scores.finalScore': { $ne: null },
          },
        },
        {
          $group: {
            _id: {
              $min: [4, { $floor: { $divide: ['$scores.finalScore', 2] } }],
            },
            count: { $sum: 1 },
          },
        },
      ]),
      ExamAttempt.find({
        assignmentId: { $in: assignmentIds },
        status: 'submitted',
        'scores.skillScores': { $exists: true },
        submittedAt: { $gte: since },
      })
        .select('scores.skillScores')
        .lean(),
      ExamAttempt.aggregate([
        { $match: { assignmentId: { $in: assignmentIds } } },
        {
          $group: {
            _id: '$integrity.riskLevel',
            count: { $sum: 1 },
          },
        },
      ]),
      classIds.length
        ? ClassroomMember.countDocuments({
            classroomId: { $in: classIds },
            status: 'active',
            roleInClass: 'student',
          })
        : Promise.resolve(0),
      ExamAttempt.countDocuments({
        assignmentId: { $in: assignmentIds },
        gradingState: 'pending_manual',
      }),
      ExamAttempt.aggregate([
        {
          $match: {
            assignmentId: { $in: assignmentIds },
            status: 'submitted',
            submittedAt: { $gte: since },
            'scores.finalScore': { $ne: null },
          },
        },
        { $group: { _id: null, avg: { $avg: '$scores.finalScore' }, count: { $sum: 1 } } },
      ]),
      ExamAttempt.countDocuments({
        assignmentId: { $in: assignmentIds },
        status: 'submitted',
        submittedAt: { $gte: prevSince, $lt: since },
      }),
      ExamAttempt.aggregate([
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
      ]),
    ]);

    const dayMap = Object.fromEntries(submissionsByDay.map((r) => [r._id, r.count]));
    const filledDays = fillSubmissionDays(nDays, since, dayMap);

    const integratedTotal = integratedBucketAgg.reduce((s, b) => s + b.count, 0);
    let scoreDistribution;
    if (integratedTotal > 0) {
      const bucketMap = Object.fromEntries(integratedBucketAgg.map((b) => [b._id, b.count]));
      const labels = ['0–2', '2–4', '4–6', '6–8', '8–10'];
      scoreDistribution = labels.map((range, i) => ({ range, count: bucketMap[i] ?? 0 }));
    } else {
      const bucketLabel = { 0: '<50%', 50: '50–70%', 70: '70–85%', 85: '≥85%' };
      scoreDistribution = legacyScoreBuckets.map((b) => ({
        range: bucketLabel[b._id] ?? String(b._id),
        count: b.count,
      }));
    }

    const skillNames = ['listening', 'reading', 'writing', 'speaking', 'grammar'];
    const skillSums = Object.fromEntries(skillNames.map((k) => [k, { sum: 0, count: 0 }]));

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

    const avgScore =
      avgScoreAgg.length > 0
        ? Math.round((avgScoreAgg[0].avg ?? 0) * 10) / 10
        : null;

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
