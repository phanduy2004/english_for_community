import mongoose from 'mongoose';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import { percentFromScore, scoreOfAttempt } from '../lib/examAttemptScoreUtils.js';
import {
  gradingAttentionMatch,
  resolveWindow,
  teacherAnalyticsScope,
} from './teacherAnalyticsScope.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const VN_OFFSET_MS = 7 * 60 * 60 * 1000;

// ── Pure business logic (unit-tested in teacherAnalyticsChartsService.test.js) ──

export function trendPct(current, prev) {
  if (prev === 0 && current === 0) return 0;
  if (prev === 0) return 100;
  return Math.round(((current - prev) / prev) * 100 * 10) / 10;
}

export function fillSubmissionDays(nDays, since, dayMap, offsetMs = VN_OFFSET_MS) {
  const filledDays = [];
  for (let d = 0; d < nDays; d++) {
    const dt = new Date(since.getTime() + d * DAY_MS);
    // Key = ngày theo LỊCH VN (khớp $dateToString timezone:'+07:00'), không phải UTC.
    const key = new Date(dt.getTime() + offsetMs).toISOString().slice(0, 10);
    filledDays.push({ date: key, count: dayMap[key] ?? 0 });
  }
  return filledDays;
}

/**
 * Chỉ giữ attempt MỚI NHẤT cho mỗi cặp (userId, assignmentId) — tránh đếm trùng khi
 * học sinh nộp lại (finding #3): on-time/late + submittedCount phải tính 1 lần/bài.
 */
export function dedupeLatestAttempts(attempts) {
  const latest = new Map(); // `${uid}:${aid}` -> attempt
  for (const att of attempts || []) {
    const key = `${att.userId}:${att.assignmentId}`;
    const prev = latest.get(key);
    if (!prev || new Date(att.submittedAt) > new Date(prev.submittedAt)) {
      latest.set(key, att);
    }
  }
  return [...latest.values()];
}

export function shortStem(text, max = 64) {
  const t = String(text || '').replace(/\s+/g, ' ').trim();
  if (!t) return '';
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

/** Flatten exam-snapshot items keeping the owning section label (skill / title). */
export function walkItemsWithSection(sections) {
  const out = [];
  if (!Array.isArray(sections)) return out;
  for (const sec of sections) {
    const secLabel = sec?.skill || sec?.title || sec?.kind || '';
    for (const item of sec?.items || []) {
      out.push({ ...item, _section: secLabel });
      if (item?.kind === 'reading' || item?.kind === 'listening') {
        for (const nested of item?.nestedItems || []) {
          out.push({ ...nested, _section: secLabel || item.kind });
        }
      }
    }
  }
  return out;
}

/**
 * Classify a single student's standing into an at-risk reason + sort severity.
 * Priority: no submissions > low average (<50%) > frequently late (≥2).
 */
export function classifyStudentRisk({ assignedCount, submittedCount, avgPercent, lateCount = 0 }) {
  if (assignedCount > 0 && submittedCount === 0) {
    return { reason: 'not_submitting', severity: 300 };
  }
  if (avgPercent != null && avgPercent < 50) {
    return { reason: 'low_score', severity: 200 + (50 - avgPercent) };
  }
  if (lateCount >= 2) {
    return { reason: 'late', severity: 100 + lateCount };
  }
  return { reason: null, severity: 0 };
}

/** On-time iff there is a due date and the submission is at/under it. No due date → on-time. */
export function classifyOnTime(submittedAt, dueAt) {
  if (!dueAt || !submittedAt) return 'onTime';
  return new Date(submittedAt) <= new Date(dueAt) ? 'onTime' : 'late';
}

/**
 * Aggregate per-question performance into the hardest N questions.
 * @param itemAttempts array of attempts, each `{ assignmentId, scores: { items } }` (or `{ items }`)
 * @param getMeta (assignmentId, itemId) => { stem, tag } | undefined
 */
export function aggregateHardestItems(itemAttempts, getMeta, { minResponses = 3, limit = 6 } = {}) {
  const agg = new Map(); // `${aid}:${itemId}` -> { aid, itemId, awarded, max, count }
  for (const att of itemAttempts) {
    const aid = String(att.assignmentId);
    const items = att.scores?.items ?? att.items;
    if (!items || typeof items !== 'object') continue;
    for (const [itemId, entry] of Object.entries(items)) {
      // Ungraded manual questions have awardedPoints=0 → would fake a "0% hardest".
      if (entry?.status === 'pending_manual' || entry?.status === 'pending_ai') continue;
      const max = Number(entry?.maxPoints ?? 0);
      if (!(max > 0)) continue;
      const awarded = Number(entry?.awardedPoints ?? entry?.manual?.points ?? 0);
      const key = `${aid}:${itemId}`;
      if (!agg.has(key)) agg.set(key, { aid, itemId, awarded: 0, max: 0, count: 0 });
      const g = agg.get(key);
      g.awarded += Math.max(0, Math.min(max, awarded));
      g.max += max;
      g.count += 1;
    }
  }

  const rows = [];
  for (const g of agg.values()) {
    if (g.count < minResponses || !(g.max > 0)) continue;
    const meta = getMeta(g.aid, g.itemId);
    const label = shortStem(meta?.stem) || `#${String(g.itemId).slice(-4)}`;
    rows.push({
      label,
      tag: meta?.tag || '',
      pctCorrect: Math.round((g.awarded / g.max) * 1000) / 10,
      attempts: g.count,
    });
  }
  rows.sort((a, b) => a.pctCorrect - b.pctCorrect);
  return rows.slice(0, limit);
}

/** Build the 5-bucket score distribution (integrated 0–10 preferred, else legacy % buckets). */
export function buildScoreDistribution(integratedBucketAgg, legacyScoreBuckets) {
  const integratedTotal = (integratedBucketAgg || []).reduce((s, b) => s + b.count, 0);
  if (integratedTotal > 0) {
    const bucketMap = Object.fromEntries(integratedBucketAgg.map((b) => [b._id, b.count]));
    const labels = ['0–2', '2–4', '4–6', '6–8', '8–10'];
    return labels.map((range, i) => ({ range, count: bucketMap[i] ?? 0 }));
  }
  const bucketLabel = { 0: '<50%', 50: '50–70%', 70: '70–85%', 85: '≥85%' };
  return (legacyScoreBuckets || []).map((b) => ({
    range: bucketLabel[b._id] ?? String(b._id),
    count: b.count,
  }));
}

/** Average per-skill scores across attempts — only finalized, non-null scores count. */
export function aggregateSkillAvg(integratedWithSkills) {
  const skillNames = ['listening', 'reading', 'writing', 'speaking', 'grammar'];
  const skillSums = Object.fromEntries(skillNames.map((k) => [k, { sum: 0, count: 0 }]));
  for (const a of integratedWithSkills || []) {
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
    if (count > 0) skillScoreAvg[skill] = Math.round((sum / count) * 10) / 10;
  }
  return skillScoreAvg;
}

// ── DB access ──────────────────────────────────────────────────────────────────

const EMPTY_INSIGHTS = {
  scoreByDay: [],
  atRiskStudents: [],
  hardestItems: [],
  integrityReasons: { tabSwitch: 0, copyPaste: 0, fullscreenExited: 0, focusLossSeconds: 0 },
  onTime: { onTime: 0, late: 0, missing: 0 },
};

/**
 * Per-student risk + on-time submission — computed over the teacher's ACTIVE
 * classroom assignments (a proxy for "current" work), scoped to the window.
 */
async function computeStudentRiskAndOnTime(assignments, classIds) {
  const activeClassAssignments = assignments.filter(
    (a) => a.classroomId && a.status === 'active'
  );
  if (!classIds.length || !activeClassAssignments.length) {
    return { atRiskStudents: [], onTime: { onTime: 0, late: 0, missing: 0 } };
  }

  const byClassroom = new Map(); // classroomId -> [{ id, dueAt }]
  for (const a of activeClassAssignments) {
    const cid = a.classroomId.toString();
    if (!byClassroom.has(cid)) byClassroom.set(cid, []);
    byClassroom.get(cid).push({
      id: a._id.toString(),
      dueAt: a.config?.dueAt ? new Date(a.config.dueAt) : null,
    });
  }

  const members = await ClassroomMember.find({
    classroomId: { $in: classIds },
    status: 'active',
    roleInClass: 'student',
  })
    .select('userId classroomId')
    .populate('userId', 'fullName email username')
    .lean();

  const students = new Map(); // uid -> { profile, assignedIds:Set, dueById:Map }
  for (const m of members) {
    const u = m.userId;
    const uid = u?._id ? u._id.toString() : String(m.userId);
    if (!students.has(uid)) {
      students.set(uid, {
        userId: uid,
        fullName: u?.fullName || u?.username || '',
        email: u?.email || '',
        assignedIds: new Set(),
        dueById: new Map(),
      });
    }
    const s = students.get(uid);
    for (const a of byClassroom.get(m.classroomId.toString()) || []) {
      s.assignedIds.add(a.id);
      s.dueById.set(a.id, a.dueAt);
    }
  }

  const assignmentIds = activeClassAssignments.map((a) => a._id);
  const userIds = [...students.keys()].map((id) => new mongoose.Types.ObjectId(id));
  // Finding #4: KHÔNG lọc theo window — xét MỌI lần nộp của assignment active (một bài
  // nộp trước cửa sổ N ngày vẫn tính là "đã nộp"), tránh cờ not_submitting sai + missing phồng.
  const rawAttempts =
    assignmentIds.length && userIds.length
      ? await ExamAttempt.find({
          assignmentId: { $in: assignmentIds },
          userId: { $in: userIds },
          status: 'submitted',
        })
          .select('userId assignmentId scores submittedAt')
          .lean()
      : [];
  // Finding #3: dedupe theo (student, assignment) trước khi tally on-time/late.
  const attempts = dedupeLatestAttempts(rawAttempts);

  const perStudent = new Map(); // uid -> { sumPct, scored, submittedIds:Set, late }
  let onTime = 0;
  let late = 0;
  for (const att of attempts) {
    const uid = att.userId.toString();
    const s = students.get(uid);
    if (!s) continue;
    const aid = att.assignmentId.toString();
    if (!perStudent.has(uid)) {
      perStudent.set(uid, { sumPct: 0, scored: 0, submittedIds: new Set(), late: 0 });
    }
    const ps = perStudent.get(uid);
    ps.submittedIds.add(aid);
    const pct = percentFromScore(scoreOfAttempt(att));
    if (pct != null) {
      ps.sumPct += pct;
      ps.scored += 1;
    }
    if (classifyOnTime(att.submittedAt, s.dueById.get(aid)) === 'late') {
      late += 1;
      ps.late += 1;
    } else {
      onTime += 1;
    }
  }

  const list = [];
  let totalAssigned = 0;
  let totalSubmitted = 0;
  for (const s of students.values()) {
    const ps = perStudent.get(s.userId);
    const submittedCount = ps ? ps.submittedIds.size : 0;
    const assignedCount = s.assignedIds.size;
    totalAssigned += assignedCount;
    totalSubmitted += submittedCount;
    const avgPercent = ps && ps.scored > 0 ? Math.round((ps.sumPct / ps.scored) * 10) / 10 : null;

    const { reason, severity } = classifyStudentRisk({
      assignedCount,
      submittedCount,
      avgPercent,
      lateCount: ps ? ps.late : 0,
    });
    if (reason) {
      list.push({
        userId: s.userId,
        fullName: s.fullName,
        email: s.email,
        avgPercent,
        submittedCount,
        assignedCount,
        reason,
        severity,
      });
    }
  }
  list.sort((a, b) => b.severity - a.severity || (a.avgPercent ?? 999) - (b.avgPercent ?? 999));

  return {
    atRiskStudents: list.slice(0, 8).map(({ severity, ...r }) => r),
    onTime: { onTime, late, missing: Math.max(0, totalAssigned - totalSubmitted) },
  };
}

/** Item analysis — the questions the class scored lowest on (avg % of points earned). */
async function computeHardestItems(assignmentIds, since) {
  if (!assignmentIds.length) return [];
  const itemAttempts = await ExamAttempt.find({
    assignmentId: { $in: assignmentIds },
    status: 'submitted',
    submittedAt: { $gte: since },
    'scores.items': { $exists: true, $ne: null },
  })
    .select('assignmentId scores.items')
    .lean();
  if (!itemAttempts.length) return [];

  const involved = new Set(itemAttempts.map((a) => a.assignmentId.toString()));
  const snaps = await ExamAssignment.find({
    _id: { $in: [...involved].map((id) => new mongoose.Types.ObjectId(id)) },
  })
    .select('examSnapshot')
    .lean();
  const metaByAssignment = new Map(); // aid -> Map(itemId -> { stem, tag })
  for (const snap of snaps) {
    const m = new Map();
    for (const it of walkItemsWithSection(snap.examSnapshot?.sections || [])) {
      if (it?.itemId) m.set(it.itemId, { stem: it.stem, tag: it._section || it.kind || '' });
    }
    metaByAssignment.set(snap._id.toString(), m);
  }

  return aggregateHardestItems(
    itemAttempts,
    (aid, itemId) => metaByAssignment.get(aid)?.get(itemId),
    { minResponses: 3, limit: 6 }
  );
}

export const teacherAnalyticsChartsService = {
  async getCharts(teacherId, { days = 14, classroomId = null } = {}) {
    const nDays = Math.min(30, Math.max(7, Number(days) || 14));
    const now = Date.now();
    // Finding #1/#2: cửa sổ N ngày theo LỊCH VN, GỒM hôm nay.
    const { since, prevSince } = resolveWindow(now, nDays);

    // Scope: 1 lớp cụ thể nếu có classroomId, ngược lại gộp owner ∪ co-taught.
    const { classIds, assignments, assignmentIds } = await teacherAnalyticsScope(
      teacherId,
      undefined,
      { classroomId }
    );

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
        trend: { submissions: 0, avgScore: 0 },
        ...EMPTY_INSIGHTS,
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
      scoreByDayAgg,
      prevAvgScoreAgg,
      integrityReasonsAgg,
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
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$submittedAt', timezone: '+07:00' } },
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
            submittedAt: { $gte: since },
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
        { $match: { assignmentId: { $in: assignmentIds }, status: 'submitted', submittedAt: { $gte: since } } },
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
        ...gradingAttentionMatch,
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
            submittedAt: { $gte: since },
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
      ExamAttempt.aggregate([
        {
          $match: {
            assignmentId: { $in: assignmentIds },
            status: 'submitted',
            submittedAt: { $gte: since },
            'scores.finalScore': { $ne: null },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$submittedAt', timezone: '+07:00' } },
            avg: { $avg: '$scores.finalScore' },
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
            submittedAt: { $gte: prevSince, $lt: since },
            'scores.finalScore': { $ne: null },
          },
        },
        { $group: { _id: null, avg: { $avg: '$scores.finalScore' } } },
      ]),
      ExamAttempt.aggregate([
        { $match: { assignmentId: { $in: assignmentIds }, status: 'submitted', submittedAt: { $gte: since } } },
        {
          $group: {
            _id: null,
            tabSwitch: { $sum: { $ifNull: ['$integrity.tabSwitchCount', 0] } },
            copyPaste: { $sum: { $ifNull: ['$integrity.copyPasteAttempts', 0] } },
            focusLossSeconds: { $sum: { $ifNull: ['$integrity.focusLossSeconds', 0] } },
            fullscreenExited: { $sum: { $cond: ['$integrity.fullscreenExited', 1, 0] } },
          },
        },
      ]),
    ]);

    const [{ atRiskStudents, onTime }, hardestItems] = await Promise.all([
      computeStudentRiskAndOnTime(assignments, classIds),
      computeHardestItems(assignmentIds, since),
    ]);

    const dayMap = Object.fromEntries(submissionsByDay.map((r) => [r._id, r.count]));
    const filledDays = fillSubmissionDays(nDays, since, dayMap);

    const scoreByDay = scoreByDayAgg.map((r) => ({
      date: r._id,
      avg: Math.round((r.avg ?? 0) * 10) / 10,
      count: r.count,
    }));

    const scoreDistribution = buildScoreDistribution(integratedBucketAgg, legacyScoreBuckets);

    const skillScoreAvg = aggregateSkillAvg(integratedWithSkills);
    const hasSkillData = Object.keys(skillScoreAvg).length > 0;

    const avgScore =
      avgScoreAgg.length > 0 ? Math.round((avgScoreAgg[0].avg ?? 0) * 10) / 10 : null;
    const prevAvgScore = prevAvgScoreAgg.length > 0 ? prevAvgScoreAgg[0].avg ?? null : null;

    const currentSubmissions = filledDays.reduce((s, d) => s + d.count, 0);

    const ir = integrityReasonsAgg[0] || {};
    const integrityReasons = {
      tabSwitch: ir.tabSwitch || 0,
      copyPaste: ir.copyPaste || 0,
      fullscreenExited: ir.fullscreenExited || 0,
      focusLossSeconds: ir.focusLossSeconds || 0,
    };

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
      scoreByDay,
      atRiskStudents,
      hardestItems,
      integrityReasons,
      onTime,
      trend: {
        submissions: trendPct(currentSubmissions, prevSubmissions),
        avgScore:
          avgScore != null && prevAvgScore != null
            ? Math.round((avgScore - prevAvgScore) * 100) / 100
            : 0,
      },
    };
  },
};
