import Listening from '../models/Listening.js';
import ListeningComprehension from '../models/ListeningComprehension.js';
import Reading from '../models/Reading.js';
import SpeakingSet from '../models/SpeakingSet.js';
import { computeGrammarAnswers, resolveLiveGrammarNavIndex } from './examAttemptProgress.js';
import {
  examTimeBounds,
  fetchListeningRecords,
  fetchReadingRecord,
  fetchSpeakingRecords,
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

function speakingAttemptAnswered(rec) {
  if (!rec) return false;
  return String(rec.userTranscript || '').trim().length > 0;
}

function speakingAttemptCorrect(rec) {
  if (!speakingAttemptAnswered(rec)) return null;
  const wer = Number(rec?.score?.wer);
  if (!Number.isFinite(wer)) return null;
  return wer <= 0.25;
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
    if (!['listening', 'reading', 'speaking'].includes(skill)) continue;

    const partKey = String(sec.sectionId || '').trim();
    if (!partKey) continue;

    const listeningType = skill === 'listening'
      ? (sec.sectionConfig?.listeningType || 'dictation')
      : null;

    const questions = [];
    let currentQuestionIndex = null;

    for (const res of resourcesFromSkillSection(sec)) {
      const resourceOid = resolveMongoResourceId(res.id);
      if (!resourceOid) continue;

      if (skill === 'listening' && listeningType === 'comprehension') {
        // Listening Comprehension: MCQ questions
        const compDoc = await ListeningComprehension.findById(resourceOid).select('questions').lean();
        const qList = Array.isArray(compDoc?.questions) ? compDoc.questions : [];
        const secAns = sectionAnswers(plain, partKey);
        const compAnswers = secAns?.listeningCompAnswers;

        for (let i = 0; i < qList.length; i += 1) {
          const qid = qList[i]._id != null ? String(qList[i]._id) : String(i);
          const chosen = compAnswers && typeof compAnswers === 'object'
            ? (compAnswers[qid] ?? compAnswers[String(i)])
            : undefined;
          const answered = chosen !== undefined && chosen !== null && Number(chosen) >= 0;
          const isCorrect = answered
            ? Number(chosen) === Number(qList[i].correctAnswerIndex ?? -1)
              ? true
              : false
            : null;
          questions.push({
            number: questions.length + 1,
            answered,
            isCorrect,
          });
        }
        if (activePartKey === partKey && questions.some((q) => q.answered)) {
          currentQuestionIndex = Math.min(
            questions.filter((q) => q.answered).length - 1,
            questions.length - 1,
          );
        }
        continue;
      }

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

      if (skill === 'speaking') {
        const setDoc = await SpeakingSet.findById(resourceOid).select('sentences').lean();
        const sentences = Array.isArray(setDoc?.sentences)
          ? [...setDoc.sentences].sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0))
          : [];
        const secAns = sectionAnswers(plain, partKey);
        const inlineIndex = Number(secAns?.speakingSentenceIndex);

        // Strict exam window only — never reuse near_session / latest_linked practice attempts.
        const { records: examRecords } = await fetchSpeakingRecords(
          userId,
          resourceOid,
          bounds,
          { examOnly: true },
        );
        const bySentence = new Map();
        for (const rec of examRecords) {
          const sid = rec?.sentenceId != null ? String(rec.sentenceId) : '';
          if (!sid) continue;
          const prev = bySentence.get(sid);
          if (
            !prev
            || new Date(rec.createdAt || rec.submittedAt || 0).getTime()
              > new Date(prev.createdAt || prev.submittedAt || 0).getTime()
          ) {
            bySentence.set(sid, rec);
          }
        }

        for (let i = 0; i < sentences.length; i += 1) {
          const sid = sentences[i]?.id != null ? String(sentences[i].id) : '';
          const rec = sid ? bySentence.get(sid) : null;
          const answered = speakingAttemptAnswered(rec);
          questions.push({
            number: questions.length + 1,
            answered,
            isCorrect: answered ? speakingAttemptCorrect(rec) : null,
          });
        }

        if (activePartKey === partKey && questions.length > 0) {
          if (Number.isFinite(inlineIndex) && inlineIndex >= 0) {
            currentQuestionIndex = Math.min(Math.floor(inlineIndex), questions.length - 1);
          } else {
            const answeredCount = questions.filter((x) => x.answered).length;
            if (answeredCount > 0) {
              currentQuestionIndex = Math.min(answeredCount - 1, questions.length - 1);
            }
          }
        }
      }
    }

    if (questions.length > 0) {
      strips.push({
        partKey,
        skill,
        ...(listeningType ? { listeningType } : {}),
        currentQuestionIndex,
        questions,
      });
    }
  }

  return strips;
}
