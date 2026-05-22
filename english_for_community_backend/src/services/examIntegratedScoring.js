/**
 * examIntegratedScoring.js
 *
 * Per-skill scoring engine for integrated exams (integrated_four_skills / skills_exam).
 * Each component (skill + grammar) is scored 0–10.
 * finalScore = mean of all finalized component scores.
 */

import Listening from '../models/Listening.js';
import Reading from '../models/Reading.js';
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
    detail,
    status,
    gradingSource: gradingSource ?? null,
    ...extras,
  };
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
async function scoreListeningSection(sec, attempt, ctx) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt?.answers?.[sid];
  const listeningCues =
    secAns?.listeningCues && typeof secAns.listeningCues === 'object'
      ? secAns.listeningCues
      : null;

  let totalCues = 0;
  let correctCues = 0;
  let usedInline = false;

  for (const res of resourcesFromSkillSection(sec)) {
    const oid = resolveMongoResourceId(res.id);
    if (!oid) continue;
    const doc = await Listening.findById(oid).select('cues').lean();
    const cues = Array.isArray(doc?.cues) ? doc.cues : [];
    if (cues.length === 0) continue;

    if (listeningCues) {
      usedInline = true;
      totalCues += cues.length;
      for (let i = 0; i < cues.length; i += 1) {
        const userText = listeningCueTextAt(listeningCues, i);
        const expected = cues[i]?.text != null ? String(cues[i].text) : '';
        if (listeningCueTextIsCorrect(expected, userText) === true) correctCues += 1;
      }
      continue;
    }

    if (ctx.userId && ctx.bounds) {
      const { records } = await fetchListeningRecords(ctx.userId, oid, ctx.bounds, {
        examOnly: true,
      });
      if (records.length === 0) continue;
      const byCue = new Map(records.map((r) => [Number(r.cueIdx), r]));
      totalCues += cues.length;
      for (let i = 0; i < cues.length; i += 1) {
        const expected = cues[i]?.text != null ? String(cues[i].text) : '';
        const rec = byCue.get(i);
        if (dictationRecordCorrect(rec, expected)) correctCues += 1;
      }
    }
  }

  if (totalCues === 0) {
    return skillEntry('listening', null, null, null, 'no_content', null);
  }
  const score = round1((correctCues / totalCues) * 10);
  return skillEntry(
    'listening',
    score,
    correctCues,
    totalCues,
    'finalized',
    usedInline ? 'auto_inline' : 'auto_cms'
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

    if (readingAnswers) {
      usedInline = true;
      totalQ += questions.length;
      for (let i = 0; i < questions.length; i += 1) {
        const chosen = readingChosenForQuestion(readingAnswers, questions[i], i);
        if (readingChoiceIsCorrect(questions[i], chosen) === true) correctQ += 1;
      }
      continue;
    }

    if (ctx.userId && ctx.bounds) {
      const { records } = await fetchReadingRecord(ctx.userId, oid, ctx.bounds, { examOnly: true });
      const answers = Array.isArray(records?.answers) ? records.answers : [];
      if (answers.length === 0) continue;
      const byQid = new Map(answers.map((a) => [String(a.questionId), a]));
      totalQ += questions.length;
      for (const q of questions) {
        const qid = q._id != null ? String(q._id) : '';
        const row = byQid.get(qid);
        if (row?.isCorrect === true) correctQ += 1;
        else if (row && readingChoiceIsCorrect(q, row.chosenIndex) === true) correctQ += 1;
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
export function computeFinal(skillScores, grammarScore) {
  const components = [];
  let anyPending = false;

  for (const entry of Object.values(skillScores)) {
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
    } else {
      entry = skillEntry(skill, null, null, null, 'pending_manual', null);
    }
    skillScores[sid] = entry;
  }

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

/** Preserve teacher/AI finalized speaking & writing when rebuilding auto scores. */
export function mergePreservedSkillScores(integrated, previousSkillScores = {}) {
  if (!previousSkillScores || typeof previousSkillScores !== 'object') return integrated;
  for (const [sid, entry] of Object.entries(integrated.skillScores || {})) {
    const prev = previousSkillScores[sid];
    if (!prev || prev.score == null || prev.status !== 'finalized') continue;
    const skill = entry.skill || prev.skill;
    if (skill !== 'writing' && skill !== 'speaking') continue;
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
    if (['listening', 'reading'].includes(entry.skill) && entry.status === 'pending_ai') {
      return true;
    }
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
