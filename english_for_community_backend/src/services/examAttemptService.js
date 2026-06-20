import mongoose from 'mongoose';
import Exam from '../models/Exam.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamSession from '../models/ExamSession.js';
import User from '../models/User.js';
import DictationAttempt from '../models/DictationAttempt.js';
import Listening from '../models/Listening.js';
import ListeningComprehension from '../models/ListeningComprehension.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import Reading from '../models/Reading.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import WritingSubmission from '../models/WritingSubmission.js';
import { wordErrorRate } from '../untils/scoring.js';
import { teacherExamService } from './teacherExamService.js';
import { teacherExamAssignmentService } from './teacherExamAssignmentService.js';
import { resolveAttemptPolicy, resolveResultsDetailLevel, resolveShowResultsPolicy } from './assignmentPolicy.js';
import { computeAdaptiveState, isAdaptiveExamSnapshot } from './examAdaptiveService.js';
import { broadcastAttemptProgress } from './examLiveMonitorService.js';
import {
  buildIntegratedScores,
  integratedAutoScoresStale,
  integratedSkillEntriesMissing,
  mergePreservedSkillScores,
} from './examIntegratedScoring.js';
import {
  healExamSnapshotFromLiveExam,
  normalizeExamSnapshot,
  resourcesFromSkillSection,
} from './examSkillSectionResources.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

async function assertLiveSessionAllowsEdits(attempt) {
  if (!attempt.sessionId) return;
  const session = await ExamSession.findById(attempt.sessionId).select('status').lean();
  if (!session) return;
  if (['closed', 'grading', 'canceled'].includes(session.status)) {
    throw httpError(400, 'Live session has ended');
  }
}

const { walkItems, walkSkillContentSections } = teacherExamService;

async function afterAttemptActivity(attempt, assignment) {
  if (assignment?.classroomId) {
    const { classroomActivityService } = await import('./classroomActivityService.js');
    await classroomActivityService.log({
      classroomId: assignment.classroomId,
      actorId: attempt.userId,
      type: 'attempt_submitted',
      message: 'Student submitted work',
      meta: {
        attemptId: attempt._id.toString(),
        assignmentId: assignment._id.toString(),
      },
    });
  }

  if (attempt.status !== 'submitted') return;

  try {
    const {
      notifyTeacherExamSubmission,
      notifyStudentResultsReleased,
      studentDisplayName,
      assignmentNotificationContext,
    } = await import('./teacherNotificationHelper.js');

    let examTitle = attempt.examSnapshot?.title || '';
    if (!examTitle && assignment) {
      await assignment.populate?.('examId', 'title');
      const ctx = await assignmentNotificationContext(assignment);
      examTitle = ctx.examTitle;
    }

    const studentName = await studentDisplayName(attempt.userId);
    const teacherId = assignment?.teacherId;
    if (teacherId) {
      await notifyTeacherExamSubmission({
        teacherId,
        studentId: attempt.userId,
        studentName,
        assignmentId: assignment._id,
        attemptId: attempt._id,
        examTitle,
        classroomId: assignment.classroomId?._id || assignment.classroomId || null,
      });
    }

    if (attempt.resultsReleased) {
      await notifyStudentResultsReleased({
        studentId: attempt.userId,
        teacherId,
        examTitle,
        attemptId: attempt._id,
        assignmentId: assignment._id,
        classroomId: assignment.classroomId?._id || assignment.classroomId || null,
      });
    }
  } catch {
    /* optional notifications */
  }
}

function normalizeAnswer(s, { caseInsensitive = true, trim = true } = {}) {
  let v = String(s ?? '');
  if (trim) v = v.trim();
  if (caseInsensitive) v = v.toLowerCase();
  return v;
}

function scoreMcq(item, answer) {
  const selected = Array.isArray(answer?.selectedIndexes) ? answer.selectedIndexes.map(Number).sort((a, b) => a - b) : [];
  const correct = Array.isArray(item.correctOptionIndexes)
    ? item.correctOptionIndexes.map(Number).sort((a, b) => a - b)
    : [];
  if (selected.length !== correct.length) return 0;
  for (let i = 0; i < selected.length; i += 1) {
    if (selected[i] !== correct[i]) return 0;
  }
  return Number(item.points ?? 1);
}

function scoreFillBlank(item, answer) {
  const blanks = answer?.blanks || {};
  let earned = 0;
  const max = Number(item.points ?? 1);
  const defs = item.blanks || [];
  if (defs.length === 0) return 0;
  const per = max / defs.length;
  for (const b of defs) {
    const raw = blanks[b.blankId];
    const normalized = normalizeAnswer(raw, b);
    const ok = (b.acceptedAnswers || []).some((a) => normalizeAnswer(a, b) === normalized);
    if (ok) earned += per;
  }
  return Math.min(max, earned);
}

function scoreGrammarMatching(item, answer) {
  const chosen = answer?.matching || {};
  const corr = item.correctPairs;
  const max = Number(item.points ?? 1);
  if (!Array.isArray(corr) || corr.length === 0) return 0;
  const per = max / corr.length;
  let earned = 0;
  for (const pair of corr) {
    const [leftId, rightId] = pair;
    if (String(chosen[leftId]) === String(rightId)) earned += per;
  }
  return Math.min(max, earned);
}

function scoreGrammarReorder(item, answer) {
  const sub = answer?.order;
  if (!Array.isArray(sub)) return 0;
  const cor = (item.correctOrder || []).map(Number);
  if (sub.length !== cor.length) return 0;
  for (let i = 0; i < cor.length; i += 1) {
    if (Number(sub[i]) !== Number(cor[i])) return 0;
  }
  return Number(item.points ?? 1);
}

function resolveAllowPartialSubmit(assignment, exam) {
  if (assignment?.config?.allowPartialSubmit === false) return false;
  if (exam?.settings?.allowPartialSubmit === false) return false;
  return true;
}

/** Whether integrated/skills attempt has every required part done (for submitCompleteness). */
function integratedAttemptAllPartsDone(attempt, exam) {
  const examFormat = exam?.settings?.examFormat;
  if (examFormat !== 'integrated_four_skills' && examFormat !== 'skills_exam') return true;
  const skillSections = walkSkillContentSections(exam.sections || []);
  const grammarItems = Array.isArray(exam.settings?.grammarItems) ? exam.settings.grammarItems : [];
  for (const it of grammarItems) {
    if (!grammarAnswerComplete(it, attempt.answers?.[it.itemId])) return false;
  }
  for (const sec of skillSections) {
    const sid = String(sec.sectionId);
    const ans = attempt.answers?.[sid];
    const done = ans && typeof ans === 'object' && ans.completed === true;
    if (!done) return false;
  }
  return true;
}

function grammarAnswerComplete(item, answer) {
  const k = String(item.kind || '');
  if (k === 'mcq_single' || k === 'mcq_multi') {
    const sel = answer?.selectedIndexes;
    if (!Array.isArray(sel) || sel.length === 0) return false;
    if (k === 'mcq_single' && sel.length !== 1) return false;
    return true;
  }
  if (k === 'grammar_cloze' || k === 'grammar_gap') {
    const bl = answer?.blanks || {};
    const defs = item.blanks || [];
    return defs.every((d) => {
      const v = bl[d.blankId];
      return v != null && String(v).trim().length > 0;
    });
  }
  if (k === 'grammar_matching') {
    const m = answer?.matching || {};
    const left = item.leftItems || item.leftColumn;
    if (!Array.isArray(left)) return false;
    return left.every((row) => m[row.id] != null && String(m[row.id]).trim().length > 0);
  }
  if (k === 'grammar_reorder') {
    const ord = answer?.order;
    const fr = item.fragments || [];
    return Array.isArray(ord) && ord.length === fr.length;
  }
  return false;
}

function scoreGrammarItem(item, answer) {
  const k = String(item.kind || '');
  if (k === 'mcq_single' || k === 'mcq_multi') return scoreMcq(item, answer);
  if (k === 'grammar_cloze' || k === 'grammar_gap') {
    return scoreFillBlank(item, answer);
  }
  if (k === 'grammar_matching') return scoreGrammarMatching(item, answer);
  if (k === 'grammar_reorder') return scoreGrammarReorder(item, answer);
  return 0;
}

function computeAttemptDeadline(assignment, startedAt) {
  const limitSec = assignment.config?.timeLimitSeconds;
  const started = startedAt.getTime();
  const closes = assignment.config?.closesAt ? new Date(assignment.config.closesAt).getTime() : null;
  const due = assignment.config?.dueAt ? new Date(assignment.config.dueAt).getTime() : null;

  if (assignment.mode === 'scheduled') {
    if (limitSec && Number(limitSec) > 0) {
      const t = started + Number(limitSec) * 1000;
      if (closes != null) return new Date(Math.min(t, closes));
      return new Date(t);
    }
    if (closes != null) return new Date(closes);
    return null;
  }

  if (assignment.mode === 'self_paced') {
    if (limitSec && Number(limitSec) > 0) {
      const t = started + Number(limitSec) * 1000;
      if (due != null) return new Date(Math.min(t, due));
      return new Date(t);
    }
    if (due != null) return new Date(due);
    return null;
  }

  if (assignment.mode === 'realtime') {
    if (limitSec && Number(limitSec) > 0) {
      return new Date(started + Number(limitSec) * 1000);
    }
    return null;
  }

  return null;
}

/**
 * When per-attempt deadline has passed, auto-submit (partial allowed) instead of leaving `expired`.
 */
async function lazyExpireIfNeeded(attempt) {
  if (!attempt || attempt.status !== 'in_progress') return attempt;
  if (!attempt.attemptDeadlineAt) return attempt;
  if (new Date(attempt.attemptDeadlineAt).getTime() >= Date.now()) return attempt;

  const userId = attempt.userId?.toString?.() ?? String(attempt.userId);
  const attemptId = attempt._id?.toString?.() ?? String(attempt._id);
  try {
    await examAttemptService.submit(userId, attemptId, {
      force: true,
      forceEnd: true,
    });
    const refreshed = await ExamAttempt.findById(attemptId);
    return refreshed || attempt;
  } catch {
    attempt.status = 'expired';
    await attempt.save();
    return attempt;
  }
}

function iso(d) {
  if (!d) return null;
  const t = new Date(d).getTime();
  if (Number.isNaN(t)) return null;
  return new Date(t).toISOString();
}

/**
 * Student-facing attempt JSON plus `runtimeContext` (class, teacher, mode, deadlines).
 */
async function attachRuntimeContextToAttempt(attemptDoc) {
  await lazyExpireIfNeeded(attemptDoc);
  const plain = attemptDoc.toJSON
    ? attemptDoc.toJSON()
    : typeof attemptDoc.toObject === 'function'
      ? attemptDoc.toObject()
      : { ...attemptDoc };
  const assignment = await ExamAssignment.findById(plain.assignmentId)
    .populate('classroomId', 'name')
    .populate('teacherId', 'fullName username')
    .lean();

  const student = await User.findById(plain.userId).select('fullName username').lean();

  if (plain.examSnapshot && typeof plain.examSnapshot === 'object') {
    let snap = normalizeExamSnapshot(plain.examSnapshot);
    const examRef = assignment?.examId;
    const examId =
      examRef && typeof examRef === 'object' && examRef._id
        ? examRef._id
        : examRef;
    if (examId) {
      const liveExam = await Exam.findById(examId).lean();
      if (liveExam) {
        const healed = healExamSnapshotFromLiveExam(snap, liveExam);
        snap = healed;
        if (attemptDoc?.save && attemptDoc.examSnapshot) {
          const before = JSON.stringify(attemptDoc.examSnapshot?.sections ?? []);
          const after = JSON.stringify(healed.sections ?? []);
          if (before !== after) {
            attemptDoc.examSnapshot = healed;
            attemptDoc.markModified('examSnapshot');
            await attemptDoc.save();
          }
        }
      }
    }
    plain.examSnapshot = snap;
  }
  const snap = plain.examSnapshot || {};
  const classRoom = assignment?.classroomId;
  const classroomName =
    classRoom && typeof classRoom === 'object' && classRoom.name ? String(classRoom.name) : null;

  const teacher = assignment?.teacherId;
  const teacherName =
    teacher && typeof teacher === 'object' && teacher.fullName ? String(teacher.fullName) : null;

  const cfg = assignment?.config || {};
  const allowPartialSubmit = resolveAllowPartialSubmit(assignment, snap);
  plain.runtimeContext = {
    examTitle: snap.title ? String(snap.title) : '',
    subject: cfg.subject != null && cfg.subject !== '' ? String(cfg.subject) : null,
    assignmentMode: assignment?.mode != null ? String(assignment.mode) : null,
    audience: assignment?.audience != null ? String(assignment.audience) : null,
    classroomName,
    teacherName,
    studentName: student?.fullName != null ? String(student.fullName) : null,
    timeLimitSeconds: cfg.timeLimitSeconds != null ? Number(cfg.timeLimitSeconds) : null,
    dueAt: iso(cfg.dueAt),
    opensAt: iso(cfg.opensAt),
    closesAt: iso(cfg.closesAt),
    attemptDeadlineAt: iso(plain.attemptDeadlineAt),
    startedAt: iso(plain.startedAt),
    sessionId: plain.sessionId != null ? String(plain.sessionId) : null,
    allowPartialSubmit,
    partialSubmitConfirm: cfg.partialSubmitConfirm !== false,
    showResultsPolicy: resolveShowResultsPolicy(assignment, snap),
    resultsDetailLevel: resolveResultsDetailLevel(assignment, snap),
    resultsReleased: !!plain.resultsReleased,
  };

  return plain;
}

/** Normalizes populated or raw user refs to a MongoDB ObjectId for queries. */
function resolveMongoUserId(userRef) {
  if (userRef == null) return null;
  if (userRef instanceof mongoose.Types.ObjectId) return userRef;
  if (typeof userRef === 'string') {
    if (!mongoose.isValidObjectId(userRef)) return null;
    return new mongoose.Types.ObjectId(userRef);
  }
  if (typeof userRef === 'object') {
    const raw = userRef._id ?? userRef.id;
    if (raw == null) return null;
    const s = String(raw);
    if (!mongoose.isValidObjectId(s)) return null;
    return new mongoose.Types.ObjectId(s);
  }
  return null;
}

function resolveMongoResourceId(id) {
  if (id == null) return null;
  const s = String(id).trim();
  if (!mongoose.isValidObjectId(s)) return null;
  return new mongoose.Types.ObjectId(s);
}

function skillSectionsFromExam(exam) {
  const out = [];
  for (const sec of exam?.sections || []) {
    if (!sec?.skill) continue;
    const sk = String(sec.skill);
    if (!['listening', 'speaking', 'reading', 'writing'].includes(sk)) continue;
    if (sec.sectionKind === 'skill_content' || sec.sectionKind == null) {
      out.push(sec);
    }
  }
  return out.sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
}

function examTimeBounds(startedAt, endAt) {
  const start = new Date(startedAt);
  const end = new Date(endAt);
  const bufferMs = 15 * 60 * 1000;
  const lookbackMs = 3 * 60 * 60 * 1000;
  return {
    strictStart: start,
    strictEnd: new Date(end.getTime() + bufferMs),
    softStart: new Date(start.getTime() - lookbackMs),
    softEnd: new Date(end.getTime() + bufferMs),
  };
}

function pickLatestDictationPerCue(rows) {
  const byCue = new Map();
  for (const row of rows) {
    const k = row.cueIdx;
    const prev = byCue.get(k);
    const rowT = new Date(row.updatedAt || row.submittedAt || 0).getTime();
    const prevT = prev ? new Date(prev.updatedAt || prev.submittedAt || 0).getTime() : -1;
    if (!prev || rowT >= prevT) byCue.set(k, row);
  }
  return [...byCue.values()].sort((a, b) => Number(a.cueIdx ?? 0) - Number(b.cueIdx ?? 0));
}

async function fetchListeningRecords(userId, listeningId, bounds, opts = {}) {
  const examOnly = opts.examOnly === true;
  const strict = await DictationAttempt.find({
    userId,
    listeningId,
    $or: [
      { updatedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .select('cueIdx userText score submittedAt updatedAt')
    .sort({ cueIdx: 1 })
    .lean();
  if (strict.length > 0) return { records: strict, source: 'exam_window' };
  if (examOnly) return { records: [], source: null };

  const soft = await DictationAttempt.find({
    userId,
    listeningId,
    updatedAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .select('cueIdx userText score submittedAt updatedAt')
    .lean();
  const picked = pickLatestDictationPerCue(soft);
  if (picked.length > 0) return { records: picked, source: 'near_session' };

  const all = await DictationAttempt.find({ userId, listeningId })
    .select('cueIdx userText score submittedAt updatedAt')
    .lean();
  const latest = pickLatestDictationPerCue(all);
  if (latest.length > 0) return { records: latest, source: 'latest_linked' };
  return { records: [], source: null };
}

async function fetchReadingRecord(userId, readingId, bounds, opts = {}) {
  const examOnly = opts.examOnly === true;
  let doc = await ReadingAttempt.findOne({
    userId,
    readingId,
    createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd },
  })
    .sort({ createdAt: -1 })
    .lean();
  if (doc) return { records: doc, source: 'exam_window' };
  if (examOnly) return { records: null, source: null };

  doc = await ReadingAttempt.findOne({
    userId,
    readingId,
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .sort({ createdAt: -1 })
    .lean();
  if (doc) return { records: doc, source: 'near_session' };

  doc = await ReadingAttempt.findOne({ userId, readingId }).sort({ createdAt: -1 }).lean();
  if (doc) return { records: doc, source: 'latest_linked' };
  return { records: null, source: null };
}

async function fetchSpeakingRecords(userId, speakingSetId, bounds, opts = {}) {
  const examOnly = opts.examOnly === true;
  const strict = await SpeakingAttempt.find({
    userId,
    speakingSetId: String(speakingSetId),
    $or: [
      { createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .select('sentenceId userTranscript score submittedAt createdAt')
    .sort({ sentenceId: 1 })
    .lean();
  if (strict.length > 0) return { records: strict, source: 'exam_window' };
  if (examOnly) return { records: [], source: null };

  const soft = await SpeakingAttempt.find({
    userId,
    speakingSetId: String(speakingSetId),
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .select('sentenceId userTranscript score submittedAt createdAt')
    .sort({ sentenceId: 1 })
    .lean();
  if (soft.length > 0) return { records: soft, source: 'near_session' };

  const latest = await SpeakingAttempt.find({ userId, speakingSetId: String(speakingSetId) })
    .select('sentenceId userTranscript score submittedAt createdAt')
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  if (latest.length > 0) return { records: latest, source: 'latest_linked' };
  return { records: [], source: null };
}

async function fetchWritingRecord(userId, topicId, bounds) {
  const statuses = ['draft', 'submitted', 'reviewed'];
  const selectFields = 'content score status submittedAt createdAt feedback wordCount generatedPrompt';
  let doc = await WritingSubmission.findOne({
    userId,
    topicId,
    status: { $in: statuses },
    $or: [
      { createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  if (doc) return { records: doc, source: 'exam_window' };

  doc = await WritingSubmission.findOne({
    userId,
    topicId,
    status: { $in: statuses },
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  if (doc) return { records: doc, source: 'near_session' };

  doc = await WritingSubmission.findOne({ userId, topicId, status: { $in: statuses } })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  if (doc) return { records: doc, source: 'latest_linked' };
  return { records: null, source: null };
}

function groupRowsByKey(rows, keyFn) {
  const map = new Map();
  for (const row of rows) {
    const k = keyFn(row);
    if (!map.has(k)) map.set(k, []);
    map.get(k).push(row);
  }
  return map;
}

/** Batch dictation lookup keyed by listeningId string (P0-B1). */
async function batchFetchListeningRecordsMap(userId, listeningOids, bounds, opts = {}) {
  const map = new Map();
  if (!userId || !bounds || listeningOids.length === 0) return map;
  const examOnly = opts.examOnly === true;
  const oidList = [...new Set(listeningOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );

  const strictRows = await DictationAttempt.find({
    userId,
    listeningId: { $in: oidList },
    $or: [
      { updatedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .select('listeningId cueIdx userText score submittedAt updatedAt')
    .sort({ cueIdx: 1 })
    .lean();

  const strictById = groupRowsByKey(strictRows, (r) => String(r.listeningId));
  const pending = [];
  for (const oid of oidList) {
    const key = oid.toString();
    const strict = strictById.get(key) || [];
    if (strict.length > 0) {
      map.set(key, { records: strict, source: 'exam_window' });
    } else if (!examOnly) {
      pending.push(oid);
    } else {
      map.set(key, { records: [], source: null });
    }
  }
  if (pending.length === 0) return map;

  const softRows = await DictationAttempt.find({
    userId,
    listeningId: { $in: pending },
    updatedAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .select('listeningId cueIdx userText score submittedAt updatedAt')
    .lean();
  const softById = groupRowsByKey(softRows, (r) => String(r.listeningId));
  const stillPending = [];
  for (const oid of pending) {
    const key = oid.toString();
    const picked = pickLatestDictationPerCue(softById.get(key) || []);
    if (picked.length > 0) {
      map.set(key, { records: picked, source: 'near_session' });
    } else {
      stillPending.push(oid);
    }
  }
  if (stillPending.length === 0) return map;

  const allRows = await DictationAttempt.find({
    userId,
    listeningId: { $in: stillPending },
  })
    .select('listeningId cueIdx userText score submittedAt updatedAt')
    .lean();
  const allById = groupRowsByKey(allRows, (r) => String(r.listeningId));
  for (const oid of stillPending) {
    const key = oid.toString();
    const latest = pickLatestDictationPerCue(allById.get(key) || []);
    map.set(key, {
      records: latest,
      source: latest.length > 0 ? 'latest_linked' : null,
    });
  }
  return map;
}

/** Batch reading lookup keyed by readingId string (P0-B1). */
async function batchFetchReadingRecordsMap(userId, readingOids, bounds, opts = {}) {
  const map = new Map();
  if (!userId || !bounds || readingOids.length === 0) return map;
  const examOnly = opts.examOnly === true;
  const oidList = [...new Set(readingOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );

  const strictRows = await ReadingAttempt.find({
    userId,
    readingId: { $in: oidList },
    createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd },
  })
    .sort({ createdAt: -1 })
    .lean();
  const strictById = new Map();
  for (const row of strictRows) {
    const key = String(row.readingId);
    if (!strictById.has(key)) strictById.set(key, row);
  }
  const pending = [];
  for (const oid of oidList) {
    const key = oid.toString();
    if (strictById.has(key)) {
      map.set(key, { records: strictById.get(key), source: 'exam_window' });
    } else if (!examOnly) {
      pending.push(oid);
    } else {
      map.set(key, { records: null, source: null });
    }
  }
  if (pending.length === 0) return map;

  const softRows = await ReadingAttempt.find({
    userId,
    readingId: { $in: pending },
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .sort({ createdAt: -1 })
    .lean();
  const softById = new Map();
  for (const row of softRows) {
    const key = String(row.readingId);
    if (!softById.has(key)) softById.set(key, row);
  }
  const stillPending = [];
  for (const oid of pending) {
    const key = oid.toString();
    if (softById.has(key)) {
      map.set(key, { records: softById.get(key), source: 'near_session' });
    } else {
      stillPending.push(oid);
    }
  }
  if (stillPending.length === 0) return map;

  const latestRows = await ReadingAttempt.find({
    userId,
    readingId: { $in: stillPending },
  })
    .sort({ createdAt: -1 })
    .lean();
  const latestById = new Map();
  for (const row of latestRows) {
    const key = String(row.readingId);
    if (!latestById.has(key)) latestById.set(key, row);
  }
  for (const oid of stillPending) {
    const key = oid.toString();
    const doc = latestById.get(key);
    map.set(key, {
      records: doc ?? null,
      source: doc ? 'latest_linked' : null,
    });
  }
  return map;
}

/** Batch speaking lookup keyed by speakingSetId string (P0-B1). */
async function batchFetchSpeakingRecordsMap(userId, speakingSetIds, bounds, opts = {}) {
  const map = new Map();
  if (!userId || !bounds || speakingSetIds.length === 0) return map;
  const examOnly = opts.examOnly === true;
  const idList = [...new Set(speakingSetIds.map((id) => String(id).trim()).filter(Boolean))];

  const strictRows = await SpeakingAttempt.find({
    userId,
    speakingSetId: { $in: idList },
    $or: [
      { createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .select('speakingSetId sentenceId userTranscript score submittedAt createdAt')
    .sort({ sentenceId: 1 })
    .lean();
  const strictById = groupRowsByKey(strictRows, (r) => String(r.speakingSetId));
  const pending = [];
  for (const id of idList) {
    const strict = strictById.get(id) || [];
    if (strict.length > 0) {
      map.set(id, { records: strict, source: 'exam_window' });
    } else if (!examOnly) {
      pending.push(id);
    } else {
      map.set(id, { records: [], source: null });
    }
  }
  if (pending.length === 0) return map;

  const softRows = await SpeakingAttempt.find({
    userId,
    speakingSetId: { $in: pending },
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .select('speakingSetId sentenceId userTranscript score submittedAt createdAt')
    .sort({ sentenceId: 1 })
    .lean();
  const softById = groupRowsByKey(softRows, (r) => String(r.speakingSetId));
  const stillPending = [];
  for (const id of pending) {
    const soft = softById.get(id) || [];
    if (soft.length > 0) {
      map.set(id, { records: soft, source: 'near_session' });
    } else {
      stillPending.push(id);
    }
  }
  if (stillPending.length === 0) return map;

  const latestRows = await SpeakingAttempt.find({
    userId,
    speakingSetId: { $in: stillPending },
  })
    .select('speakingSetId sentenceId userTranscript score submittedAt createdAt')
    .sort({ createdAt: -1 })
    .lean();
  const latestById = groupRowsByKey(latestRows, (r) => String(r.speakingSetId));
  for (const id of stillPending) {
    const latest = latestById.get(id) || [];
    map.set(id, {
      records: latest.slice(0, 50),
      source: latest.length > 0 ? 'latest_linked' : null,
    });
  }
  return map;
}

/** Batch writing lookup keyed by topicId string (P0-B1). */
async function batchFetchWritingRecordsMap(userId, topicOids, bounds) {
  const map = new Map();
  if (!userId || !bounds || topicOids.length === 0) return map;
  const statuses = ['draft', 'submitted', 'reviewed'];
  const selectFields = 'topicId content score status submittedAt createdAt feedback wordCount generatedPrompt';
  const oidList = [...new Set(topicOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );

  const strictRows = await WritingSubmission.find({
    userId,
    topicId: { $in: oidList },
    status: { $in: statuses },
    $or: [
      { createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
      { submittedAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd } },
    ],
  })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  const strictById = new Map();
  for (const row of strictRows) {
    const key = String(row.topicId);
    if (!strictById.has(key)) strictById.set(key, row);
  }
  const pending = [];
  for (const oid of oidList) {
    const key = oid.toString();
    if (strictById.has(key)) {
      map.set(key, { records: strictById.get(key), source: 'exam_window' });
    } else {
      pending.push(oid);
    }
  }
  if (pending.length === 0) return map;

  const softRows = await WritingSubmission.find({
    userId,
    topicId: { $in: pending },
    status: { $in: statuses },
    createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
  })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  const softById = new Map();
  for (const row of softRows) {
    const key = String(row.topicId);
    if (!softById.has(key)) softById.set(key, row);
  }
  const stillPending = [];
  for (const oid of pending) {
    const key = oid.toString();
    if (softById.has(key)) {
      map.set(key, { records: softById.get(key), source: 'near_session' });
    } else {
      stillPending.push(oid);
    }
  }
  if (stillPending.length === 0) return map;

  const latestRows = await WritingSubmission.find({
    userId,
    topicId: { $in: stillPending },
    status: { $in: statuses },
  })
    .sort({ updatedAt: -1 })
    .select(selectFields)
    .lean();
  const latestById = new Map();
  for (const row of latestRows) {
    const key = String(row.topicId);
    if (!latestById.has(key)) latestById.set(key, row);
  }
  for (const oid of stillPending) {
    const key = oid.toString();
    const doc = latestById.get(key);
    map.set(key, {
      records: doc ?? null,
      source: doc ? 'latest_linked' : null,
    });
  }
  return map;
}

async function batchFetchListeningCuesMap(listeningOids) {
  const map = new Map();
  if (listeningOids.length === 0) return map;
  const oidList = [...new Set(listeningOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );
  const docs = await Listening.find({ _id: { $in: oidList } }).select('cues').lean();
  for (const doc of docs) {
    map.set(String(doc._id), Array.isArray(doc.cues) ? doc.cues : []);
  }
  return map;
}

async function batchFetchReadingQuestionsMap(readingOids) {
  const map = new Map();
  if (readingOids.length === 0) return map;
  const oidList = [...new Set(readingOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );
  const docs = await Reading.find({ _id: { $in: oidList } }).select('questions').lean();
  for (const doc of docs) {
    map.set(String(doc._id), Array.isArray(doc.questions) ? doc.questions : []);
  }
  return map;
}

async function batchFetchListeningCompMaps(userId, compOids, bounds) {
  const docsById = new Map();
  const attemptsById = new Map();
  if (compOids.length === 0) return { docsById, attemptsById };
  const oidList = [...new Set(compOids.map((o) => o.toString()))].map(
    (s) => new mongoose.Types.ObjectId(s)
  );
  const docs = await ListeningComprehension.find({ _id: { $in: oidList } })
    .select('title audioUrl questions')
    .lean();
  for (const doc of docs) {
    docsById.set(String(doc._id), doc);
  }
  if (!userId || !bounds) return { docsById, attemptsById };

  const strictRows = await ListeningCompAttempt.find({
    userId,
    listeningId: { $in: oidList },
    createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd },
  })
    .sort({ createdAt: -1 })
    .lean();
  for (const row of strictRows) {
    const key = String(row.listeningId);
    if (!attemptsById.has(key)) attemptsById.set(key, row);
  }
  const missing = oidList.filter((oid) => !attemptsById.has(oid.toString()));
  if (missing.length > 0) {
    const softRows = await ListeningCompAttempt.find({
      userId,
      listeningId: { $in: missing },
      createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
    })
      .sort({ createdAt: -1 })
      .lean();
    for (const row of softRows) {
      const key = String(row.listeningId);
      if (!attemptsById.has(key)) attemptsById.set(key, row);
    }
  }
  return { docsById, attemptsById };
}

function buildInlineListeningRecordsFromCues(cues, listeningCues, cueOffset = 0) {
  if (!cues.length || !listeningCues) return [];
  const records = [];
  for (let i = 0; i < cues.length; i += 1) {
    const expected = cues[i]?.text != null ? String(cues[i].text) : '';
    const userText = listeningCueTextAt(listeningCues, cueOffset + i);
    const { wer, correctWords, totalWords } = wordErrorRate(expected, userText);
    const passed =
      listeningCueTextIsCorrect(expected, userText) === true || wer <= WER_PASS_THRESHOLD;
    records.push({
      cueIdx: i,
      userText,
      score: { wer, correctWords, totalWords, thresholdWer: WER_PASS_THRESHOLD, passed },
    });
  }
  return records;
}

function buildInlineReadingRecordFromQuestions(questions, readingAnswers) {
  if (!questions.length || !readingAnswers) return null;
  const answers = [];
  let correctCount = 0;
  for (let i = 0; i < questions.length; i += 1) {
    const q = questions[i];
    const qid = q._id != null ? String(q._id) : String(i);
    const chosen = readingChosenForQuestion(readingAnswers, q, i);
    const isCorrect = chosen !== undefined && readingChoiceIsCorrect(q, chosen) === true;
    if (isCorrect) correctCount += 1;
    answers.push({
      questionId: qid,
      chosenIndex: chosen ?? -1,
      isCorrect,
    });
  }
  const totalQuestions = questions.length;
  const score =
    totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 1000) / 10 : 0;
  return { answers, score, correctCount, totalQuestions };
}

function resolveListeningCompRecordForGrading(compDoc, attemptDoc, secAns) {
  if (!compDoc) return null;
  const inlineAnswers = secAns?.listeningCompAnswers;
  if (inlineAnswers && typeof inlineAnswers === 'object' && Object.keys(inlineAnswers).length > 0) {
    return {
      questions: compDoc.questions,
      answers: inlineAnswers,
      audioUrl: compDoc.audioUrl,
      title: compDoc.title,
      source: 'exam_inline',
    };
  }
  if (attemptDoc) {
    const byQid = {};
    for (const a of Array.isArray(attemptDoc.answers) ? attemptDoc.answers : []) {
      byQid[String(a.questionId)] = a.chosenIndex;
    }
    return {
      questions: compDoc.questions,
      answers: byQid,
      audioUrl: compDoc.audioUrl,
      title: compDoc.title,
      source: 'near_session',
    };
  }
  return {
    questions: compDoc.questions,
    answers: {},
    audioUrl: compDoc.audioUrl,
    title: compDoc.title,
    source: null,
  };
}

/** Rebuild per-skill 0–10 scores when legacy attempts lack `skillScores`. */
async function ensureIntegratedScoresOnAttempt(attemptDoc) {
  const exam = attemptDoc.examSnapshot;
  const fmt = exam?.settings?.examFormat;
  if (fmt !== 'integrated_four_skills' && fmt !== 'skills_exam') return attemptDoc;
  if (!['submitted', 'expired'].includes(attemptDoc.status)) return attemptDoc;

  const scores = attemptDoc.scores;
  const skillScores = scores?.skillScores;
  const hasNewFormat =
    skillScores &&
    typeof skillScores === 'object' &&
    Object.keys(skillScores).length > 0 &&
    scores.examFormat;

  // Also rebuild if any exam section is missing from skillScores (e.g. older attempts)
  const skillSections = (exam?.sections || []).filter(
    (s) => s?.skill && (s.sectionKind === 'skill_content' || s.sectionKind == null)
  );
  const hasMissingEntries = hasNewFormat && integratedSkillEntriesMissing(skillSections, skillScores);

  const needsRebuild = !hasNewFormat || integratedAutoScoresStale(scores) || hasMissingEntries;
  if (!needsRebuild) return attemptDoc;

  const plain = attemptDoc.toObject ? attemptDoc.toObject() : attemptDoc;
  const prevSkills = scores?.skillScores || {};
  let integrated = await buildIntegratedScores(plain, exam, scoreGrammarItem);
  integrated = mergePreservedSkillScores(integrated, prevSkills);
  attemptDoc.scores = integrated;
  attemptDoc.markModified('scores');
  if (integrated.finalStatus === 'finalized') {
    attemptDoc.gradingState = 'finalized';
  } else if (attemptDoc.gradingState !== 'finalized') {
    attemptDoc.gradingState = 'pending_manual';
  }
  await attemptDoc.save();
  return attemptDoc;
}

const WER_PASS_THRESHOLD = Number(process.env.WER_PASS_THRESHOLD ?? 0.25);

function normalizeListeningText(s) {
  return String(s ?? '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[''`]/g, "'")
    .replace(/[^a-z0-9'\s]/g, ' ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function listeningCueTextIsCorrect(expectedText, userText) {
  const user = normalizeListeningText(userText);
  if (!user.length) return null;
  const expected = normalizeListeningText(expectedText);
  if (!expected.length) return null;
  return user === expected;
}

function readingChoiceIsCorrect(question, chosenIndex) {
  if (chosenIndex === undefined || chosenIndex === null) return null;
  const correct = Number(question?.correctAnswerIndex);
  if (!Number.isFinite(correct)) return null;
  return Number(chosenIndex) === correct;
}

function listeningCueTextAt(examCues, idx) {
  if (!examCues || typeof examCues !== 'object') return '';
  const raw = examCues[String(idx)] ?? examCues[idx];
  return raw != null ? String(raw).trim() : '';
}

function readingChosenForQuestion(readingAnswers, q, index) {
  if (!readingAnswers || typeof readingAnswers !== 'object') return undefined;
  const qid = q._id != null ? String(q._id) : '';
  if (qid && readingAnswers[qid] !== undefined && readingAnswers[qid] !== null) {
    return Number(readingAnswers[qid]);
  }
  const byIdx = readingAnswers[String(index)];
  return byIdx !== undefined && byIdx !== null ? Number(byIdx) : undefined;
}

/** Build dictation-shaped rows from integrated exam inline `listeningCues`. */
async function buildInlineListeningRecords(listeningId, listeningCues, cueOffset = 0) {
  const doc = await Listening.findById(listeningId).select('cues').lean();
  const cues = Array.isArray(doc?.cues) ? doc.cues : [];
  if (!cues.length || !listeningCues) return [];

  const records = [];
  for (let i = 0; i < cues.length; i += 1) {
    const expected = cues[i]?.text != null ? String(cues[i].text) : '';
    const userText = listeningCueTextAt(listeningCues, cueOffset + i);
    const { wer, correctWords, totalWords } = wordErrorRate(expected, userText);
    const passed =
      listeningCueTextIsCorrect(expected, userText) === true || wer <= WER_PASS_THRESHOLD;
    records.push({
      cueIdx: i,
      userText,
      score: { wer, correctWords, totalWords, thresholdWer: WER_PASS_THRESHOLD, passed },
    });
  }
  return records;
}

/**
 * Fetch Listening Comprehension questions + student answers for teacher grading display.
 * Returns { questions, answers, audioUrl, title, source } or null if not found.
 */
async function fetchListeningCompRecordForGrading(userId, listCompId, bounds, secAns) {
  const oid = resolveMongoResourceId(listCompId);
  if (!oid) return null;

  const lc = await ListeningComprehension.findById(oid)
    .select('title audioUrl questions')
    .lean();
  if (!lc) return null;

  // Prefer inline answers from exam attempt (most accurate — no cross-attempt confusion)
  const inlineAnswers = secAns?.listeningCompAnswers;
  if (inlineAnswers && typeof inlineAnswers === 'object' && Object.keys(inlineAnswers).length > 0) {
    return {
      questions: lc.questions,
      answers: inlineAnswers,
      audioUrl: lc.audioUrl,
      title: lc.title,
      source: 'exam_inline',
    };
  }

  // Fallback: query ListeningCompAttempt within exam window (strict, then near-session)
  if (userId && bounds) {
    let attemptDoc = await ListeningCompAttempt.findOne({
      userId,
      listeningId: oid,
      createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd },
    })
      .sort({ createdAt: -1 })
      .lean();

    if (!attemptDoc) {
      attemptDoc = await ListeningCompAttempt.findOne({
        userId,
        listeningId: oid,
        createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
      })
        .sort({ createdAt: -1 })
        .lean();
    }

    if (attemptDoc) {
      const byQid = {};
      for (const a of Array.isArray(attemptDoc.answers) ? attemptDoc.answers : []) {
        byQid[String(a.questionId)] = a.chosenIndex;
      }
      return {
        questions: lc.questions,
        answers: byQid,
        audioUrl: lc.audioUrl,
        title: lc.title,
        source: 'near_session',
      };
    }
  }

  // No answers found — return questions only (teacher can still see the exercise)
  return {
    questions: lc.questions,
    answers: {},
    audioUrl: lc.audioUrl,
    title: lc.title,
    source: null,
  };
}

/** Build reading-attempt-shaped doc from integrated exam inline `readingAnswers`. */
async function buildInlineReadingRecord(readingId, readingAnswers) {
  const doc = await Reading.findById(readingId).select('questions').lean();
  const questions = Array.isArray(doc?.questions) ? doc.questions : [];
  if (!questions.length || !readingAnswers) return null;

  const answers = [];
  let correctCount = 0;
  for (let i = 0; i < questions.length; i += 1) {
    const q = questions[i];
    const qid = q._id != null ? String(q._id) : String(i);
    const chosen = readingChosenForQuestion(readingAnswers, q, i);
    const isCorrect = chosen !== undefined && readingChoiceIsCorrect(q, chosen) === true;
    if (isCorrect) correctCount += 1;
    answers.push({
      questionId: qid,
      chosenIndex: chosen ?? -1,
      isCorrect,
    });
  }
  const totalQuestions = questions.length;
  const score =
    totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 1000) / 10 : 0;
  return { answers, score, correctCount, totalQuestions };
}

/** Latest CMS skill work during this exam attempt window (for teacher grading UI). */
async function attachSkillWorkForGrading(attemptDoc) {
  // Resolve student id from the Mongoose doc (populate uses `id` in JSON, not `_id`).
  const userId = resolveMongoUserId(attemptDoc.userId);

  const plain = attemptDoc.toJSON
    ? attemptDoc.toJSON()
    : typeof attemptDoc.toObject === 'function'
      ? attemptDoc.toObject()
      : { ...attemptDoc };

  const startedAt = plain.startedAt ? new Date(plain.startedAt) : null;
  const endAt = plain.submittedAt ? new Date(plain.submittedAt) : new Date();
  const exam = plain.examSnapshot || {};
  const skillWork = {};

  const hasTimeWindow =
    userId && startedAt && !Number.isNaN(startedAt.getTime());
  const bounds = hasTimeWindow ? examTimeBounds(startedAt, endAt) : null;
  const sections = skillSectionsFromExam(exam);

  const listeningOids = [];
  const compOids = [];
  const readingOids = [];
  const speakingIds = [];
  const writingOids = [];

  for (const sec of sections) {
    for (const res of resourcesFromSkillSection(sec)) {
      const resourceOid = resolveMongoResourceId(res.id);
      if (!resourceOid) continue;
      switch (sec.skill) {
        case 'listening':
          if ((sec.sectionConfig?.listeningType || 'dictation') === 'comprehension') {
            compOids.push(resourceOid);
          } else {
            listeningOids.push(resourceOid);
          }
          break;
        case 'reading':
          readingOids.push(resourceOid);
          break;
        case 'speaking':
          speakingIds.push(String(res.id).trim());
          break;
        case 'writing':
          writingOids.push(resourceOid);
          break;
        default:
          break;
      }
    }
  }

  const [
    listeningMap,
    readingMap,
    speakingMap,
    writingMap,
    listeningCuesMap,
    readingQuestionsMap,
    listeningCompMaps,
  ] = await Promise.all([
    bounds && userId
      ? batchFetchListeningRecordsMap(userId, listeningOids, bounds)
      : Promise.resolve(new Map()),
    bounds && userId
      ? batchFetchReadingRecordsMap(userId, readingOids, bounds)
      : Promise.resolve(new Map()),
    bounds && userId
      ? batchFetchSpeakingRecordsMap(userId, speakingIds, bounds)
      : Promise.resolve(new Map()),
    bounds && userId
      ? batchFetchWritingRecordsMap(userId, writingOids, bounds)
      : Promise.resolve(new Map()),
    batchFetchListeningCuesMap(listeningOids),
    batchFetchReadingQuestionsMap(readingOids),
    batchFetchListeningCompMaps(userId, compOids, bounds),
  ]);

  for (const sec of sections) {
    const sid = String(sec.sectionId || '').trim();
    if (!sid) continue;
    const secAns =
      plain.answers?.[sid] && typeof plain.answers[sid] === 'object'
        ? plain.answers[sid]
        : null;
    const resources = [];
    let listeningCueOffset = 0;
    for (const res of resourcesFromSkillSection(sec)) {
      const resourceOid = resolveMongoResourceId(res.id);
      if (!resourceOid) continue;
      const resourceKey = resourceOid.toString();

      let records = null;
      let source = null;
      switch (sec.skill) {
        case 'listening': {
          const listeningType = sec.sectionConfig?.listeningType || 'dictation';
          if (listeningType === 'comprehension') {
            const compRecord = resolveListeningCompRecordForGrading(
              listeningCompMaps.docsById.get(resourceKey),
              listeningCompMaps.attemptsById.get(resourceKey),
              secAns
            );
            if (compRecord) {
              records = compRecord;
              source = compRecord.source || null;
            }
          } else {
            if (bounds && userId) {
              const cached = listeningMap.get(resourceKey);
              records = cached?.records;
              source = cached?.source ?? null;
            } else {
              records = [];
            }
            if ((!records || records.length === 0) && secAns?.listeningCues) {
              const cues = listeningCuesMap.get(resourceKey) || [];
              const inline = buildInlineListeningRecordsFromCues(
                cues,
                secAns.listeningCues,
                listeningCueOffset
              );
              if (inline.length > 0) {
                records = inline;
                source = 'exam_inline';
              }
            }
            listeningCueOffset += (listeningCuesMap.get(resourceKey) || []).length;
          }
          break;
        }
        case 'reading': {
          if (bounds && userId) {
            const cached = readingMap.get(resourceKey);
            records = cached?.records;
            source = cached?.source ?? null;
          }
          if (!records && secAns?.readingAnswers) {
            const questions = readingQuestionsMap.get(resourceKey) || [];
            const inline = buildInlineReadingRecordFromQuestions(questions, secAns.readingAnswers);
            if (inline) {
              records = inline;
              source = 'exam_inline';
            }
          }
          break;
        }
        case 'speaking': {
          if (bounds && userId) {
            const speakKey = String(res.id).trim();
            const cached = speakingMap.get(speakKey);
            const spSrc = cached?.source;
            if (spSrc !== 'latest_linked') {
              records = cached?.records ?? [];
              source = spSrc ?? null;
            } else {
              records = [];
              source = null;
            }
          } else {
            records = [];
          }
          break;
        }
        case 'writing': {
          if (bounds && userId) {
            const cached = writingMap.get(resourceKey);
            if (cached?.records) {
              const hasContent = String(cached.records.content ?? '').trim().length > 0;
              const hasPrompt = cached.records.generatedPrompt?.text || cached.records.generatedPrompt?.title;
              if (hasContent || hasPrompt) {
                records = cached.records;
                source = cached.source;
              }
            }
          }
          if (!records && secAns?.writingDraft) {
            records = {
              content: String(secAns.writingDraft),
              status: 'submitted',
              wordCount: String(secAns.writingDraft).trim().split(/\s+/).filter(Boolean).length,
            };
            source = 'exam_inline';
          }
          break;
        }
        default:
          break;
      }
      resources.push({
        resourceId: res.id,
        title: res.title,
        records: records ?? (sec.skill === 'listening' || sec.skill === 'speaking' ? [] : null),
        source,
      });
    }
    skillWork[sid] = { skill: sec.skill, resources };
  }

  plain.skillWork = skillWork;
  return plain;
}

export {
  computeAttemptDeadline,
  examTimeBounds,
  fetchListeningRecords,
  fetchReadingRecord,
  fetchSpeakingRecords,
  fetchWritingRecord,
  resolveMongoResourceId,
  resolveMongoUserId,
  resourcesFromSkillSection,
  skillSectionsFromExam,
};

export const examAttemptService = {
  walkItems,

  /** Mark overdue in_progress attempts (used by cron). */
  async bulkExpirePastDeadline() {
    const now = new Date();
    const res = await ExamAttempt.updateMany(
      { status: 'in_progress', attemptDeadlineAt: { $lte: now } },
      { $set: { status: 'expired' } }
    );
    return res.modifiedCount ?? 0;
  },

  async getAttemptForTeacherGrading(teacherId, attemptId) {
    const attempt = await ExamAttempt.findById(attemptId)
      .populate({
        path: 'assignmentId',
        select: 'teacherId mode',
      })
      .populate({
        path: 'userId',
        select: 'fullName username email',
      });
    if (!attempt) throw httpError(404, 'Attempt not found');
    const a = attempt.assignmentId;
    if (!a) throw httpError(404, 'Assignment not found');
    await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, a._id.toString());
    await ensureIntegratedScoresOnAttempt(attempt);
    return attachSkillWorkForGrading(attempt);
  },

  async startAttempt(userId, assignmentId, opts = {}) {
    const { publicToken } = opts;
    const assignment = await teacherExamAssignmentService.assertStudentEntitled(userId, assignmentId, { publicToken });

    if (assignment.mode === 'realtime') {
      throw httpError(400, 'Realtime exams use the session join flow');
    }

    const existing = await ExamAttempt.findOne({
      assignmentId: assignment._id,
      userId,
      status: 'in_progress',
    });
    if (existing) return existing;

    if (assignment.mode !== 'practice') {
      if (assignment.mode === 'scheduled') {
        const opens = assignment.config?.opensAt ? new Date(assignment.config.opensAt).getTime() : null;
        const closes = assignment.config?.closesAt ? new Date(assignment.config.closesAt).getTime() : null;
        const now = Date.now();
        if (opens != null && now < opens) throw httpError(400, 'Exam has not opened yet');
        if (closes != null && now > closes) throw httpError(400, 'Exam window is closed');
      }

      if (assignment.mode === 'self_paced') {
        const due = assignment.config?.dueAt ? new Date(assignment.config.dueAt).getTime() : null;
        if (due && due < Date.now()) throw httpError(400, 'Assignment is past due date');
      }
    }

    const exam = assignment.examId;
    if (!exam) throw httpError(500, 'Exam missing on assignment');

    const attemptPolicy = resolveAttemptPolicy(assignment, exam);
    if (assignment.mode !== 'practice') {
      const submittedCount = await ExamAttempt.countDocuments({
        assignmentId: assignment._id,
        userId,
        status: { $in: ['submitted', 'expired'] },
      });

      if (attemptPolicy.kind === 'single') {
        if (submittedCount > 0) throw httpError(400, 'Already submitted');
      } else if (attemptPolicy.kind === 'limited') {
        if (submittedCount >= attemptPolicy.max) {
          throw httpError(400, 'Maximum attempts reached');
        }
      }
    }

    if (assignment.audience === 'public_link') {
      await teacherExamAssignmentService.consumePublicStartSlot(assignment._id);
    }

    let snapshot = exam.toObject ? exam.toObject() : exam;
    delete snapshot._id;
    snapshot = normalizeExamSnapshot(snapshot);

    const startedAt = new Date();
    const attemptDeadlineAt = computeAttemptDeadline(assignment, startedAt);

    const attempt = await ExamAttempt.create({
      assignmentId: assignment._id,
      userId,
      examSnapshot: snapshot,
      status: 'in_progress',
      startedAt,
      attemptDeadlineAt,
      answers: {},
      gradingState: 'pending_auto',
    });
    return attempt;
  },

  async patchAnswers(userId, attemptId, answersPatch) {
    const attempt = await ExamAttempt.findById(attemptId);
    if (!attempt) throw httpError(404, 'Attempt not found');
    await lazyExpireIfNeeded(attempt);
    if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
    if (attempt.status !== 'in_progress') throw httpError(400, 'Attempt is not editable');

    if (attempt.meta?.canAnswer === false) throw httpError(400, 'Answers are locked for this attempt');

    if (attempt.attemptDeadlineAt && new Date(attempt.attemptDeadlineAt).getTime() < Date.now()) {
      throw httpError(400, 'Attempt time limit has expired');
    }

    const assignment = await ExamAssignment.findById(attempt.assignmentId);
    const due = assignment?.config?.dueAt ? new Date(assignment.config.dueAt) : null;
    if (assignment?.mode === 'self_paced' && due && due.getTime() < Date.now()) {
      throw httpError(400, 'Past due date');
    }

    attempt.answers = { ...(attempt.answers || {}), ...(answersPatch || {}) };
    const prevMeta = attempt.meta && typeof attempt.meta === 'object' ? { ...attempt.meta } : {};
    const prevLiveView = prevMeta.liveView && typeof prevMeta.liveView === 'object' ? { ...prevMeta.liveView } : {};
    if (isAdaptiveExamSnapshot(attempt.examSnapshot)) {
      const items = walkItems(attempt.examSnapshot.sections || []);
      attempt.meta = { ...computeAdaptiveState(attempt, items), liveView: prevLiveView };
    }
    await attempt.save();
    await broadcastAttemptProgress(attempt);
    return attempt;
  },

  async submit(userId, attemptId, opts = {}) {
    const force = opts.force === true;
    const forceEnd = opts.forceEnd === true;
    const attempt = await ExamAttempt.findById(attemptId);
    if (!attempt) throw httpError(404, 'Attempt not found');
    if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
    await lazyExpireIfNeeded(attempt);
    if (attempt.status !== 'in_progress') throw httpError(400, 'Already submitted');

    if (!forceEnd) {
      await assertLiveSessionAllowsEdits(attempt);
    }

    const assignment = await ExamAssignment.findById(attempt.assignmentId);
    const exam = attempt.examSnapshot;

    if (!force) {
      if (attempt.attemptDeadlineAt && new Date(attempt.attemptDeadlineAt).getTime() < Date.now()) {
        attempt.status = 'expired';
        await attempt.save();
        throw httpError(400, 'Attempt time limit has expired');
      }

      const due = assignment?.config?.dueAt ? new Date(assignment.config.dueAt) : null;
      if (assignment?.mode === 'self_paced' && due && due.getTime() < Date.now()) {
        attempt.status = 'expired';
        await attempt.save();
        throw httpError(400, 'Past due date');
      }
    }

    const allowPartialSubmit = forceEnd || resolveAllowPartialSubmit(assignment, exam);

    attempt.status = 'submitted';
    attempt.submittedAt = new Date();

    const examFormat = exam?.settings?.examFormat;
    if (examFormat === 'integrated_four_skills' || examFormat === 'skills_exam') {
      const skillSections = walkSkillContentSections(exam.sections || []).sort(
        (a, b) => Number(a.order ?? 0) - Number(b.order ?? 0)
      );
      const grammarItems = Array.isArray(exam.settings?.grammarItems) ? exam.settings.grammarItems : [];

      if (examFormat === 'integrated_four_skills' && skillSections.length !== 4) {
        throw httpError(500, 'Integrated exam snapshot is invalid');
      }

      if (!forceEnd && !allowPartialSubmit) {
        for (const it of grammarItems) {
          const ans = attempt.answers[it.itemId];
          if (!grammarAnswerComplete(it, ans)) {
            throw httpError(400, 'Complete all Grammar questions before submitting');
          }
        }

        for (const sec of skillSections) {
          const sid = String(sec.sectionId);
          const ans = attempt.answers[sid];
          const done = ans && typeof ans === 'object' && ans.completed === true;
          if (!done) {
            const msg =
              examFormat === 'integrated_four_skills'
                ? 'Mark all four skill parts as completed before submitting'
                : 'Mark all selected skill parts as completed before submitting';
            throw httpError(400, msg);
          }
        }
      }

      let submitCompleteness = 'complete';
      if (forceEnd) submitCompleteness = 'force_end';
      else if (!integratedAttemptAllPartsDone(attempt, exam)) submitCompleteness = 'partial';
      attempt.meta = { ...(attempt.meta || {}), submitCompleteness };

      // Build per-skill 0–10 scores (auto for grammar/listening/reading, pending for speaking/writing)
      const integratedScores = await buildIntegratedScores(
        attempt.toObject ? attempt.toObject() : attempt,
        exam,
        scoreGrammarItem
      );
      attempt.scores = integratedScores;
      attempt.gradingState =
        integratedScores.finalStatus === 'finalized' ? 'finalized' : 'pending_manual';
      attempt.resultsReleased =
        assignment?.mode === 'practice' || resolveShowResultsPolicy(assignment, exam) === 'after_submit';
      await attempt.save();
      await broadcastAttemptProgress(attempt);
      await afterAttemptActivity(attempt, assignment);
      return attempt;
    }

    const items = walkItems(exam.sections || []);
    const itemResults = {};
    let totalAwarded = 0;
    let totalMax = 0;
    let needsManual = false;

    for (const it of items) {
      const max = Number(it.points ?? 1);
      if (['reading', 'listening'].includes(it.kind)) continue;
      totalMax += max;
      const ans = attempt.answers[it.itemId];
      let awarded = 0;
      let status = 'finalized';

      if (it.kind === 'mcq_single' || it.kind === 'mcq_multi') {
        awarded = scoreMcq(it, ans);
      } else if (it.kind === 'fill_blank') {
        awarded = scoreFillBlank(it, ans);
      } else if (['essay', 'speaking'].includes(it.kind)) {
        awarded = 0;
        needsManual = true;
        status = 'pending_manual';
      } else {
        totalMax -= max;
        continue;
      }

      totalAwarded += awarded;
      itemResults[it.itemId] = {
        kind: it.kind,
        maxPoints: max,
        awardedPoints: awarded,
        status,
      };
    }

    attempt.scores = {
      totalAwarded,
      totalMax,
      items: itemResults,
    };
    attempt.gradingState =
      assignment?.mode === 'practice' ? 'finalized' : needsManual ? 'pending_manual' : 'finalized';
    attempt.resultsReleased =
      assignment?.mode === 'practice' ||
      (resolveShowResultsPolicy(assignment, exam) === 'after_submit' && !needsManual);

    const classicComplete = items.every((it) => {
      if (['reading', 'listening'].includes(it.kind)) return true;
      const ans = attempt.answers[it.itemId];
      if (['essay', 'speaking'].includes(it.kind)) return ans && String(ans.text || '').trim().length > 0;
      if (it.kind === 'mcq_single' || it.kind === 'mcq_multi') {
        return Array.isArray(ans?.selectedIndexes) && ans.selectedIndexes.length > 0;
      }
      if (it.kind === 'fill_blank') return true;
      return true;
    });
    attempt.meta = {
      ...(attempt.meta || {}),
      submitCompleteness: forceEnd ? 'force_end' : classicComplete ? 'complete' : 'partial',
    };

    await attempt.save();
    await broadcastAttemptProgress(attempt);
    await afterAttemptActivity(attempt, assignment);
    return attempt;
  },

  async getAttemptForStudent(userId, attemptId) {
    const attempt = await ExamAttempt.findById(attemptId);
    if (!attempt) throw httpError(404, 'Attempt not found');
    if (attempt.userId.toString() !== userId.toString()) throw httpError(403, 'Forbidden');
    return attachRuntimeContextToAttempt(attempt);
  },

  async buildStudentAttemptJson(attemptDoc) {
    return attachRuntimeContextToAttempt(attemptDoc);
  },

  async listAttemptsForTeacher(teacherId, assignmentId) {
    const hub = await this.getAssignmentGradingHub(teacherId, assignmentId);
    return hub.attempts;
  },

  async getAssignmentGradingHub(teacherId, assignmentId) {
    const assignment = await teacherExamAssignmentService.assertTeacherOwnsAssignment(
      teacherId,
      assignmentId
    );
    await assignment.populate('examId', 'title settings');
    await assignment.populate('classroomId', 'name');

    const attempts = await ExamAttempt.find({ assignmentId: assignment._id })
      .sort({ submittedAt: -1, updatedAt: -1 })
      .populate('userId', 'fullName email username')
      .lean();

    const stats = {
      total: 0,
      submitted: 0,
      inProgress: 0,
      pendingManual: 0,
      finalized: 0,
      released: 0,
      partial: 0,
    };

    const rows = attempts.map((plain) => {
      stats.total += 1;
      if (plain.status === 'submitted') stats.submitted += 1;
      if (plain.status === 'in_progress') stats.inProgress += 1;
      if (plain.gradingState === 'pending_manual') stats.pendingManual += 1;
      if (plain.gradingState === 'finalized') stats.finalized += 1;
      if (plain.resultsReleased) stats.released += 1;
      if (plain.meta?.submitCompleteness === 'partial') stats.partial += 1;
      return plain;
    });

    const exam = assignment.examId;
    const classroom = assignment.classroomId;

    const classroomId =
      classroom && typeof classroom === 'object' && classroom._id
        ? String(classroom._id)
        : assignment.classroomId
          ? String(assignment.classroomId)
          : null;

    return {
      assignment: {
        id: assignment._id.toString(),
        mode: assignment.mode,
        audience: assignment.audience,
        examTitle: exam?.title ? String(exam.title) : '',
        examFormat: exam?.settings?.examFormat ?? null,
        classroomId,
        classroomName:
          classroom && typeof classroom === 'object' && classroom.name
            ? String(classroom.name)
            : null,
        config: assignment.config || {},
      },
      attempts: rows,
      stats,
    };
  },
};
