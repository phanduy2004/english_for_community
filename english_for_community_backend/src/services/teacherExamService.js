import mongoose from 'mongoose';
import Exam from '../models/Exam.js';
import ExamAssignment from '../models/ExamAssignment.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamSession from '../models/ExamSession.js';
import Listening from '../models/Listening.js';
import SpeakingSet from '../models/SpeakingSet.js';
import Reading from '../models/Reading.js';
import WritingTopic from '../models/WritingTopics.js';
import { primaryResourceIdFromSection } from './examSkillSectionResources.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

export function walkItems(sections) {
  const out = [];
  if (!Array.isArray(sections)) return out;
  for (const sec of sections) {
    for (const item of sec.items || []) {
      out.push(item);
      if (item.kind === 'reading' || item.kind === 'listening') {
        for (const nested of item.nestedItems || []) {
          out.push(nested);
        }
      }
    }
  }
  return out;
}

/** Sections that link to existing skill CMS content (listening / speaking / reading / writing). */
export function walkSkillContentSections(sections) {
  const out = [];
  if (!Array.isArray(sections)) return out;
  for (const sec of sections) {
    if (!sec || sec.sectionKind !== 'skill_content' || !sec.skill) continue;
    if (primaryResourceIdFromSection(sec)) out.push(sec);
  }
  return out;
}

const INTEGRATED_FOUR_SKILLS_ORDER = ['listening', 'speaking', 'reading', 'writing'];
/** Vertical exam order for `skills_exam` (Grammar is in settings, not a section). */
const SKILLS_EXAM_SKILL_ORDER = ['reading', 'listening', 'writing', 'speaking'];

async function assertSkillResourceExists(skill, resourceId) {
  if (!resourceId || !mongoose.isValidObjectId(String(resourceId))) {
    throw httpError(400, `Invalid resource id for skill ${skill}`);
  }
  const oid = new mongoose.Types.ObjectId(String(resourceId));
  let doc;
  if (skill === 'listening') doc = await Listening.findById(oid).select('_id');
  else if (skill === 'speaking') doc = await SpeakingSet.findById(oid).select('_id');
  else if (skill === 'reading') doc = await Reading.findById(oid).select('_id');
  else if (skill === 'writing') doc = await WritingTopic.findById(oid).select('_id');
  else throw httpError(400, `Unknown skill ${skill}`);
  if (!doc) throw httpError(400, `Referenced ${skill} content was not found`);
}

async function validateIntegratedFourSkillsExam(exam) {
  if (!exam.title || !String(exam.title).trim()) throw httpError(400, 'Exam title is required');
  const sections = Array.isArray(exam.sections) ? exam.sections : [];
  if (sections.length !== 4) {
    throw httpError(400, 'Integrated exam must have exactly 4 sections (listening, speaking, reading, writing)');
  }
  const sorted = [...sections].sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
  for (let i = 0; i < 4; i += 1) {
    const sec = sorted[i];
    const expected = INTEGRATED_FOUR_SKILLS_ORDER[i];
    if (!sec || sec.sectionKind !== 'skill_content') {
      throw httpError(400, `Section ${i + 1} must be a skill_content section`);
    }
    if (String(sec.skill) !== expected) {
      throw httpError(400, `Section order ${i + 1} must be skill "${expected}"`);
    }
    if (!sec.sectionId || !String(sec.sectionId).trim()) {
      throw httpError(400, `Section ${i + 1} needs a stable sectionId`);
    }
    const resourceId = primaryResourceIdFromSection(sec);
    if (!resourceId) {
      throw httpError(400, `Section ${expected} needs a selected exercise (resourceId)`);
    }
    await assertSkillResourceExists(expected, resourceId);
  }
}

function validateGrammarBlanks(it, label) {
  if (!Array.isArray(it.blanks) || it.blanks.length === 0) {
    throw httpError(400, `${label} needs blanks array`);
  }
  for (const b of it.blanks) {
    if (!b.blankId && b.blankId !== 0) throw httpError(400, `${label} blank needs blankId`);
    if (!Array.isArray(b.acceptedAnswers) || b.acceptedAnswers.length === 0) {
      throw httpError(400, `${label} blank ${b.blankId} needs acceptedAnswers`);
    }
  }
}

function validateGrammarItem(it, idx) {
  const label = `Grammar item ${idx + 1}`;
  if (!it || typeof it !== 'object') throw httpError(400, `${label} is invalid`);
  if (!it.itemId || !String(it.itemId).trim()) throw httpError(400, `${label} must have itemId`);
  const kind = String(it.kind || '');
  const pts = Number(it.points ?? 1);
  if (Number.isNaN(pts) || pts < 0) throw httpError(400, `${label} has invalid points`);

  if (kind === 'mcq_single' || kind === 'mcq_multi') {
    if (!it.prompt || !String(it.prompt).trim()) throw httpError(400, `${label} needs prompt`);
    if (!Array.isArray(it.options) || it.options.length < 2) {
      throw httpError(400, `${label} needs at least 2 options`);
    }
    if (!Array.isArray(it.correctOptionIndexes) || it.correctOptionIndexes.length === 0) {
      throw httpError(400, `${label} needs correctOptionIndexes`);
    }
    return;
  }

  if (kind === 'grammar_cloze') {
    if (!it.passage || !String(it.passage).trim()) throw httpError(400, `${label} needs passage with {{0}}, {{1}}, ...`);
    if (!/\{\{[0-9]+\}\}/.test(String(it.passage))) {
      throw httpError(400, `${label} passage must contain {{0}} style placeholders`);
    }
    validateGrammarBlanks(it, label);
    return;
  }

  if (kind === 'grammar_gap') {
    if (!it.textBefore || !it.textAfter) throw httpError(400, `${label} needs textBefore and textAfter`);
    validateGrammarBlanks(it, label);
    if (it.blanks.length !== 1) throw httpError(400, `${label} (gap) must have exactly one blank`);
    return;
  }

  if (kind === 'grammar_matching') {
    const left = it.leftItems || it.leftColumn;
    const right = it.rightItems || it.rightColumn;
    if (!Array.isArray(left) || !Array.isArray(right) || left.length < 2 || left.length !== right.length) {
      throw httpError(400, `${label} needs leftItems and rightItems of same length (>=2)`);
    }
    for (const row of left) {
      if (!row.id || !String(row.text ?? '').trim()) throw httpError(400, `${label} each leftItems row needs id and text`);
    }
    for (const row of right) {
      if (!row.id || !String(row.text ?? '').trim()) throw httpError(400, `${label} each rightItems row needs id and text`);
    }
    const corr = it.correctPairs;
    if (!Array.isArray(corr) || corr.length !== left.length) {
      throw httpError(400, `${label} needs correctPairs array (one pair per row)`);
    }
    for (const p of corr) {
      if (!Array.isArray(p) || p.length !== 2) throw httpError(400, `${label} each correctPairs entry must be [leftId, rightId]`);
    }
    return;
  }

  if (kind === 'grammar_reorder') {
    if (!Array.isArray(it.fragments) || it.fragments.length < 2) {
      throw httpError(400, `${label} needs at least 2 fragments`);
    }
    const n = it.fragments.length;
    const ord = it.correctOrder;
    if (!Array.isArray(ord) || ord.length !== n) {
      throw httpError(400, `${label} needs correctOrder permutation of fragment indices`);
    }
    const sorted = [...ord].map(Number).sort((a, b) => a - b);
    for (let i = 0; i < n; i += 1) {
      if (sorted[i] !== i) throw httpError(400, `${label} correctOrder must be a permutation of 0..n-1`);
    }
    return;
  }

  throw httpError(400, `${label} has unsupported kind "${kind}"`);
}

function allSkillContentSections(sections) {
  if (!Array.isArray(sections)) return [];
  return sections
    .filter((s) => s && (s.sectionKind === 'skill_content' || s.sectionKind == null) && s.skill)
    .sort((a, b) => Number(a.order ?? 0) - Number(b.order ?? 0));
}

/** Subset of four CMS-linked skills + optional Grammar (MCQ in settings.grammarItems). */
async function validateSkillsExam(exam) {
  if (!exam.title || !String(exam.title).trim()) throw httpError(400, 'Exam title is required');
  const sections = allSkillContentSections(exam.sections);
  const grammarItems = Array.isArray(exam.settings?.grammarItems) ? exam.settings.grammarItems : [];
  if (sections.length === 0 && grammarItems.length === 0) {
    throw httpError(400, 'Enable at least one skill with content or add at least one Grammar question');
  }
  const seen = new Set();
  let lastIdx = -1;
  for (const sec of sections) {
    const sk = String(sec.skill || '');
    if (!SKILLS_EXAM_SKILL_ORDER.includes(sk)) {
      throw httpError(400, `Unknown skill section "${sk}"`);
    }
    if (seen.has(sk)) throw httpError(400, `Duplicate skill section "${sk}"`);
    seen.add(sk);
    const idx = SKILLS_EXAM_SKILL_ORDER.indexOf(sk);
    if (idx <= lastIdx) {
      throw httpError(400, 'Skill sections must follow exam order: reading → listening → writing → speaking');
    }
    lastIdx = idx;
    if (!sec.sectionId || !String(sec.sectionId).trim()) {
      throw httpError(400, `Section for ${sk} needs sectionId`);
    }
    if (sk === 'writing') {
      const promptText = sec.fixedWritingPrompt?.text ?? sec.fixedPrompt?.text;
      const resourceId = primaryResourceIdFromSection(sec);
      if (!resourceId && !String(promptText || '').trim()) {
        throw httpError(400, 'Writing needs a linked topic or a fixed writing prompt');
      }
      if (resourceId) await assertSkillResourceExists('writing', resourceId);
      continue;
    }
    const resourceId = primaryResourceIdFromSection(sec);
    if (!resourceId) {
      throw httpError(400, `Skill ${sk} needs a selected exercise (resourceId)`);
    }
    await assertSkillResourceExists(sk, resourceId);
  }
  grammarItems.forEach((it, i) => validateGrammarItem(it, i));
  const grammarPointsSum = grammarItems.reduce((s, it) => s + Number(it.points ?? 1), 0);
  if (sections.length > 0 && grammarPointsSum > 100) {
    throw httpError(400, 'Total Grammar points cannot exceed 100 when the exam includes skill parts');
  }
  if (sections.length === 0 && grammarPointsSum > 100) {
    throw httpError(400, 'Total Grammar points cannot exceed 100');
  }
}

async function validatePublishedExam(exam) {
  const fmt = exam?.settings?.examFormat;
  if (fmt === 'integrated_four_skills') {
    await validateIntegratedFourSkillsExam(exam);
    return;
  }
  if (fmt === 'skills_exam') {
    await validateSkillsExam(exam);
    return;
  }
  if (!exam.title || !String(exam.title).trim()) throw httpError(400, 'Exam title is required');
  if (!Array.isArray(exam.sections) || exam.sections.length === 0) {
    throw httpError(400, 'At least one section is required');
  }
  const items = walkItems(exam.sections);
  if (items.length === 0) throw httpError(400, 'At least one question item is required');

  for (const it of items) {
    if (!it.itemId || !it.kind) throw httpError(400, 'Each item must have itemId and kind');
    const pts = Number(it.points ?? 1);
    if (Number.isNaN(pts) || pts < 0) throw httpError(400, `Invalid points for item ${it.itemId}`);

    if (it.kind === 'mcq_single' || it.kind === 'mcq_multi') {
      if (!Array.isArray(it.options) || it.options.length < 2) {
        throw httpError(400, `MCQ ${it.itemId} needs at least 2 options`);
      }
      if (!Array.isArray(it.correctOptionIndexes) || it.correctOptionIndexes.length === 0) {
        throw httpError(400, `MCQ ${it.itemId} needs correctOptionIndexes`);
      }
    }
    if (it.kind === 'fill_blank') {
      if (!Array.isArray(it.blanks) || it.blanks.length === 0) {
        throw httpError(400, `fill_blank ${it.itemId} needs blanks`);
      }
    }
    if (it.kind === 'listening') {
      if (!it.audioUrl) throw httpError(400, `listening ${it.itemId} needs audioUrl`);
    }
    if (it.kind === 'essay' && !it.prompt) throw httpError(400, `essay ${it.itemId} needs prompt`);
    if (it.kind === 'speaking' && !it.prompt) throw httpError(400, `speaking ${it.itemId} needs prompt`);
    if (it.kind === 'reading' && !it.passage) throw httpError(400, `reading ${it.itemId} needs passage`);
  }
}

const defaultSettings = {
  shuffleSections: false,
  shuffleItems: false,
  defaultItemPoints: 1,
  timeLimitSeconds: null,
  allowBackNavigation: true,
  showResultsPolicy: 'after_release',
  allowMultipleSubmissions: false,
  negativeMarking: false,
  multiSelectGrading: 'partial_by_correct_ratio',
};

export const teacherExamService = {
  walkItems,
  walkSkillContentSections,

  async assertTeacherOwnsExam(teacherId, examId) {
    const exam = await Exam.findById(examId);
    if (!exam) throw httpError(404, 'Exam not found');
    if (exam.teacherId.toString() !== teacherId.toString()) throw httpError(403, 'Forbidden');
    return exam;
  },

  async createDraft(teacherId, body) {
    const title = String(body?.title || 'Untitled exam').trim();
    const exam = await Exam.create({
      teacherId,
      title,
      description: String(body?.description || ''),
      status: 'draft',
      sections: Array.isArray(body?.sections) ? body.sections : [],
      settings: { ...defaultSettings, ...(body?.settings || {}) },
    });
    return exam;
  },

  async listMine(teacherId) {
    return Exam.find({ teacherId }).sort({ updatedAt: -1 });
  },

  async getOwned(teacherId, examId) {
    return this.assertTeacherOwnsExam(teacherId, examId);
  },

  async updateDraft(teacherId, examId, body) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    if (exam.status === 'archived') {
      throw httpError(400, 'Archived exams cannot be edited. Restore the exam first.');
    }
    if (body.title != null) exam.title = String(body.title).trim();
    if (body.description != null) exam.description = String(body.description);
    if (body.sections != null) {
      exam.sections = body.sections;
      if (exam.status === 'published') {
        const candidate = exam.toObject ? exam.toObject() : { ...exam };
        await validatePublishedExam(candidate);
      }
    }
    if (body.settings != null) exam.settings = { ...defaultSettings, ...exam.settings, ...body.settings };
    exam.contentVersion = (exam.contentVersion || 1) + 1;
    await exam.save();
    return exam;
  },

  async publish(teacherId, examId) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    await validatePublishedExam(exam);
    exam.status = 'published';
    await exam.save();
    return exam;
  },

  async archive(teacherId, examId) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    exam.status = 'archived';
    await exam.save();
    return exam;
  },

  async restore(teacherId, examId) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    if (exam.status !== 'archived') throw httpError(400, 'Only archived exams can be restored');
    try {
      await validatePublishedExam(exam);
      exam.status = 'published';
    } catch {
      exam.status = 'draft';
    }
    await exam.save();
    return exam;
  },

  async deletePermanently(teacherId, examId) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    const assignments = await ExamAssignment.find({ examId: exam._id }).select('_id');
    const assignmentIds = assignments.map((a) => a._id);
    if (assignmentIds.length > 0) {
      const submitted = await ExamAttempt.countDocuments({
        assignmentId: { $in: assignmentIds },
        status: 'submitted',
      });
      if (submitted > 0) {
        throw httpError(
          400,
          'Cannot delete this exam: students have submitted attempts. Archive the exam instead.'
        );
      }
      await ExamAttempt.deleteMany({ assignmentId: { $in: assignmentIds } });
      await ExamSession.deleteMany({ assignmentId: { $in: assignmentIds } });
      await ExamAssignment.deleteMany({ _id: { $in: assignmentIds } });
    }
    await exam.deleteOne();
    return { deleted: true, examId: examId.toString() };
  },

  async duplicateExam(teacherId, examId) {
    const exam = await this.assertTeacherOwnsExam(teacherId, examId);
    const base = exam.toObject();
    delete base._id;
    delete base.createdAt;
    delete base.updatedAt;
    const copy = await Exam.create({
      ...base,
      teacherId,
      title: `${base.title || 'Exam'} (copy)`,
      status: 'draft',
      contentVersion: 1,
    });
    return copy;
  },
};
