import ExamAttempt from '../models/ExamAttempt.js';
import { resolveAttemptPolicy, allowsAnotherAttemptAfterSubmit } from './assignmentPolicy.js';
import { walkItems, walkSkillContentSections } from './teacherExamService.js';

function iso(d) {
  if (!d) return null;
  const dt = d instanceof Date ? d : new Date(d);
  if (Number.isNaN(dt.getTime())) return null;
  return dt.toISOString();
}

export function summarizeExam(exam) {
  if (!exam) return null;
  const doc = exam.toJSON ? exam.toJSON() : exam;
  const settings = doc.settings || {};
  const fmt = settings.examFormat || 'classic';
  const grammarItems = Array.isArray(settings.grammarItems) ? settings.grammarItems : [];
  const skillSections = walkSkillContentSections(doc.sections || []);
  const items = walkItems(doc.sections || []);

  let questionCount = 0;
  let totalPoints = 0;

  if (fmt === 'integrated_four_skills' || fmt === 'skills_exam') {
    questionCount = grammarItems.length + skillSections.length;
    totalPoints = 100;
  } else {
    const answerable = items.filter((i) => !['reading', 'listening'].includes(i.kind));
    questionCount = answerable.length;
    totalPoints = answerable.reduce((s, it) => s + Number(it.points ?? 1), 0);
  }

  return {
    id: doc.id || doc._id?.toString(),
    title: doc.title || '',
    description: doc.description || '',
    examFormat: fmt,
    timeLimitSeconds: settings.timeLimitSeconds ?? null,
    questionCount,
    totalPoints,
    grammarItemCount: grammarItems.length,
    skillSectionCount: skillSections.length,
    allowMultipleSubmissions: !!settings.allowMultipleSubmissions,
  };
}

export function summarizeSchedule(assignment) {
  const cfg = assignment.config || {};
  const mode = assignment.mode;
  const base = { mode };
  if (mode === 'self_paced') {
    base.dueAt = iso(cfg.dueAt);
  } else if (mode === 'scheduled') {
    base.opensAt = iso(cfg.opensAt);
    base.closesAt = iso(cfg.closesAt);
  }
  const tl = cfg.timeLimitSeconds ?? null;
  if (tl != null) base.timeLimitSeconds = Number(tl);
  return base;
}

export function serializeActiveSession(s) {
  if (!s) return null;
  const joined = Array.isArray(s.joinedUserIds) ? s.joinedUserIds.length : 0;
  return {
    id: s._id.toString(),
    status: s.status,
    roomCode: s.roomCode || '',
    startedAt: iso(s.startedAt),
    endedAt: iso(s.endedAt),
    joinedCount: joined,
    createdAt: iso(s.createdAt),
  };
}

export function serializeMyAttempt(att) {
  if (!att) return null;
  const doc = att.toJSON ? att.toJSON() : att;
  const awarded = doc.scores?.totalAwarded ?? null;
  const max = doc.scores?.totalMax ?? null;
  return {
    id: doc.id || doc._id?.toString(),
    status: doc.status,
    submittedAt: iso(doc.submittedAt),
    startedAt: iso(doc.startedAt),
    totalAwarded: awarded,
    totalMax: max,
    scorePercent: max > 0 && awarded != null ? Math.round((Number(awarded) / Number(max)) * 1000) / 10 : null,
    resultsReleased: !!doc.resultsReleased,
    gradingState: doc.gradingState || null,
  };
}

/**
 * Gắn studentCanStart / studentStatusHint theo bài làm hiện có (resume / đã nộp).
 */
export function applyStudentAttemptGate(plain, assignment, myAttemptDoc) {
  if (!myAttemptDoc || !plain) return plain;
  const status = myAttemptDoc.status;
  const exam = assignment.examId;

  if (status === 'in_progress') {
    plain.studentCanStart = true;
    plain.studentStatusHint = 'resume';
    return plain;
  }

  if (status === 'submitted' || status === 'expired') {
    const policy = resolveAttemptPolicy(assignment, exam);
    if (assignment.mode !== 'practice' && !allowsAnotherAttemptAfterSubmit(policy)) {
      plain.studentCanStart = false;
      plain.studentStatusHint = 'already_submitted';
    }
  }
  return plain;
}

export function buildAssignmentCardFields(assignment, { activeSession, myAttempt, attemptStats } = {}) {
  const exam = assignment.examId;
  const examSummary = summarizeExam(exam);
  const schedule = summarizeSchedule(assignment);
  const cfg = assignment.config || {};
  const effectiveTimeLimit =
    cfg.timeLimitSeconds != null ? Number(cfg.timeLimitSeconds) : examSummary?.timeLimitSeconds ?? null;

  return {
    examSummary,
    schedule: {
      ...schedule,
      effectiveTimeLimitSeconds: effectiveTimeLimit > 0 ? effectiveTimeLimit : null,
    },
    activeSession: serializeActiveSession(activeSession),
    myAttempt: serializeMyAttempt(myAttempt),
    attemptStats: attemptStats || null,
    assignedAt: iso(assignment.createdAt),
    updatedAt: iso(assignment.updatedAt),
  };
}

export async function latestAttemptsByAssignmentForUser(userId, assignmentIds, { assignmentById } = {}) {
  if (!assignmentIds.length) return new Map();
  const attempts = await ExamAttempt.find({
    userId,
    assignmentId: { $in: assignmentIds },
  })
    .sort({ updatedAt: -1 })
    .select('assignmentId status submittedAt startedAt scores resultsReleased gradingState');
  const map = new Map();
  for (const att of attempts) {
    const aid = att.assignmentId.toString();
    const policy =
      assignmentById?.get(aid)?.config?.attemptPolicy ||
      assignmentById?.get(aid)?.attemptPolicy ||
      'single';
    const cur = map.get(aid);
    if (!cur) {
      map.set(aid, att);
      continue;
    }
    if (policy === 'single') continue;
    const curScore = Number(cur.scores?.totalAwarded ?? -1);
    const newScore = Number(att.scores?.totalAwarded ?? -1);
    const curSubmitted = cur.status === 'submitted';
    const newSubmitted = att.status === 'submitted';
    if (newSubmitted && !curSubmitted) {
      map.set(aid, att);
      continue;
    }
    if (newSubmitted && curSubmitted && newScore > curScore) {
      map.set(aid, att);
    }
  }
  return map;
}

export async function attemptStatsByAssignment(assignmentIds) {
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
    if (!map.has(aid)) {
      map.set(aid, { inProgress: 0, submitted: 0, void: 0, expired: 0, total: 0 });
    }
    const st = row._id.status;
    const bucket = map.get(aid);
    const c = row.count;
    if (st === 'in_progress') bucket.inProgress += c;
    else if (st === 'submitted') bucket.submitted += c;
    else if (st === 'void') bucket.void += c;
    else if (st === 'expired') bucket.expired += c;
    bucket.total += c;
  }
  return map;
}
