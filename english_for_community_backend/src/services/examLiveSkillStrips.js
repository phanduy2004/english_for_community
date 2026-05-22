import Listening from '../models/Listening.js';
import Reading from '../models/Reading.js';
import { computeGrammarAnswers, resolveLiveGrammarNavIndex } from './examAttemptProgress.js';
import {
  examTimeBounds,
  fetchListeningRecords,
  fetchReadingRecord,
  resolveMongoResourceId,
  resolveMongoUserId,
  resourcesFromSkillSection,
  skillSectionsFromExam,
} from './examAttemptService.js';

function listeningCueAnswered(rec) {
  if (!rec) return false;
  const text = rec.userText != null ? String(rec.userText).trim() : '';
  return text.length > 0 || Number(rec.attemptsCount || 0) > 0;
}

function listeningCueCorrect(rec) {
  if (!rec || !listeningCueAnswered(rec)) return null;
  if (rec.score?.passed === true) return true;
  if (rec.score?.passed === false) return false;
  const wer = Number(rec.score?.wer);
  if (Number.isFinite(wer)) return wer <= Number(rec.score?.thresholdWer ?? 0.25);
  return null;
}

function sectionAnswers(attempt, partKey) {
  const a = attempt?.answers?.[partKey];
  return a && typeof a === 'object' ? a : null;
}

function listeningCueTextAt(examCues, idx) {
  if (!examCues || typeof examCues !== 'object') return '';
  const raw = examCues[String(idx)] ?? examCues[idx];
  return raw != null ? String(raw).trim() : '';
}

/** Same normalization as listening dictation grading. */
function normalizeListeningText(s = '') {
  return String(s)
    .toLowerCase()
    .replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?"'’]/g, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

export function readingChoiceIsCorrect(question, chosenIndex) {
  if (chosenIndex === undefined || chosenIndex === null) return null;
  const correct = Number(question?.correctAnswerIndex);
  if (!Number.isFinite(correct)) return null;
  return Number(chosenIndex) === correct;
}

export function listeningCueTextIsCorrect(expectedText, userText) {
  const user = normalizeListeningText(userText);
  if (!user.length) return null;
  const expected = normalizeListeningText(expectedText);
  if (!expected.length) return null;
  return user === expected;
}

/**
 * Per-skill numbered question strips for teacher live monitor (green/red/gray).
 */
export async function computeLiveSkillStrips(attempt) {
  const plain = attempt?.toObject ? attempt.toObject() : attempt;
  const exam = plain.examSnapshot || {};
  const liveView = plain.meta?.liveView && typeof plain.meta.liveView === 'object' ? plain.meta.liveView : {};
  const strips = [];

  const grammarAnswers = computeGrammarAnswers(plain);
  if (grammarAnswers.length > 0) {
    strips.push({
      partKey: '__grammar__',
      skill: 'grammar',
      currentQuestionIndex: resolveLiveGrammarNavIndex(plain, liveView),
      questions: grammarAnswers.map((g, i) => ({
        number: i + 1,
        answered: Boolean(g.answered),
        isCorrect: g.isCorrect === true ? true : g.isCorrect === false ? false : null,
      })),
    });
  }

  const userId = resolveMongoUserId(plain.userId);
  const startedAt = plain.startedAt ? new Date(plain.startedAt) : null;
  if (!userId || !startedAt || Number.isNaN(startedAt.getTime())) {
    return strips;
  }

  const endAt = plain.submittedAt ? new Date(plain.submittedAt) : new Date();
  const bounds = examTimeBounds(startedAt, endAt);
  const activePartKey = liveView.activePartKey != null ? String(liveView.activePartKey) : null;

  for (const sec of skillSectionsFromExam(exam)) {
    const skill = String(sec.skill || '');
    if (!['listening', 'reading'].includes(skill)) continue;

    const partKey = String(sec.sectionId || '').trim();
    if (!partKey) continue;

    const questions = [];
    let currentQuestionIndex = null;

    for (const res of resourcesFromSkillSection(sec)) {
      const resourceOid = resolveMongoResourceId(res.id);
      if (!resourceOid) continue;

      if (skill === 'listening') {
        const listening = await Listening.findById(resourceOid).select('cues').lean();
        const cueCount = Array.isArray(listening?.cues) ? listening.cues.length : 0;
        const secAns = sectionAnswers(plain, partKey);
        const examCues = secAns?.listeningCues;

        if (examCues && typeof examCues === 'object') {
          const cues = Array.isArray(listening?.cues) ? listening.cues : [];
          for (let i = 0; i < cueCount; i += 1) {
            const text = listeningCueTextAt(examCues, i);
            const answered = text.length > 0;
            const expected = cues[i]?.text != null ? String(cues[i].text) : '';
            const isCorrect = answered
              ? listeningCueTextIsCorrect(expected, text)
              : null;
            questions.push({
              number: questions.length + 1,
              answered,
              isCorrect,
            });
            if (activePartKey === partKey && answered) currentQuestionIndex = i;
          }
        } else {
          const { records } = await fetchListeningRecords(userId, resourceOid, bounds, { examOnly: true });
          const byCue = new Map(records.map((r) => [Number(r.cueIdx), r]));
          for (let i = 0; i < cueCount; i += 1) {
            const rec = byCue.get(i);
            const answered = listeningCueAnswered(rec);
            questions.push({
              number: questions.length + 1,
              answered,
              isCorrect: answered ? listeningCueCorrect(rec) : null,
            });
            if (activePartKey === partKey && rec && currentQuestionIndex == null) {
              const latest = [...records].sort(
                (a, b) =>
                  new Date(b.updatedAt || b.submittedAt || 0).getTime() -
                  new Date(a.updatedAt || a.submittedAt || 0).getTime()
              )[0];
              if (latest && Number(latest.cueIdx) === i) currentQuestionIndex = i;
            }
          }
        }
      }

      if (skill === 'reading') {
        const reading = await Reading.findById(resourceOid).select('questions').lean();
        const qList = Array.isArray(reading?.questions) ? reading.questions : [];
        const secAns = sectionAnswers(plain, partKey);
        const examReading = secAns?.readingAnswers;

        if (examReading && typeof examReading === 'object') {
          for (const q of qList) {
            const qid = q._id != null ? String(q._id) : '';
            const chosen = examReading[qid];
            const answered = chosen !== undefined && chosen !== null;
            const isCorrect = answered ? readingChoiceIsCorrect(q, chosen) : null;
            questions.push({
              number: questions.length + 1,
              answered,
              isCorrect,
            });
          }
          if (activePartKey === partKey) {
            const answeredCount = questions.filter((x) => x.answered).length;
            if (answeredCount > 0) currentQuestionIndex = Math.min(answeredCount - 1, questions.length - 1);
          }
        } else {
          const { records } = await fetchReadingRecord(userId, resourceOid, bounds, { examOnly: true });
          const answers = records?.answers && Array.isArray(records.answers) ? records.answers : [];
          const byQ = new Map(answers.map((a) => [String(a.questionId), a]));
          for (const q of qList) {
            const qid = q._id != null ? String(q._id) : '';
            const ans = byQ.get(qid);
            const answered = ans != null;
            questions.push({
              number: questions.length + 1,
              answered,
              isCorrect: answered
                ? ans?.isCorrect === true
                  ? true
                  : ans?.isCorrect === false
                    ? false
                    : null
                : null,
            });
          }
          if (activePartKey === partKey && answers.length > 0) {
            const answeredCount = questions.filter((x) => x.answered).length;
            if (answeredCount > 0) currentQuestionIndex = Math.min(answeredCount - 1, questions.length - 1);
          }
        }
      }
    }

    if (questions.length > 0) {
      strips.push({
        partKey,
        skill,
        currentQuestionIndex,
        questions,
      });
    }
  }

  return strips;
}
