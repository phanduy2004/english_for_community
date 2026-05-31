/**
 * examIntegratedScoring.js
 *
 * Per-skill scoring engine for integrated exams (integrated_four_skills / skills_exam).
 * Each component (skill + grammar) is scored 0–10.
 * finalScore = mean of all finalized component scores.
 */

import Listening from '../models/Listening.js';
import ListeningComprehension from '../models/ListeningComprehension.js';
import ListeningCompAttempt from '../models/ListeningCompAttempt.js';
import Reading from '../models/Reading.js';
import SpeakingSet from '../models/SpeakingSet.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import {
  examTimeBounds,
  fetchListeningRecords,
  fetchReadingRecord,
  fetchWritingRecord,
  resolveMongoResourceId,
  resolveMongoUserId,
  resourcesFromSkillSection,
  skillSectionsFromExam,
} from './examAttemptService.js';
import { listeningCueTextIsCorrect, readingChoiceIsCorrect } from './examLiveSkillStrips.js';

/** Round to 1 decimal place. */
function round1(n) {
  return Math.round(n * 10) / 10;
}

/** Map IELTS-style band (0–9) to exam scale 0–10. */
export function ieltsBandToExamTen(band) {
  const b = Number(band);
  if (!Number.isFinite(b)) return null;
  return round1(Math.max(0, Math.min(10, (b / 9) * 10)));
}

function listeningCueTextAt(examCues, idx) {
  if (!examCues || typeof examCues !== 'object') return '';
  const raw = examCues[String(idx)] ?? examCues[idx];
  return raw != null ? String(raw).trim() : '';
}

function scoringContext(attempt) {
  const userId = resolveMongoUserId(attempt.userId);
  const startedAt = attempt.startedAt ? new Date(attempt.startedAt) : null;
  const endAt = attempt.submittedAt ? new Date(attempt.submittedAt) : new Date();
  if (!userId || !startedAt || Number.isNaN(startedAt.getTime())) {
    return { userId: null, bounds: null };
  }
  return { userId, bounds: examTimeBounds(startedAt, endAt) };
}

/** Merged listening score key when exam has dictation + comprehension sections. */
export const LISTENING_MERGED_KEY = '__listening__';

/** Build a skill score entry. */
function skillEntry(skill, score, rawCorrect, rawTotal, status, gradingSource, extras = {}) {
  const detail =
    rawTotal != null && rawTotal > 0
      ? `${rawCorrect ?? 0}/${rawTotal} correct`
      : null;
  return {
    skill,
    score: score != null ? round1(score) : null,
    max: 10,
    rawCorrect: rawTotal != null && rawTotal > 0 ? Number(rawCorrect ?? 0) : null,
    rawTotal: rawTotal != null && rawTotal > 0 ? Number(rawTotal) : null,
    detail,
    status,
    gradingSource: gradingSource ?? null,
    includeInFinal: extras.includeInFinal !== false,
    ...extras,
  };
}

/** Exam section exists but student did not answer — score 0/10, still counts toward average. */
function zeroScoreEntry(skill, rawTotal, gradingSource = 'auto_empty', extras = {}) {
  const total = Number(rawTotal);
  if (!Number.isFinite(total) || total <= 0) {
    return skillEntry(skill, null, null, null, 'no_content', null, extras);
  }
  return skillEntry(skill, 0, 0, total, 'finalized', gradingSource, extras);
}

function hasInlineDictationWork(secAns) {
  const cues = secAns?.listeningCues;
  if (!cues || typeof cues !== 'object') return false;
  return Object.values(cues).some((v) => String(v ?? '').trim().length > 0);
}

function hasInlineCompWork(secAns) {
  const ans = secAns?.listeningCompAnswers;
  if (!ans || typeof ans !== 'object') return false;
  return Object.keys(ans).length > 0;
}

async function findListeningCompAttemptInWindow(userId, listeningOid, bounds) {
  let attemptDoc = await ListeningCompAttempt.findOne({
    userId,
    listeningId: listeningOid,
    createdAt: { $gte: bounds.strictStart, $lte: bounds.strictEnd },
  })
    .select('correctCount totalQuestions answers')
    .sort({ createdAt: -1 })
    .lean();

  if (!attemptDoc) {
    attemptDoc = await ListeningCompAttempt.findOne({
      userId,
      listeningId: listeningOid,
      createdAt: { $gte: bounds.softStart, $lte: bounds.softEnd },
    })
      .select('correctCount totalQuestions answers')
      .sort({ createdAt: -1 })
      .lean();
  }
  return attemptDoc;
}

function dictationRecordCorrect(rec, expectedText) {
  if (!rec) return false;
  const userText = rec.userText != null ? String(rec.userText).trim() : '';
  if (!userText.length) return false;
  if (rec.score?.passed === true) return true;
  if (rec.score?.passed === false) return false;
  const wer = Number(rec.score?.wer);
  if (Number.isFinite(wer)) return wer <= Number(rec.score?.thresholdWer ?? 0.25);
  return listeningCueTextIsCorrect(expectedText, userText) === true;
}

/** Compute score for a listening skill section (inline cues + CMS dictation fallback). */
async function scoreListeningCompSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];

  for (const res of resourcesFromSkillSection(sec)) {
    const oid = resolveMongoResourceId(res.id);
    if (!oid) continue;

    const lc = await ListeningComprehension.findById(oid).select('questions').lean();
    if (!lc || !Array.isArray(lc.questions) || lc.questions.length === 0) continue;

    const total = lc.questions.length;
    const inlineAnswers = secAns?.listeningCompAnswers;
    let correct = 0;
    let source = 'auto_empty';

    if (hasInlineCompWork(secAns)) {
      source = 'auto_inline';
      for (const q of lc.questions) {
        const qid = String(q._id);
        const chosen = Number(inlineAnswers[qid]);
        if (!Number.isNaN(chosen) && chosen === q.correctAnswerIndex) correct++;
      }
    } else if (ctx.userId && ctx.bounds) {
      const attemptDoc = await findListeningCompAttemptInWindow(ctx.userId, oid, ctx.bounds);
      if (attemptDoc) {
        source = 'auto_cms';
        correct = Number(attemptDoc.correctCount ?? 0);
      }
    }

    const score = round1((correct / total) * 10);
    return skillEntry('listening', score, correct, total, 'finalized', source, {
      listeningType: 'comprehension',
    });
  }

  return skillEntry('listening', null, null, null, 'no_content', null, {
    listeningType: 'comprehension',
  });
}

async function scoreListeningSection(sec, attempt, ctx) {
  const listeningType = sec.sectionConfig?.listeningType || 'dictation';
  if (listeningType === 'comprehension') {
    return scoreListeningCompSection(sec, attempt, ctx);
  }
  return scoreDictationSection(sec, attempt, ctx);
}

/** Compute score for a listening dictation section (inline cues + CMS fallback). */
async function scoreDictationSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];
  const listeningCues =
    secAns?.listeningCues && typeof secAns.listeningCues === 'object'
      ? secAns.listeningCues
      : null;
  const useInline = hasInlineDictationWork(secAns);

  let totalCues = 0;
  let correctCues = 0;
  let usedInline = false;

  for (const res of resourcesFromSkillSection(sec)) {
    const oid = resolveMongoResourceId(res.id);
    if (!oid) continue;
    const doc = await Listening.findById(oid).select('cues').lean();
    const cues = Array.isArray(doc?.cues) ? doc.cues : [];
    if (cues.length === 0) continue;

    totalCues += cues.length;

    if (useInline && listeningCues) {
      usedInline = true;
      for (let i = 0; i < cues.length; i += 1) {
        const userText = listeningCueTextAt(listeningCues, i);
        const expected = cues[i]?.text != null ? String(cues[i].text) : '';
        if (listeningCueTextIsCorrect(expected, userText) === true) correctCues += 1;
      }
      continue;
    }

    if (ctx.userId && ctx.bounds) {
      const { records, source } = await fetchListeningRecords(ctx.userId, oid, ctx.bounds);
      if (source !== 'latest_linked' && records.length > 0) {
        const byCue = new Map(records.map((r) => [Number(r.cueIdx), r]));
        for (let i = 0; i < cues.length; i += 1) {
          const expected = cues[i]?.text != null ? String(cues[i].text) : '';
          const rec = byCue.get(i);
          if (dictationRecordCorrect(rec, expected)) correctCues += 1;
        }
      }
    }
  }

  if (totalCues === 0) {
    return skillEntry('listening', null, null, null, 'no_content', null, {
      listeningType: 'dictation',
    });
  }
  const score = round1((correctCues / totalCues) * 10);
  return skillEntry(
    'listening',
    score,
    correctCues,
    totalCues,
    'finalized',
    usedInline ? 'auto_inline' : 'auto_cms',
    { listeningType: 'dictation' }
  );
}

function readingChosenForQuestion(readingAnswers, q, index) {
  if (!readingAnswers || typeof readingAnswers !== 'object') return undefined;
  const qid = q._id != null ? String(q._id) : '';
  if (qid && readingAnswers[qid] !== undefined && readingAnswers[qid] !== null) {
    return readingAnswers[qid];
  }
  return readingAnswers[String(index)];
}

/** Compute score for a reading skill section (inline + ReadingAttempt fallback). */
async function scoreReadingSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];
  const readingAnswers =
    secAns?.readingAnswers && typeof secAns.readingAnswers === 'object'
      ? secAns.readingAnswers
      : null;

  let totalQ = 0;
  let correctQ = 0;
  let usedInline = false;

  for (const res of resourcesFromSkillSection(sec)) {
    const oid = resolveMongoResourceId(res.id);
    if (!oid) continue;
    const doc = await Reading.findById(oid).select('questions').lean();
    const questions = Array.isArray(doc?.questions) ? doc.questions : [];
    if (questions.length === 0) continue;

    totalQ += questions.length;

    if (readingAnswers && typeof readingAnswers === 'object') {
      usedInline = true;
      for (let i = 0; i < questions.length; i += 1) {
        const chosen = readingChosenForQuestion(readingAnswers, questions[i], i);
        if (readingChoiceIsCorrect(questions[i], chosen) === true) correctQ += 1;
      }
      continue;
    }

    if (ctx.userId && ctx.bounds) {
      const { records, source } = await fetchReadingRecord(ctx.userId, oid, ctx.bounds);
      if (source !== 'latest_linked' && records?.answers) {
        const answers = Array.isArray(records.answers) ? records.answers : [];
        const byQid = new Map(answers.map((a) => [String(a.questionId), a]));
        for (const q of questions) {
          const qid = q._id != null ? String(q._id) : '';
          const row = byQid.get(qid);
          if (row?.isCorrect === true) correctQ += 1;
          else if (row && readingChoiceIsCorrect(q, row.chosenIndex) === true) correctQ += 1;
        }
      }
    }
  }

  if (totalQ === 0) {
    return skillEntry('reading', null, null, null, 'no_content', null);
  }
  const score = round1((correctQ / totalQ) * 10);
  return skillEntry(
    'reading',
    score,
    correctQ,
    totalQ,
    'finalized',
    usedInline ? 'auto_inline' : 'auto_cms'
  );
}

/**
 * Fetch SpeakingAttempt records strictly within the exam time window.
 * Unlike the general fetchSpeakingRecords, this does NOT fall back to
 * near_session or latest_linked — old practice records must never pollute exam scores.
 */
async function fetchSpeakingRecordsExamStrict(userId, speakingSetId, bounds) {
  const records = await SpeakingAttempt.find({
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
  return records;
}

/**
 * Compute score for a speaking skill section using WER from SpeakingAttempt records.
 * Only records within the strict exam time window are used — old practice sessions
 * are intentionally excluded to prevent false scores when speaking was skipped.
 * score = round((1 - averageWer) * 10), clamped 0–10.
 */
async function scoreSpeakingSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];

  // Inline speaking records saved directly in the attempt answers (future-proof path)
  const inlineRecords = Array.isArray(secAns?.records) ? secAns.records : null;
  if (inlineRecords && inlineRecords.length > 0) {
    const validWers = inlineRecords
      .map((r) => Number(r?.score?.wer ?? r?.wer))
      .filter((w) => Number.isFinite(w));
    if (validWers.length > 0) {
      const avgWer = validWers.reduce((a, b) => a + b, 0) / validWers.length;
      const score = round1(Math.max(0, Math.min(10, (1 - avgWer) * 10)));
      return skillEntry('speaking', score, null, null, 'finalized', 'auto_inline');
    }
  }

  // CMS SpeakingAttempt — strict exam window ONLY (no near_session / latest_linked fallback)
  if (ctx.userId && ctx.bounds) {
    for (const res of resourcesFromSkillSection(sec)) {
      const oid = resolveMongoResourceId(res.id);
      if (!oid) continue;
      const setDoc = await SpeakingSet.findById(oid).select('sentences').lean();
      const sentenceCount = Array.isArray(setDoc?.sentences) ? setDoc.sentences.length : 0;
      const records = await fetchSpeakingRecordsExamStrict(ctx.userId, oid, ctx.bounds);
      if (records && records.length > 0) {
        const validWers = records
          .map((r) => Number(r?.score?.wer))
          .filter((w) => Number.isFinite(w));
        if (validWers.length > 0) {
          const avgWer = validWers.reduce((a, b) => a + b, 0) / validWers.length;
          const score = round1(Math.max(0, Math.min(10, (1 - avgWer) * 10)));
          return skillEntry('speaking', score, null, null, 'finalized', 'auto_cms');
        }
      }
      if (sentenceCount > 0) {
        return zeroScoreEntry('speaking', sentenceCount);
      }
    }
  }

  return skillEntry('speaking', null, null, null, 'no_content', null);
}

export function writingTaskTypeFromSection(sec) {
  const fp = sec.fixedWritingPrompt || sec.fixedPrompt;
  if (fp && typeof fp === 'object' && fp.taskType) return String(fp.taskType);
  return 'Discussion';
}

/** Writing: pending manual until teacher or AI grades; may reuse CMS reviewed score. */
async function scoreWritingSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];
  let text = secAns?.writingDraft != null ? String(secAns.writingDraft).trim() : '';

  if (!text.length && ctx.userId && ctx.bounds) {
    for (const res of resourcesFromSkillSection(sec)) {
      const oid = resolveMongoResourceId(res.id);
      if (!oid) continue;
      const { records } = await fetchWritingRecord(ctx.userId, oid, ctx.bounds, { examOnly: true });
      if (records?.content) {
        text = String(records.content).trim();
        if (records.status === 'reviewed' && records.score != null) {
          const score10 = ieltsBandToExamTen(records.score);
          return skillEntry('writing', score10, null, null, 'finalized', 'practice_cms', {
            wordCount: records.wordCount ?? null,
          });
        }
        break;
      }
    }
  }

  const wordCount =
    secAns?.wordCount != null
      ? Number(secAns.wordCount)
      : text.length > 0
        ? text.trim().split(/\s+/).filter(Boolean).length
        : 0;

  if (!text.length) {
    return skillEntry('writing', null, null, null, 'pending_manual', null, { wordCount: 0 });
  }

  return skillEntry('writing', null, null, null, 'pending_manual', null, {
    wordCount,
    hasDraft: true,
  });
}

/**
 * Compute grammar score from grammar items.
 * Returns null if no grammar items.
 */
function scoreGrammarItems(grammarItems, grammarResults) {
  if (!grammarItems || grammarItems.length === 0) return null;
  let rawAwarded = 0;
  let rawMax = 0;
  for (const it of grammarItems) {
    const max = Number(it.points ?? 1);
    rawMax += max;
    const ir = grammarResults?.[it.itemId];
    rawAwarded += Math.min(max, Number(ir?.awardedPoints ?? 0));
  }
  if (rawMax === 0) return null;
  return {
    score: round1((rawAwarded / rawMax) * 10),
    max: 10,
    rawAwarded,
    rawMax,
    status: 'finalized',
    items: grammarResults ?? {},
  };
}

/**
 * Compute finalScore / finalStatus from skillScores + grammarScore.
 */
/**
 * When an exam has dictation + comprehension listening sections, merge into one
 * combined listening score for the final average. Per-section entries remain for detail.
 */
export function applyListeningScoreMerge(skillScores, skillSections) {
  const listeningSecs = skillSections.filter((s) => String(s.skill) === 'listening');
  if (listeningSecs.length <= 1) return skillScores;

  let totalCorrect = 0;
  let totalItems = 0;

  for (const sec of listeningSecs) {
    const sid = String(sec.sectionId || '').trim();
    const entry = skillScores[sid];
    if (!entry) continue;
    entry.includeInFinal = false;

    if (entry.status === 'finalized' && Number(entry.rawTotal) > 0) {
      totalCorrect += Number(entry.rawCorrect ?? 0);
      totalItems += Number(entry.rawTotal);
    }
  }

  if (totalItems > 0) {
    skillScores[LISTENING_MERGED_KEY] = skillEntry(
      'listening',
      round1((totalCorrect / totalItems) * 10),
      totalCorrect,
      totalItems,
      'finalized',
      'merged',
      {
        parts: listeningSecs.map((sec) => ({
          sectionId: String(sec.sectionId || '').trim(),
          listeningType: sec.sectionConfig?.listeningType || 'dictation',
        })),
      }
    );
  }

  return skillScores;
}

export function computeFinal(skillScores, grammarScore) {
  const components = [];
  let anyPending = false;

  for (const entry of Object.values(skillScores)) {
    if (entry.includeInFinal === false) continue;
    if (entry.status === 'no_content') continue;
    if (entry.status === 'finalized' && entry.score != null) {
      components.push(entry.score);
    } else if (
      entry.status === 'pending_ai' ||
      (entry.status === 'pending_manual' && entry.score == null)
    ) {
      anyPending = true;
    }
  }

  if (grammarScore) {
    components.push(grammarScore.score);
  }

  if (components.length === 0 && anyPending) {
    return { finalScore: null, finalMax: 10, finalStatus: 'pending' };
  }
  if (components.length === 0) {
    return { finalScore: null, finalMax: 10, finalStatus: 'pending' };
  }

  const avg = components.reduce((a, b) => a + b, 0) / components.length;
  const finalScore = round1(avg);
  const finalStatus = anyPending ? 'partial' : 'finalized';
  return { finalScore, finalMax: 10, finalStatus };
}

/**
 * Build full integrated scores at submit time.
 */
export async function buildIntegratedScores(attempt, exam, scoreGrammarItem) {
  const skillSections = skillSectionsFromExam(exam).sort(
    (a, b) => Number(a.order ?? 0) - Number(b.order ?? 0)
  );
  const grammarItems = Array.isArray(exam.settings?.grammarItems) ? exam.settings.grammarItems : [];
  const ctx = scoringContext(attempt);

  const grammarResults = {};
  for (const it of grammarItems) {
    const max = Number(it.points ?? 1);
    const awarded = scoreGrammarItem(it, attempt.answers?.[it.itemId]);
    grammarResults[it.itemId] = {
      kind: it.kind,
      maxPoints: max,
      awardedPoints: awarded,
      status: 'finalized',
    };
  }
  const grammarScore = scoreGrammarItems(grammarItems, grammarResults);

  const skillScores = {};
  for (const sec of skillSections) {
    const sid = String(sec.sectionId || '').trim();
    if (!sid) continue;
    const skill = String(sec.skill || '');
    let entry;
    if (skill === 'listening') {
      entry = await scoreListeningSection(sec, attempt, ctx);
    } else if (skill === 'reading') {
      entry = await scoreReadingSection(sec, attempt, ctx);
    } else if (skill === 'writing') {
      entry = await scoreWritingSection(sec, attempt, ctx);
    } else if (skill === 'speaking') {
      entry = await scoreSpeakingSection(sec, attempt, ctx);
    } else {
      entry = skillEntry(skill, null, null, null, 'pending_manual', null);
    }
    skillScores[sid] = entry;
  }

  applyListeningScoreMerge(skillScores, skillSections);

  const { finalScore, finalMax, finalStatus } = computeFinal(skillScores, grammarScore);

  return {
    examFormat: exam?.settings?.examFormat,
    skillScores,
    grammarScore,
    finalScore,
    finalMax,
    finalStatus,
  };
}

/**
 * Preserve teacher/AI finalized writing & speaking manual overrides when rebuilding auto scores.
 * Speaking auto-WER scores are NOT preserved (allow re-computation from latest records).
 * Speaking manual / AI-graded overrides ARE preserved.
 */
export function mergePreservedSkillScores(integrated, previousSkillScores = {}) {
  if (!previousSkillScores || typeof previousSkillScores !== 'object') return integrated;
  for (const [sid, entry] of Object.entries(integrated.skillScores || {})) {
    const prev = previousSkillScores[sid];
    if (!prev || prev.score == null || prev.status !== 'finalized') continue;
    const skill = entry.skill || prev.skill;
    if (skill !== 'writing' && skill !== 'speaking') continue;
    // For speaking, only preserve a manual/AI override — not an old auto-WER score.
    const src = prev.gradingSource;
    if (skill === 'speaking' && src !== 'manual' && src !== 'ai') continue;
    integrated.skillScores[sid] = {
      ...entry,
      score: prev.score,
      status: 'finalized',
      gradingSource: prev.gradingSource,
      note: prev.note,
      aiFeedback: prev.aiFeedback,
      aiDraftScore: prev.aiDraftScore,
    };
  }
  const { finalScore, finalMax, finalStatus } = computeFinal(
    integrated.skillScores,
    integrated.grammarScore
  );
  integrated.finalScore = finalScore;
  integrated.finalMax = finalMax;
  integrated.finalStatus = finalStatus;
  return integrated;
}

export function integratedAutoScoresStale(scores) {
  if (!scores?.skillScores) return true;
  for (const entry of Object.values(scores.skillScores)) {
    // Listening/reading: stale if never computed (pending_ai)
    if (['listening', 'reading'].includes(entry.skill) && entry.status === 'pending_ai') {
      return true;
    }
    // Speaking: stale if pending with no score (not yet auto-scored via WER)
    if (entry.skill === 'speaking' && entry.status === 'pending_manual' && entry.score == null) {
      return true;
    }
  }
  return false;
}

/**
 * Check if all expected skill sections from the exam are present in skillScores.
 * Old attempts may be missing entries for skills that were added later or not processed.
 */
export function integratedSkillEntriesMissing(skillSections, skillScores) {
  if (!skillScores || typeof skillScores !== 'object') return true;
  for (const sec of skillSections) {
    const sid = String(sec.sectionId || '').trim();
    if (!sid) continue;
    if (!skillScores[sid]) return true;
  }
  return false;
}

/**
 * Update a skill score (speaking/writing) from teacher grading patch.
 */
export function patchIntegratedSkillScores(currentScores, skillOverrides) {
  const scores = {
    ...currentScores,
    skillScores: { ...(currentScores.skillScores || {}) },
    grammarScore: currentScores.grammarScore ?? null,
  };

  for (const [sid, override] of Object.entries(skillOverrides)) {
    if (!override || typeof override !== 'object') continue;
    const prev = scores.skillScores[sid] || {};
    const rawScore = Number(override.score);
    if (Number.isNaN(rawScore)) continue;
    const clamped = round1(Math.max(0, Math.min(10, rawScore)));
    scores.skillScores[sid] = {
      ...prev,
      score: clamped,
      max: 10,
      status: 'finalized',
      gradingSource: override.gradingSource ?? 'manual',
      note: override.note != null ? String(override.note).slice(0, 1000) : prev.note ?? undefined,
      aiFeedback: override.aiFeedback ?? prev.aiFeedback,
      aiDraftScore: override.aiDraftScore ?? prev.aiDraftScore,
    };
  }

  const { finalScore, finalMax, finalStatus } = computeFinal(
    scores.skillScores,
    scores.grammarScore
  );
  scores.finalScore = finalScore;
  scores.finalMax = finalMax;
  scores.finalStatus = finalStatus;

  return scores;
}

export function findWritingSections(exam) {
  return skillSectionsFromExam(exam).filter((s) => String(s.skill) === 'writing');
}

export function findSpeakingSections(exam) {
  return skillSectionsFromExam(exam).filter((s) => String(s.skill) === 'speaking');
}

/**
 * Compute WER-based scores for all speaking sections of an attempt.
 * Returns an object keyed by sectionId with score entries (finalized or no_content).
 */
export async function autoScoreIntegratedSpeaking(attempt, exam) {
  const sections = findSpeakingSections(exam);
  if (sections.length === 0) return {};
  const ctx = scoringContext(attempt);
  const overrides = {};
  for (const sec of sections) {
    const sid = String(sec.sectionId || '').trim();
    if (!sid) continue;
    const entry = await scoreSpeakingSection(sec, attempt, ctx);
    if (entry.status === 'finalized' && entry.score != null) {
      overrides[sid] = { score: entry.score, gradingSource: entry.gradingSource };
    }
  }
  return overrides;
}
