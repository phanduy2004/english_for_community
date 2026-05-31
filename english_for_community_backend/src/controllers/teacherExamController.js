import { teacherExamService } from '../services/teacherExamService.js';
import { teacherExamAssignmentService } from '../services/teacherExamAssignmentService.js';
import { examAttemptService } from '../services/examAttemptService.js';
import { examSessionService } from '../services/examSessionService.js';
import { examGradingService } from '../services/examGradingService.js';
import { teacherGradebookService } from '../services/teacherGradebookService.js';
import { teacherAssignmentScoresExportService } from '../services/teacherAssignmentScoresExportService.js';
import { teacherDashboardService } from '../services/teacherDashboardService.js';
import { teacherAssignmentPresetService } from '../services/teacherAssignmentPresetService.js';
import { teacherAnalyticsChartsService } from '../services/teacherAnalyticsChartsService.js';
import { examIntegrityService } from '../services/examIntegrityService.js';
import { aiService } from '../services/aiService.js';
import WritingTopic from '../models/WritingTopics.js';

const getStatusCode = (err) => err.statusCode || 500;

export const getAttemptForGrading = async (req, res) => {
  try {
    const doc = await examAttemptService.getAttemptForTeacherGrading(req.user._id, req.params.attemptId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const createExamDraft = async (req, res) => {
  try {
    const doc = await teacherExamService.createDraft(req.user._id, req.body);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listMyExams = async (req, res) => {
  try {
    const list = await teacherExamService.listMine(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getExam = async (req, res) => {
  try {
    const doc = await teacherExamService.getOwned(req.user._id, req.params.examId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const updateExamDraft = async (req, res) => {
  try {
    const doc = await teacherExamService.updateDraft(req.user._id, req.params.examId, req.body);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const publishExam = async (req, res) => {
  try {
    const doc = await teacherExamService.publish(req.user._id, req.params.examId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const archiveExam = async (req, res) => {
  try {
    const doc = await teacherExamService.archive(req.user._id, req.params.examId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const restoreExam = async (req, res) => {
  try {
    const doc = await teacherExamService.restore(req.user._id, req.params.examId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const deleteExam = async (req, res) => {
  try {
    const doc = await teacherExamService.deletePermanently(req.user._id, req.params.examId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const duplicateExam = async (req, res) => {
  try {
    const doc = await teacherExamService.duplicateExam(req.user._id, req.params.examId);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getTeacherDashboardActionItems = async (req, res) => {
  try {
    const doc = await teacherDashboardService.getActionItems(req.user._id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getTeacherAnalyticsSummary = async (req, res) => {
  try {
    const summary = await teacherDashboardService.getAnalyticsSummary(req.user._id);
    const charts = await teacherAnalyticsChartsService.getCharts(req.user._id, {
      days: req.query.days,
    });
    return res.status(200).json({ summary, charts });
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getAssignmentIntegritySummary = async (req, res) => {
  try {
    const doc = await examIntegrityService.summaryForAssignment(
      req.user._id,
      req.params.assignmentId
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getTeacherCalendarEvents = async (req, res) => {
  try {
    const doc = await teacherDashboardService.getCalendarEvents(req.user._id, {
      from: req.query.from,
      to: req.query.to,
    });
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getClassroomGradebook = async (req, res) => {
  try {
    const doc = await teacherGradebookService.getClassroomGradebook(req.user._id, req.params.classroomId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const exportClassroomGradebookCsv = async (req, res) => {
  try {
    const data = await teacherGradebookService.getClassroomGradebook(req.user._id, req.params.classroomId);
    const csv = teacherGradebookService.gradebookToCsv(data);
    const name = (data.classroom?.name || 'gradebook').replace(/[^\w\-]+/g, '_');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${name}-gradebook.csv"`);
    return res.status(200).send(`\uFEFF${csv}`);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listAssignmentPresets = async (req, res) => {
  try {
    const list = await teacherAssignmentPresetService.list(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const createAssignmentPreset = async (req, res) => {
  try {
    const doc = await teacherAssignmentPresetService.create(req.user._id, req.body);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const deleteAssignmentPreset = async (req, res) => {
  try {
    const doc = await teacherAssignmentPresetService.remove(req.user._id, req.params.presetId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const createAssignment = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.create(req.user._id, req.body);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const duplicateAssignment = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.duplicateAssignment(
      req.user._id,
      req.params.assignmentId,
      req.body || {}
    );
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const patchAssignment = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.patchAssignment(
      req.user._id,
      req.params.assignmentId,
      req.body || {}
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const closeAssignment = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.closeAssignment(req.user._id, req.params.assignmentId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const deleteAssignment = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.deleteAssignment(
      req.user._id,
      req.params.assignmentId
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const rotatePublicJoin = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.rotatePublicJoinToken(req.user._id, req.params.assignmentId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listMyAssignments = async (req, res) => {
  try {
    const list = await teacherExamAssignmentService.listForTeacher(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listClassroomAssignments = async (req, res) => {
  try {
    const list = await teacherExamAssignmentService.listForTeacherInClassroom(
      req.user._id,
      req.params.classroomId
    );
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listAssignmentAttempts = async (req, res) => {
  try {
    const hub = await examAttemptService.getAssignmentGradingHub(req.user._id, req.params.assignmentId);
    return res.status(200).json(hub);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const exportAssignmentAttemptsXlsx = async (req, res) => {
  try {
    const { buffer, filename } = await teacherAssignmentScoresExportService.buildXlsx(
      req.user._id,
      req.params.assignmentId
    );
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    return res.status(200).send(Buffer.from(buffer));
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getSessionConsole = async (req, res) => {
  try {
    const doc = await examSessionService.getSessionConsoleForTeacher(req.user._id, req.params.assignmentId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const createExamSession = async (req, res) => {
  try {
    const doc = await examSessionService.createSession(req.user._id, req.params.assignmentId);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getExamSessionLobby = async (req, res) => {
  try {
    const doc = await examSessionService.getSessionLobbyForTeacher(req.user._id, req.params.sessionId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getSessionLiveMonitor = async (req, res) => {
  try {
    const { examLiveMonitorService } = await import('../services/examLiveMonitorService.js');
    const doc = await examLiveMonitorService.buildSnapshotForTeacher(
      req.user._id,
      req.params.sessionId
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getAttemptLiveScreen = async (req, res) => {
  try {
    const { examLiveMonitorService } = await import('../services/examLiveMonitorService.js');
    const doc = await examLiveMonitorService.getLiveScreenForTeacher(
      req.user._id,
      req.params.attemptId
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const startExamSession = async (req, res) => {
  try {
    const doc = await examSessionService.startSession(req.user._id, req.params.sessionId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const endExamSession = async (req, res) => {
  try {
    const doc = await examSessionService.endSession(req.user._id, req.params.sessionId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const kickExamSessionParticipant = async (req, res) => {
  try {
    const userId = req.body?.userId;
    if (!userId) return res.status(400).json({ message: 'userId is required' });
    const payload = await examSessionService.kickParticipant(
      req.user._id,
      req.params.sessionId,
      userId
    );
    return res.status(200).json(payload);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const runAiGradingDraft = async (req, res) => {
  try {
    const doc = await examGradingService.runAiSuggestions(req.user._id, req.params.attemptId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const patchManualGrade = async (req, res) => {
  try {
    const doc = await examGradingService.patchManualGrade(req.user._id, req.params.attemptId, req.body || {});
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const releaseExamResults = async (req, res) => {
  try {
    const doc = await examGradingService.releaseResults(
      req.user._id,
      req.params.attemptId,
      req.body || {}
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const finalizeExamAttempt = async (req, res) => {
  try {
    const doc = await examGradingService.finalizeAttempt(req.user._id, req.params.attemptId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const runAiGradingBatch = async (req, res) => {
  try {
    const doc = await examGradingService.runAiBatchForAssignment(
      req.user._id,
      req.params.assignmentId
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const batchReleaseExamResults = async (req, res) => {
  try {
    const doc = await examGradingService.batchReleaseResults(req.user._id, req.params.assignmentId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const batchFinalizeExamAttempts = async (req, res) => {
  try {
    const doc = await examGradingService.batchFinalizeAttempts(req.user._id, req.params.assignmentId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

/**
 * POST /api/teacher/exams/writing/generate-prompt-options
 * Body: { topicId, taskType? }
 * Generates 3 writing prompt variations for a topic (for teacher to pick one).
 */
const WRITING_TASK_TYPE_ALIASES = {
  Opinion: 'Agree or Disagree',
  Discussion: 'Discuss both views',
  'Advantages-Disadvantages': 'Advantages and Disadvantages',
  'Problem-Solution': 'Problem and Solution',
  'Discuss both views and give your own opinion': 'Discuss both views',
  'Two-part question': 'Essay',
};

function normalizeWritingTaskTypeForExam(tt) {
  const s = String(tt || '').trim();
  if (!s) return 'Essay';
  return WRITING_TASK_TYPE_ALIASES[s] || s;
}

export const generateWritingPromptOptions = async (req, res) => {
  try {
    const { topicId, taskType, topicName } = req.body;
    let topic;
    if (topicId) {
      topic = await WritingTopic.findById(topicId).lean();
      if (!topic) return res.status(404).json({ message: 'Writing topic not found' });
    } else {
      const name = String(topicName || '').trim();
      if (!name) {
        return res.status(400).json({ message: 'topicId or topicName is required' });
      }
      topic = {
        name,
        aiConfig: {
          level: 'Intermediate',
          defaultTaskType: 'Essay',
          taskTypes: ['Essay', 'Agree or Disagree', 'Discuss both views'],
        },
      };
    }

    const resolvedTaskType = normalizeWritingTaskTypeForExam(
      taskType || topic.aiConfig?.defaultTaskType || 'Essay'
    );
    const rawTypes = topic.aiConfig?.taskTypes?.length
      ? topic.aiConfig.taskTypes.map((t) => normalizeWritingTaskTypeForExam(t))
      : [resolvedTaskType, 'Discuss both views', 'Agree or Disagree'];
    const taskTypes = [...new Set(rawTypes)];

    const generateOne = async (tt) => {
      const normalized = normalizeWritingTaskTypeForExam(tt);
      try {
        const row = await aiService.generateWritingPrompt(topic.name, topic.aiConfig, normalized);
        return { ...row, taskType: normalized };
      } catch {
        return {
          title: topic.name,
          text: `Write about "${topic.name}". ${normalized} — give your opinion and support it with examples.`,
          taskType: normalized,
          level: topic.aiConfig?.level || 'Intermediate',
        };
      }
    };

    const types = (taskType ? [resolvedTaskType, ...taskTypes] : taskTypes).slice(0, 3);
    const options = await Promise.all(types.map((tt) => generateOne(tt)));
    return res.status(200).json({ options });
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};
