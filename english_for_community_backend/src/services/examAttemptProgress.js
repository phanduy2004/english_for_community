import { walkItems } from './teacherExamService.js';

/** Normalize populate/ObjectId/string refs to a 24-char hex id string. */
export function refToMongoIdString(ref) {
  if (ref == null || ref === '') return null;
  if (typeof ref === 'string') return ref;
  if (typeof ref === 'object') {
    const raw = ref._id ?? ref.id;
    if (raw != null) return String(raw);
  }
  try {
    const s = String(ref);
    return s === '[object Object]' ? null : s;
  } catch {
    return null;
  }
}

function isItemAnswered(item, ans) {
  if (!ans) return false;
  if (item.kind === 'mcq_single' || item.kind === 'mcq_multi') {
    return Array.isArray(ans.selectedIndexes) && ans.selectedIndexes.length > 0;
  }
  if (item.kind === 'fill_blank' || item.kind === 'grammar_cloze') return true;
  if (['essay', 'speaking'].includes(item.kind)) {
    return String(ans.text || '').trim().length > 0;
  }
  return true;
}

export function computeAttemptProgress(attempt) {
  const items = walkItems(attempt.examSnapshot?.sections || []);
  const answerable = items.filter((it) => !['reading', 'listening'].includes(it.kind));
  const answers = attempt.answers || {};
  let answered = 0;
  for (const it of answerable) {
    if (isItemAnswered(it, answers[it.itemId])) answered += 1;
  }
  const total = answerable.length || 1;
  return {
    answeredCount: answered,
    totalItems: answerable.length,
    progressPercent: Math.min(100, Math.round((answered / total) * 1000) / 10),
  };
}

export function computeCurrentFocus(attempt) {
  const items = walkItems(attempt.examSnapshot?.sections || []);
  const answerable = items.filter((it) => !['reading', 'listening'].includes(it.kind));
  const answers = attempt.answers || {};
  for (const it of answerable) {
    if (!isItemAnswered(it, answers[it.itemId])) {
      const label =
        (typeof it.prompt === 'string' && it.prompt.trim()) ||
        (typeof it.title === 'string' && it.title.trim()) ||
        (typeof it.stem === 'string' && it.stem.trim()) ||
        '';
      return {
        currentItemId: it.itemId,
        currentItemKind: it.kind,
        currentItemLabel: label.length > 80 ? `${label.slice(0, 77)}…` : label,
      };
    }
  }
  return { currentItemId: null, currentItemKind: null, currentItemLabel: '' };
}

/**
 * Grammar MCQ answers with correctness check for teacher live monitor.
 */
export function computeGrammarAnswers(attempt) {
  const snap = attempt.examSnapshot || {};
  const settings = snap.settings || {};
  const grammarItems = Array.isArray(settings.grammarItems) ? settings.grammarItems : [];
  const answers = attempt.answers || {};
  return grammarItems.map((it) => {
    const ans = answers[it.itemId];
    const selected = Array.isArray(ans?.selectedIndexes)
      ? ans.selectedIndexes.map(Number)
      : Array.isArray(ans?.blanks)
        ? ans.blanks
        : null;
    const correct = Array.isArray(it.correctOptionIndexes)
      ? it.correctOptionIndexes.map(Number).sort((a, b) => a - b)
      : null;
    const answered = selected != null && (Array.isArray(selected) ? selected.length > 0 : true);
    let isCorrect = null;
    if (answered && correct != null && Array.isArray(selected)) {
      const sortedSel = [...selected].sort((a, b) => a - b);
      isCorrect =
        sortedSel.length === correct.length && sortedSel.every((v, i) => v === correct[i]);
    }
    const options = Array.isArray(it.options)
      ? it.options.map((o) => (typeof o === 'string' ? o : o?.text ?? String(o)))
      : [];
    return {
      itemId: it.itemId,
      kind: it.kind || 'mcq_single',
      answered,
      selectedIndexes: Array.isArray(selected) ? selected : [],
      correctOptionIndexes: correct || [],
      isCorrect,
      options,
    };
  });
}

/**
 * Skill section completion status for teacher live monitor.
 */
export function computeSectionStatus(attempt) {
  const snap = attempt.examSnapshot || {};
  const sections = Array.isArray(snap.sections) ? snap.sections : [];
  const answers = attempt.answers || {};
  return sections
    .filter((s) => s?.skill && (s.sectionKind === 'skill_content' || !s.sectionKind))
    .sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0))
    .map((s) => {
      const sid = String(s.sectionId || '');
      const ans = answers[sid];
      const completed = ans && typeof ans === 'object' && ans.completed === true;
      return { sectionId: sid, skill: s.skill, completed };
    });
}

/**
 * Row for teacher live monitor UI + socket `exam_session_live_progress`.
 */
export function buildAttemptLiveProgressRow(attempt, userLean = null) {
  const progress = computeAttemptProgress(attempt);
  const focus = computeCurrentFocus(attempt);
  const integrity = attempt.integrity && typeof attempt.integrity === 'object' ? attempt.integrity : {};
  const u =
    userLean && typeof userLean === 'object'
      ? userLean
      : attempt.userId && typeof attempt.userId === 'object'
        ? attempt.userId
        : null;
  const userId =
    refToMongoIdString(u?._id ?? attempt.userId) ??
    (attempt.userId != null ? String(attempt.userId) : '');

  return {
    attemptId: attempt._id != null ? String(attempt._id) : '',
    assignmentId: refToMongoIdString(attempt.assignmentId) ?? '',
    sessionId: refToMongoIdString(attempt.sessionId),
    userId,
    fullName: u?.fullName || '',
    email: u?.email || '',
    username: u?.username || '',
    status: attempt.status,
    gradingState: attempt.gradingState || null,
    submittedAt: attempt.submittedAt ? new Date(attempt.submittedAt).toISOString() : null,
    lastActivityAt: attempt.updatedAt ? new Date(attempt.updatedAt).toISOString() : null,
    ...progress,
    ...focus,
    integrityRiskLevel: integrity.riskLevel || 'low',
    tabSwitchCount: Number(integrity.tabSwitchCount || 0),
    focusLossSeconds: Number(integrity.focusLossSeconds || 0),
    copyPasteAttempts: Number(integrity.copyPasteAttempts || 0),
    grammarAnswers: computeGrammarAnswers(attempt),
    sectionStatus: computeSectionStatus(attempt),
    liveView: buildResolvedLiveView(attempt),
  };
}

/**
 * Prefer explicit nav index from client; fall back to current/first unanswered item.
 */
export function resolveLiveGrammarNavIndex(attempt, liveView = {}) {
  const items = attempt.examSnapshot?.settings?.grammarItems || [];
  if (!items.length) return 0;

  if (liveView.currentGrammarItemId != null && String(liveView.currentGrammarItemId)) {
    const byId = items.findIndex((it) => String(it.itemId) === String(liveView.currentGrammarItemId));
    if (byId >= 0) return byId;
  }

  const fromMeta = Number(liveView.grammarNavIndex);
  if (Number.isFinite(fromMeta) && fromMeta >= 0 && fromMeta < items.length) {
    return Math.floor(fromMeta);
  }

  const focusId = computeCurrentFocus(attempt).currentItemId;
  if (focusId) {
    const byFocus = items.findIndex((it) => String(it.itemId) === String(focusId));
    if (byFocus >= 0) return byFocus;
  }
  return 0;
}

function buildResolvedLiveView(attempt) {
  const meta = attempt.meta && typeof attempt.meta === 'object' ? attempt.meta : {};
  const liveView = meta.liveView && typeof meta.liveView === 'object' ? meta.liveView : {};
  const snap = attempt.examSnapshot || {};
  const grammarItems = Array.isArray(snap.settings?.grammarItems) ? snap.settings.grammarItems : [];
  const grammarNavIndex = resolveLiveGrammarNavIndex(attempt, liveView);
  return {
    activePartIndex: Number(liveView.activePartIndex ?? 0),
    grammarNavIndex,
    activePartKey: liveView.activePartKey != null ? String(liveView.activePartKey) : null,
    currentGrammarItemId:
      grammarItems[grammarNavIndex]?.itemId != null
        ? String(grammarItems[grammarNavIndex].itemId)
        : liveView.currentGrammarItemId != null
          ? String(liveView.currentGrammarItemId)
          : null,
    updatedAt: liveView.updatedAt || (attempt.updatedAt ? new Date(attempt.updatedAt).toISOString() : null),
  };
}

/**
 * Full state for teacher "live screen" mirror (answers + UI focus + exam structure).
 */
export function buildLiveScreenPayload(attempt, userLean = null) {
  const row = buildAttemptLiveProgressRow(attempt, userLean);
  const snap = attempt.examSnapshot || {};
  return {
    ...row,
    liveView: row.liveView,
    answers: attempt.answers || {},
    examSnapshot: snap,
    examTitle: snap.title ? String(snap.title) : '',
    skillStrips: [],
  };
}

/** Async variant includes live skill question strips (grammar / listening / reading). */
export async function buildLiveScreenPayloadAsync(attempt, userLean = null, { skillStrips } = {}) {
  const row = buildAttemptLiveProgressRow(attempt, userLean);
  const snap = attempt.examSnapshot || {};
  let strips = skillStrips;
  if (strips == null) {
    const { computeLiveSkillStrips } = await import('./examLiveSkillStrips.js');
    strips = await computeLiveSkillStrips(attempt);
  }
  return {
    ...row,
    liveView: row.liveView,
    answers: attempt.answers || {},
    examSnapshot: snap,
    examTitle: snap.title ? String(snap.title) : '',
    skillStrips: strips,
  };
}
