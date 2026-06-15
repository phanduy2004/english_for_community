import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import { examStandardLimiter, examStrictLimiter, examPublicJoinLimiter } from '../middleware/examRateLimit.js';
import * as examStudentController from '../controllers/examStudentController.js';

const router = Router();

router.use(authenticate);

router.get('/public/:token/preview', examPublicJoinLimiter, examStudentController.previewPublicExam);
router.post('/public/:token/start', examPublicJoinLimiter, examStudentController.startPublicExamAttempt);
router.post('/public/:token/join', examPublicJoinLimiter, examStudentController.joinPublicExamSession);

router.use(examStandardLimiter);

router.get(
  '/classrooms/:classroomId/assignments/available',
  examStudentController.listAvailableAssignmentsForClassroom
);
router.get('/assignments/available', examStudentController.listAvailableAssignments);
router.post('/assignments/:assignmentId/start', examStudentController.startExamAttempt);
router.post('/sessions/:sessionId/join', examStudentController.joinExamSession);
router.get('/sessions/:sessionId/my-attempt', examStudentController.getMySessionAttempt);

router.patch('/attempts/:attemptId', examStudentController.patchExamAttempt);
router.patch('/attempts/:attemptId/live-view', examStudentController.patchAttemptLiveView);
router.post('/attempts/:attemptId/integrity', examStudentController.reportExamAttemptIntegrity);
router.post('/attempts/:attemptId/submit', examStudentController.submitExamAttempt);
router.post('/attempts/:attemptId/abandon', examStudentController.abandonRealtimeExamAttempt);
router.get('/attempts/:attemptId', examStudentController.getExamAttempt);

export default router;
