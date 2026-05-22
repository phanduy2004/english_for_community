import { Router } from 'express';
import { authenticate, requirePermissions } from '../middleware/auth.js';
import { Permission } from '../constants/permissions.js';
import { examStrictLimiter } from '../middleware/examRateLimit.js';
import * as teacherApplicationController from '../controllers/teacherApplicationController.js';
import * as teacherExamController from '../controllers/teacherExamController.js';

const router = Router();
router.use(authenticate);

router.post(
  '/applications',
  requirePermissions(Permission.TEACHER_APPLICATION_CREATE),
  teacherApplicationController.createTeacherApplication
);
router.get(
  '/applications/me',
  requirePermissions(Permission.TEACHER_APPLICATION_READ_OWN),
  teacherApplicationController.getMyTeacherApplication
);
router.post(
  '/applications/withdraw',
  requirePermissions(Permission.TEACHER_APPLICATION_CREATE),
  teacherApplicationController.withdrawTeacherApplication
);

router.get(
  '/exams/grading-attempts/:attemptId',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.getAttemptForGrading
);

router.get(
  '/dashboard/action-items',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.getTeacherDashboardActionItems
);
router.get(
  '/dashboard/analytics',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.getTeacherAnalyticsSummary
);
router.get(
  '/dashboard/calendar',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.getTeacherCalendarEvents
);

router.get(
  '/assignment-presets',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.listAssignmentPresets
);
router.post(
  '/assignment-presets',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.createAssignmentPreset
);
router.delete(
  '/assignment-presets/:presetId',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.deleteAssignmentPreset
);

router.post(
  '/exams/writing/generate-prompt-options',
  requirePermissions(Permission.TEACHER_EXAM_MANAGE),
  teacherExamController.generateWritingPromptOptions
);

router.post('/exams', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.createExamDraft);
router.get('/exams', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.listMyExams);

router.post(
  '/exams/assignments',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.createAssignment
);
router.patch(
  '/exams/assignments/:assignmentId',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.patchAssignment
);
router.post(
  '/exams/assignments/:assignmentId/duplicate',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.duplicateAssignment
);
router.post(
  '/exams/assignments/:assignmentId/close',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.closeAssignment
);
router.delete(
  '/exams/assignments/:assignmentId',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.deleteAssignment
);
router.post(
  '/exams/assignments/:assignmentId/public-join/rotate',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.rotatePublicJoin
);
router.get(
  '/exams/assignments',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.listMyAssignments
);
router.get(
  '/exams/classrooms/:classroomId/assignments',
  requirePermissions(Permission.TEACHER_EXAM_ASSIGN),
  teacherExamController.listClassroomAssignments
);
router.get(
  '/exams/classrooms/:classroomId/gradebook',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.getClassroomGradebook
);
router.get(
  '/exams/classrooms/:classroomId/gradebook/export.csv',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.exportClassroomGradebookCsv
);
router.get(
  '/exams/assignments/:assignmentId/attempts',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.listAssignmentAttempts
);
router.get(
  '/exams/assignments/:assignmentId/attempts/export.xlsx',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.exportAssignmentAttemptsXlsx
);
router.get(
  '/exams/assignments/:assignmentId/integrity-summary',
  requirePermissions(Permission.TEACHER_GRADING_READ),
  teacherExamController.getAssignmentIntegritySummary
);

router.get(
  '/exams/assignments/:assignmentId/session-console',
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.getSessionConsole
);
router.post(
  '/exams/assignments/:assignmentId/sessions',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.createExamSession
);
router.get(
  '/exams/sessions/:sessionId/lobby',
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.getExamSessionLobby
);
router.get(
  '/exams/sessions/:sessionId/live-monitor',
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.getSessionLiveMonitor
);
router.get(
  '/exams/attempts/:attemptId/live-screen',
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.getAttemptLiveScreen
);
router.post(
  '/exams/sessions/:sessionId/start',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.startExamSession
);
router.post(
  '/exams/sessions/:sessionId/end',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.endExamSession
);
router.post(
  '/exams/sessions/:sessionId/kick',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_EXAM_SESSION_RUN),
  teacherExamController.kickExamSessionParticipant
);

router.post(
  '/exams/attempts/:attemptId/ai-suggestions',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.runAiGradingDraft
);
router.patch(
  '/exams/attempts/:attemptId/manual-grade',
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.patchManualGrade
);
router.post(
  '/exams/attempts/:attemptId/release-results',
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.releaseExamResults
);
router.post(
  '/exams/attempts/:attemptId/finalize',
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.finalizeExamAttempt
);
router.post(
  '/exams/assignments/:assignmentId/grading/ai-batch',
  examStrictLimiter,
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.runAiGradingBatch
);
router.post(
  '/exams/assignments/:assignmentId/grading/batch-release',
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.batchReleaseExamResults
);
router.post(
  '/exams/assignments/:assignmentId/grading/batch-finalize',
  requirePermissions(Permission.TEACHER_GRADING_WRITE),
  teacherExamController.batchFinalizeExamAttempts
);

router.get('/exams/:examId', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.getExam);
router.post(
  '/exams/:examId/duplicate',
  requirePermissions(Permission.TEACHER_EXAM_MANAGE),
  teacherExamController.duplicateExam
);
router.patch('/exams/:examId', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.updateExamDraft);
router.post('/exams/:examId/publish', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.publishExam);
router.post('/exams/:examId/archive', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.archiveExam);
router.post('/exams/:examId/restore', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.restoreExam);
router.delete('/exams/:examId', requirePermissions(Permission.TEACHER_EXAM_MANAGE), teacherExamController.deleteExam);

export default router;
