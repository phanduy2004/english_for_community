import mongoose from 'mongoose';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import { classroomService } from './classroomService.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

function shortTitle(title, max = 36) {
  const t = String(title || 'Exam').trim();
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

function isIntegratedScores(scores) {
  if (!scores || typeof scores !== 'object') return false;
  const fmt = scores.examFormat;
  return (
    fmt === 'integrated_four_skills' ||
    fmt === 'skills_exam' ||
    scores.finalScore != null ||
    scores.finalMax != null
  );
}

/** Same rules as grading hub: integrated → finalScore/10; classic → totalAwarded/totalMax. */
function scoreOfAttempt(att) {
  if (!att) return null;
  const scores = att.scores || {};

  if (isIntegratedScores(scores)) {
    const awarded = scores.finalScore;
    const max = Number(scores.finalMax ?? 10);
    if (awarded == null) return { awarded: null, max, scale: 'ten' };
    return { awarded: Number(awarded), max, scale: 'ten' };
  }

  let awarded = scores.totalAwarded;
  let max = scores.totalMax;
  if ((awarded == null && max == null) || (Number(max ?? 0) <= 0 && scores.finalScore != null)) {
    if (scores.finalScore != null) {
      return {
        awarded: Number(scores.finalScore),
        max: Number(scores.finalMax ?? 10),
        scale: 'ten',
      };
    }
    return null;
  }
  return { awarded: Number(awarded ?? 0), max: Number(max ?? 0), scale: 'points' };
}

function percentFromScore(score) {
  if (!score || score.max <= 0) return null;
  return Math.round((score.awarded / score.max) * 1000) / 10;
}

function pickBestAttempt(attempts) {
  let best = null;
  let bestAwarded = -1;
  for (const att of attempts) {
    if (att.status !== 'submitted' && att.status !== 'expired') continue;
    const s = scoreOfAttempt(att);
    const awarded = s?.awarded ?? -1;
    if (!best || awarded > bestAwarded) {
      best = att;
      bestAwarded = awarded;
    }
  }
  if (best) return best;
  return attempts.find((a) => a.status === 'in_progress') || attempts[0] || null;
}

function escapeCsvCell(v) {
  const s = String(v ?? '');
  if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

function buildCell(best) {
  const score = scoreOfAttempt(best);
  const status = best?.status || 'not_started';
  const gradingState = best?.gradingState || null;
  const hasScore =
    score != null && score.awarded != null && Number.isFinite(score.awarded) && score.max > 0;
  const pendingGrading =
    status === 'submitted' &&
    (gradingState === 'pending_manual' ||
      gradingState === 'pending_ai' ||
      gradingState === 'pending_auto' ||
      (gradingState === 'finalized' && !best?.resultsReleased));

  return {
    assignmentId: best?.assignmentId?.toString?.() || null,
    attemptId: best?._id?.toString() || null,
    status,
    gradingState,
    resultsReleased: !!best?.resultsReleased,
    pendingGrading,
    scorePercent: hasScore ? percentFromScore(score) : null,
    totalAwarded: score?.awarded ?? null,
    totalMax: score?.max ?? null,
    scoreScale: score?.scale ?? null,
    submittedAt: best?.submittedAt || null,
  };
}

export const teacherGradebookService = {
  async getClassroomGradebook(teacherId, classroomId) {
    if (!mongoose.Types.ObjectId.isValid(classroomId)) throw httpError(400, 'Invalid classroom id');
    const { isTeacher, classroom } = await classroomService.getByIdForUser(classroomId, teacherId);
    if (!isTeacher) throw httpError(403, 'Forbidden');

    const members = await ClassroomMember.find({
      classroomId,
      status: 'active',
    }).populate('userId', 'fullName email username');

    const assignments = await ExamAssignment.find({
      teacherId,
      audience: 'classroom',
      classroomId,
      mode: { $ne: 'practice' },
    })
      .sort({ createdAt: -1 })
      .populate('examId', 'title');

    const assignmentIds = assignments.map((a) => a._id);
    const attempts = assignmentIds.length
      ? await ExamAttempt.find({
          assignmentId: { $in: assignmentIds },
          userId: { $in: members.map((m) => m.userId) },
        }).select(
          'userId assignmentId status scores gradingState resultsReleased submittedAt'
        )
      : [];

    const byUserAssignment = new Map();
    for (const att of attempts) {
      const key = `${att.userId.toString()}:${att.assignmentId.toString()}`;
      if (!byUserAssignment.has(key)) byUserAssignment.set(key, []);
      byUserAssignment.get(key).push(att);
    }

    const assignmentCols = assignments.map((a) => {
      const exam = a.examId;
      const title = exam?.title ? String(exam.title) : 'Exam';
      return {
        id: a._id.toString(),
        examTitle: title,
        shortTitle: shortTitle(title),
        mode: a.mode,
        status: a.status,
        dueAt: a.config?.dueAt || null,
        opensAt: a.config?.opensAt || null,
        closesAt: a.config?.closesAt || null,
      };
    });

    const rows = members.map((m) => {
      const u = m.userId;
      const userId = u?._id?.toString() || m.userId.toString();
      const cells = assignmentCols.map((col) => {
        const key = `${userId}:${col.id}`;
        const list = byUserAssignment.get(key) || [];
        const best = pickBestAttempt(list);
        return {
          ...buildCell(best),
          assignmentId: col.id,
        };
      });

      const scored = cells.filter((c) => c.scorePercent != null);
      const rowAvgPercent =
        scored.length > 0
          ? Math.round(
              (scored.reduce((s, c) => s + c.scorePercent, 0) / scored.length) * 10
            ) / 10
          : null;
      const submittedCount = cells.filter(
        (c) => c.status === 'submitted' || c.status === 'expired'
      ).length;

      return {
        userId,
        fullName: u?.fullName || '',
        email: u?.email || '',
        username: u?.username || '',
        rowAvgPercent,
        submittedCount,
        cells,
      };
    });

    const classAverageCells = assignmentCols.map((col) => {
      const percents = rows
        .map((r) => r.cells.find((c) => c.assignmentId === col.id)?.scorePercent)
        .filter((p) => p != null);
      const submitted = rows.filter((r) => {
        const c = r.cells.find((x) => x.assignmentId === col.id);
        return c && (c.status === 'submitted' || c.status === 'expired');
      }).length;
      const pendingGrading = rows.filter((r) => {
        const c = r.cells.find((x) => x.assignmentId === col.id);
        return c?.pendingGrading;
      }).length;
      const avgPercent =
        percents.length > 0
          ? Math.round((percents.reduce((a, b) => a + b, 0) / percents.length) * 10) / 10
          : null;

      return {
        assignmentId: col.id,
        avgPercent,
        submittedCount: submitted,
        pendingGradingCount: pendingGrading,
        studentCount: rows.length,
      };
    });

    const allPercents = rows.map((r) => r.rowAvgPercent).filter((p) => p != null);
    const classAvgPercent =
      allPercents.length > 0
        ? Math.round((allPercents.reduce((a, b) => a + b, 0) / allPercents.length) * 10) / 10
        : null;

    let pendingGradingTotal = 0;
    for (const r of rows) {
      for (const c of r.cells) {
        if (c.pendingGrading) pendingGradingTotal += 1;
      }
    }

    return {
      classroom: {
        id: classroom._id.toString(),
        name: classroom.name,
      },
      summary: {
        studentCount: rows.length,
        assignmentCount: assignmentCols.length,
        classAvgPercent,
        pendingGradingCount: pendingGradingTotal,
        submittedCells: rows.reduce((s, r) => s + r.submittedCount, 0),
        totalCells: rows.length * Math.max(assignmentCols.length, 1),
      },
      assignments: assignmentCols,
      classAverages: classAverageCells,
      rows,
    };
  },

  gradebookToCsv(data) {
    const headers = [
      'Student',
      'Email',
      ...data.assignments.map((a) => a.examTitle),
      'Student average %',
    ];
    const lines = [headers.map(escapeCsvCell).join(',')];
    for (const row of data.rows) {
      const name = row.fullName || row.username || row.userId;
      const cells = row.cells.map((c) => {
        if (c.totalAwarded != null && c.totalMax != null) {
          const pct = c.scorePercent != null ? ` (${c.scorePercent}%)` : '';
          return `${c.totalAwarded}/${c.totalMax}${pct}`;
        }
        if (c.status === 'in_progress') return 'In progress';
        if (c.pendingGrading) return 'Pending grading';
        if (c.status === 'not_started') return '';
        return c.status;
      });
      lines.push(
        [name, row.email || '', ...cells, row.rowAvgPercent ?? ''].map(escapeCsvCell).join(',')
      );
    }
    if (data.classAverages?.length) {
      const avgCells = data.classAverages.map((c) =>
        c.avgPercent != null ? `${c.avgPercent}%` : ''
      );
      lines.push(
        ['Class average', '', ...avgCells, data.summary?.classAvgPercent ?? ''].map(escapeCsvCell).join(',')
      );
    }
    return lines.join('\r\n');
  },
};
