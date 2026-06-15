import Groq from 'groq-sdk';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamAssignment from '../models/ExamAssignment.js';
import { teacherExamService } from './teacherExamService.js';
import { teacherExamAssignmentService } from './teacherExamAssignmentService.js';
import { GROQ_MODEL_NAME } from './aiService.js';
import { aiService } from './aiService.js';
import {
  findWritingSections,
  ieltsBandToExamTen,
  patchIntegratedSkillScores,
  writingTaskTypeFromSection,
} from './examIntegratedScoring.js';
import {
  examTimeBounds,
  fetchWritingRecord,
  resolveMongoResourceId,
  resolveMongoUserId,
  resourcesFromSkillSection,
} from './examAttemptService.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

const { walkItems } = teacherExamService;

let groqClient;
function getGroq() {
  if (!groqClient) groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });
  return groqClient;
}

async function assertTeacherOwnsAttempt(teacherId, attemptId) {
  const attempt = await ExamAttempt.findById(attemptId).populate({
    path: 'assignmentId',
    select: 'teacherId classroomId',
  });
  if (!attempt) throw httpError(404, 'Attempt not found');
  const a = attempt.assignmentId;
  if (!a) throw httpError(404, 'Assignment not found');
  await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, a._id.toString());
  return attempt;
}

function extractEssayText(ans) {
  if (!ans || typeof ans !== 'object') return '';
  return String(ans.text || '').slice(0, 12000);
}

function parseJsonLoose(raw) {
  const t = String(raw || '').replace(/```json\n?|\n?```/g, '').trim();
  try {
    return JSON.parse(t);
  } catch {
    return null;
  }
}

async function resolveWritingTextForSection(sec, attempt) {
  const sid = String(sec.sectionId || '').trim();
  const secAns = attempt.answers?.[sid];
  let text = secAns?.writingDraft != null ? String(secAns.writingDraft).trim() : '';
  if (text.length > 0) return text;

  const userId = resolveMongoUserId(attempt.userId);
  const startedAt = attempt.startedAt ? new Date(attempt.startedAt) : null;
  if (!userId || !startedAt) return '';
  const bounds = examTimeBounds(startedAt, attempt.submittedAt ? new Date(attempt.submittedAt) : new Date());

  for (const res of resourcesFromSkillSection(sec)) {
    const oid = resolveMongoResourceId(res.id);
    if (!oid) continue;
    const { records } = await fetchWritingRecord(userId, oid, bounds, { examOnly: true });
    if (records?.content) return String(records.content).trim();
  }
  return '';
}

export const examGradingService = {
  async runIntegratedWritingAi(teacherId, attempt) {
    const exam = attempt.examSnapshot || {};
    const writingSecs = findWritingSections(exam);
    if (writingSecs.length === 0) throw httpError(400, 'No writing section in this exam');

    if (!process.env.GROQ_API_KEY) throw httpError(503, 'AI grading unavailable');

    const skillOverrides = {};

    for (const sec of writingSecs) {
      const sid = String(sec.sectionId || '').trim();
      if (!sid) continue;
      const text = await resolveWritingTextForSection(sec, attempt);
      if (!text.length) {
        skillOverrides[sid] = {
          score: 0,
          gradingSource: 'auto_empty',
          note: 'No writing submitted',
        };
        continue;
      }

      const taskType = writingTaskTypeFromSection(sec);
      const fp = sec.fixedWritingPrompt || sec.fixedPrompt;
      const promptText =
        fp && typeof fp === 'object' && fp.text ? String(fp.text).slice(0, 4000) : '';

      const feedback = await aiService.generateFeedback(
        promptText ? `Exam prompt:\n${promptText}\n\nStudent essay:\n${text}` : text,
        taskType
      );
      const score10 = ieltsBandToExamTen(feedback.overall);
      if (score10 == null) continue;

      skillOverrides[sid] = {
        score: score10,
        gradingSource: 'ai',
        aiFeedback: feedback,
        aiDraftScore: score10,
        note: `AI (IELTS ${feedback.overall})`,
      };
    }

    const updated = patchIntegratedSkillScores(attempt.scores || {}, skillOverrides);
    attempt.scores = updated;
    if (updated.finalStatus === 'finalized') {
      attempt.gradingState = 'finalized';
    } else {
      attempt.gradingState = 'pending_manual';
    }
    await attempt.save();
    return attempt;
  },

  async runAiSuggestions(teacherId, attemptId) {
    const attempt = await assertTeacherOwnsAttempt(teacherId, attemptId);
    if (attempt.status !== 'submitted') throw httpError(400, 'Attempt must be submitted');

    const examFormat = attempt.examSnapshot?.settings?.examFormat;
    if (examFormat === 'integrated_four_skills' || examFormat === 'skills_exam') {
      return this.runIntegratedWritingAi(teacherId, attempt);
    }

    if (!process.env.GROQ_API_KEY) throw httpError(503, 'AI grading unavailable');

    const items = walkItems(attempt.examSnapshot.sections || []);
    const essayItems = items.filter((it) => it.kind === 'essay');
    if (essayItems.length === 0) return attempt;

    const scores = { ...(attempt.scores || {}), items: { ...(attempt.scores?.items || {}) } };

    const groq = getGroq();

    for (const it of essayItems) {
      const ans = attempt.answers[it.itemId];
      const text = extractEssayText(ans);
      const max = Number(it.points ?? 1);
      const existing = scores.items[it.itemId] || {};

      const userContent = `Grade this English learner essay for an exam.
Return JSON only with shape: {"points": number (0..${max}), "rubric": object optional, "rationale": string (<=500 chars)}
Question: ${String(it.stem || '').slice(0, 2000)}
Student answer:
${text || '(empty)'}`;

      const completion = await groq.chat.completions.create({
        model: GROQ_MODEL_NAME,
        messages: [
          { role: 'system', content: 'You output only compact JSON. No markdown fences.' },
          { role: 'user', content: userContent },
        ],
        temperature: 0.2,
      });
      const raw = completion.choices[0]?.message?.content || '{}';
      const parsed = parseJsonLoose(raw) || {};
      const pts = Math.max(0, Math.min(max, Number(parsed.points) || 0));
      scores.items[it.itemId] = {
        ...existing,
        kind: it.kind,
        maxPoints: max,
        ai: {
          points: pts,
          rubric: parsed.rubric && typeof parsed.rubric === 'object' ? parsed.rubric : undefined,
          rationale: String(parsed.rationale || '').slice(0, 2000),
          model: GROQ_MODEL_NAME,
          at: new Date().toISOString(),
        },
      };
    }

    attempt.scores = scores;
    await attempt.save();
    return attempt;
  },

  async patchManualGrade(teacherId, attemptId, body) {
    const attempt = await assertTeacherOwnsAttempt(teacherId, attemptId);

    const examFormat = attempt.examSnapshot?.settings?.examFormat;
    const isIntegrated =
      examFormat === 'integrated_four_skills' || examFormat === 'skills_exam';

    if (isIntegrated && body?.skillScores && typeof body.skillScores === 'object') {
      // --- Integrated exam: patch per-skill scores (0–10) ---
      const updated = patchIntegratedSkillScores(attempt.scores || {}, body.skillScores);
      attempt.scores = updated;
      if (body?.finalize === true || updated.finalStatus === 'finalized') {
        attempt.gradingState = 'finalized';
      }
      await attempt.save();
      return attempt;
    }

    // --- Non-integrated exam: legacy item-level grading ---
    const overrides = body?.items || body?.overrides || {};
    const items = walkItems(attempt.examSnapshot.sections || []);
    const scores = { ...(attempt.scores || {}), items: { ...(attempt.scores?.items || {}) } };

    for (const [itemId, o] of Object.entries(overrides)) {
      if (!itemId || !o || typeof o !== 'object') continue;
      const def = items.find((i) => i.itemId === itemId);
      const prev = scores.items[itemId] || {};
      const maxPts = Number(o.maxPoints ?? prev.maxPoints ?? def?.points ?? 1);
      let pts = o.awardedPoints != null ? Number(o.awardedPoints) : (prev.manual?.points ?? prev.awardedPoints ?? 0);
      let rubricBlock;
      if (o.rubricCriteria && typeof o.rubricCriteria === 'object') {
        let rubricSum = 0;
        const criteria = {};
        for (const [cid, val] of Object.entries(o.rubricCriteria)) {
          const n = Math.max(0, Number(val) || 0);
          criteria[cid] = n;
          rubricSum += n;
        }
        pts = Math.min(maxPts, rubricSum);
        rubricBlock = { criteria, total: rubricSum, at: new Date().toISOString() };
      }
      if (Number.isNaN(pts)) pts = 0;
      pts = Math.max(0, Math.min(maxPts, pts));
      scores.items[itemId] = {
        ...prev,
        maxPoints: maxPts,
        awardedPoints: pts,
        ...(rubricBlock ? { rubric: rubricBlock } : {}),
        manual: {
          points: pts,
          note: String(o.note || '').slice(0, 4000),
          teacherId: teacherId.toString(),
          at: new Date().toISOString(),
        },
        status: 'finalized',
      };
    }

    let totalAwarded = 0;
    let totalMax = 0;
    for (const it of items) {
      const max = Number(it.points ?? 1);
      if (['reading', 'listening'].includes(it.kind)) continue;
      totalMax += max;
      const ir = scores.items[it.itemId];
      if (!ir) continue;
      totalAwarded += Math.min(max, Number(ir.awardedPoints ?? 0));
    }
    scores.totalAwarded = totalAwarded;
    scores.totalMax = totalMax;

    attempt.scores = scores;
    if (body?.finalize === true) {
      attempt.gradingState = 'finalized';
    }
    await attempt.save();
    return attempt;
  },

  async releaseResults(teacherId, attemptId, body = {}) {
    const attempt = await assertTeacherOwnsAttempt(teacherId, attemptId);
    const wasReleased = !!attempt.resultsReleased;

    const detailLevel = body?.resultsDetailLevel;
    if (detailLevel === 'score_only' || detailLevel === 'full_detail') {
      const assignment = await ExamAssignment.findById(attempt.assignmentId);
      if (assignment) {
        assignment.config = {
          ...(assignment.config || {}),
          resultsDetailLevel: detailLevel,
        };
        await assignment.save();
      }
    }

    attempt.resultsReleased = true;
    attempt.gradingState = 'finalized';
    await attempt.save();
    if (!wasReleased) {
      try {
        const assignment = await ExamAssignment.findById(attempt.assignmentId)
          .select('classroomId')
          .lean();
        const { notifyStudentResultsReleased } = await import('./teacherNotificationHelper.js');
        const title = attempt.examSnapshot?.title || 'Exam';
        await notifyStudentResultsReleased({
          studentId: attempt.userId,
          teacherId,
          examTitle: title,
          attemptId: attempt._id,
          assignmentId: attempt.assignmentId,
          classroomId: assignment?.classroomId || null,
        });
      } catch {
        /* optional notification */
      }
    }
    return attempt;
  },

  async finalizeAttempt(teacherId, attemptId) {
    const attempt = await assertTeacherOwnsAttempt(teacherId, attemptId);
    if (attempt.status !== 'submitted') {
      throw httpError(400, 'Only submitted attempts can be finalized');
    }
    attempt.gradingState = 'finalized';
    await attempt.save();
    return attempt;
  },

  async runAiBatchForAssignment(teacherId, assignmentId) {
    await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);

    const submitted = await ExamAttempt.find({
      assignmentId,
      status: 'submitted',
    }).select('_id');

    const results = [];
    for (const row of submitted) {
      const id = row._id.toString();
      try {
        await this.runAiSuggestions(teacherId, id);
        results.push({ attemptId: id, ok: true });
      } catch (err) {
        results.push({ attemptId: id, ok: false, message: err.message || 'AI grading failed' });
      }
    }
    return { processed: results.length, results };
  },

  async batchReleaseResults(teacherId, assignmentId) {
    await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);
    const attempts = await ExamAttempt.find({
      assignmentId,
      status: 'submitted',
      resultsReleased: { $ne: true },
    });
    const results = [];
    for (const row of attempts) {
      const id = row._id.toString();
      try {
        await this.releaseResults(teacherId, id);
        results.push({ attemptId: id, ok: true });
      } catch (err) {
        results.push({ attemptId: id, ok: false, message: err.message || 'Release failed' });
      }
    }
    return { processed: results.length, results };
  },

  async batchFinalizeAttempts(teacherId, assignmentId) {
    await teacherExamAssignmentService.assertTeacherOwnsAssignment(teacherId, assignmentId);
    const attempts = await ExamAttempt.find({
      assignmentId,
      status: 'submitted',
      gradingState: { $ne: 'finalized' },
    });
    const results = [];
    for (const row of attempts) {
      const id = row._id.toString();
      try {
        await this.finalizeAttempt(teacherId, id);
        results.push({ attemptId: id, ok: true });
      } catch (err) {
        results.push({ attemptId: id, ok: false, message: err.message || 'Finalize failed' });
      }
    }
    return { processed: results.length, results };
  },
};
