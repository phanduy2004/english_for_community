/**
 * D4 — examSnapshot dedup: một bản frozen / assignment, resolve cho API (giữ contract).
 */
import Exam from '../models/Exam.js';
import ExamAssignment from '../models/ExamAssignment.js';
import {
  healExamSnapshotFromLiveExam,
  normalizeExamSnapshot,
} from './examSkillSectionResources.js';

export function buildSnapshotFromExam(exam) {
  if (!exam) return null;
  const raw = exam.toObject ? exam.toObject() : { ...exam };
  delete raw._id;
  delete raw.__v;
  delete raw.createdAt;
  delete raw.updatedAt;
  return normalizeExamSnapshot(raw);
}

export function stableSnapshotString(snapshot) {
  const norm = normalizeExamSnapshot(snapshot || {});
  const sortKeys = (v) => {
    if (v === null || typeof v !== 'object') return v;
    if (Array.isArray(v)) return v.map(sortKeys);
    return Object.keys(v)
      .sort()
      .reduce((acc, k) => {
        acc[k] = sortKeys(v[k]);
        return acc;
      }, {});
  };
  return JSON.stringify(sortKeys(norm));
}

export function snapshotsDeepEqual(a, b) {
  return stableSnapshotString(a) === stableSnapshotString(b);
}

/** Đọc snapshot đã lưu: assignment frozen → fallback attempt/session copy cũ. */
export function resolveStoredSnapshot({ assignment, attempt, session } = {}) {
  const fromAssignment = assignment?.examSnapshot;
  if (fromAssignment && typeof fromAssignment === 'object') {
    return normalizeExamSnapshot(fromAssignment);
  }
  const fromSession = session?.examSnapshot;
  if (fromSession && typeof fromSession === 'object') {
    return normalizeExamSnapshot(fromSession);
  }
  const fromAttempt = attempt?.examSnapshot;
  if (fromAttempt && typeof fromAttempt === 'object') {
    return normalizeExamSnapshot(fromAttempt);
  }
  return null;
}

export async function loadAssignmentSnapshot(assignmentId) {
  if (!assignmentId) return null;
  const a = await ExamAssignment.findById(assignmentId).select('examSnapshot examId').lean();
  return resolveStoredSnapshot({ assignment: a });
}

/**
 * Đảm bảo assignment có examSnapshot frozen (từ Exam hiện tại nếu chưa có).
 */
export async function ensureAssignmentFrozenSnapshot(assignmentId, { exam } = {}) {
  const assignment = await ExamAssignment.findById(assignmentId).populate('examId');
  if (!assignment) return null;

  if (assignment.examSnapshot && typeof assignment.examSnapshot === 'object') {
    return normalizeExamSnapshot(assignment.examSnapshot);
  }

  const examDoc = exam || assignment.examId;
  const snapshot = buildSnapshotFromExam(examDoc);
  if (!snapshot) return null;

  assignment.examSnapshot = snapshot;
  assignment.examSnapshotFrozenAt = new Date();
  assignment.markModified('examSnapshot');
  await assignment.save();
  return snapshot;
}

/**
 * Heal snapshot từ live exam; persist chỉ lên assignment (D4 contract).
 */
export async function healPersistSnapshot({ assignmentId, snapshot, liveExam }) {
  let snap = normalizeExamSnapshot(snapshot);
  if (liveExam) {
    snap = healExamSnapshotFromLiveExam(snap, liveExam);
  }

  const assignment = await ExamAssignment.findById(assignmentId);
  if (assignment) {
    const before = stableSnapshotString(assignment.examSnapshot);
    const after = stableSnapshotString(snap);
    if (before !== after) {
      assignment.examSnapshot = snap;
      if (!assignment.examSnapshotFrozenAt) assignment.examSnapshotFrozenAt = new Date();
      assignment.markModified('examSnapshot');
      await assignment.save();
    }
  }

  return snap;
}

/** Gắn snapshot từ assignment lên doc in-memory (không ghi DB). */
export async function loadSnapshotOntoAttemptDoc(attemptDoc, { heal = true } = {}) {
  if (!attemptDoc) return null;
  const snap = await resolveSnapshotForAttemptDoc(attemptDoc, { heal });
  if (snap) attemptDoc.examSnapshot = snap;
  return snap;
}

/**
 * Resolve + optional heal cho attempt (student/teacher API).
 */
export async function resolveSnapshotForAttemptDoc(attemptDoc, { heal = true } = {}) {
  const assignmentId = attemptDoc.assignmentId?._id ?? attemptDoc.assignmentId;
  const assignment = assignmentId
    ? await ExamAssignment.findById(assignmentId).select('examSnapshot examId').lean()
    : null;

  let snap =
    resolveStoredSnapshot({ assignment, attempt: attemptDoc }) ||
    (assignmentId ? await loadAssignmentSnapshot(assignmentId) : null);

  if (!snap && assignmentId) {
    snap = await ensureAssignmentFrozenSnapshot(assignmentId);
  }

  if (!snap) return null;

  if (heal && assignment?.examId) {
    const examId =
      assignment.examId && typeof assignment.examId === 'object' && assignment.examId._id
        ? assignment.examId._id
        : assignment.examId;
    const liveExam = examId ? await Exam.findById(examId).lean() : null;
    if (liveExam) {
      return healPersistSnapshot({
        assignmentId,
        snapshot: snap,
        liveExam,
      });
    }
    if (liveExam) {
      snap = healExamSnapshotFromLiveExam(snap, liveExam);
    }
  }

  return snap;
}

/** Gắn snapshot đã resolve vào plain object (API output). */
export function attachResolvedSnapshotToPlain(plain, snapshot) {
  if (snapshot && typeof snapshot === 'object') {
    plain.examSnapshot = snapshot;
  }
  return plain;
}

/** Hydrate lean attempt (live monitor) từ assignment frozen snapshot. */
export async function hydrateLeanAttemptSnapshot(attempt) {
  if (!attempt) return attempt;
  const assignmentId = attempt.assignmentId?._id ?? attempt.assignmentId;
  if (!assignmentId) return attempt;
  const fromAssignment = await loadAssignmentSnapshot(assignmentId);
  if (fromAssignment) {
    attempt.examSnapshot = fromAssignment;
  }
  return attempt;
}

