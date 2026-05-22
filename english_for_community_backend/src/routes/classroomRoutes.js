import { Router } from 'express';
import { authenticate, requirePermissions } from '../middleware/auth.js';
import { Permission } from '../constants/permissions.js';
import * as classroomController from '../controllers/classroomController.js';

const router = Router();

router.post('/lti/launch', classroomController.ltiLaunchStub);

router.post('/join-by-code', authenticate, classroomController.joinClassroomByCode);
router.post('/join-by-token', authenticate, classroomController.joinClassroomByToken);
router.get('/enrolled', authenticate, classroomController.listMyEnrolledClassrooms);

router.post('/', authenticate, requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE), classroomController.createClassroom);
router.get('/mine', authenticate, requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE), classroomController.listMyClassroomsAsTeacher);
router.get('/:id', authenticate, classroomController.getClassroom);
router.patch('/:id', authenticate, requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE), classroomController.updateClassroom);
router.post('/:id/archive', authenticate, requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE), classroomController.archiveClassroom);
router.post(
  '/:id/rotate-invite',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE),
  classroomController.rotateClassroomInvite
);
router.get(
  '/:id/members',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.listClassroomMembers
);
router.get(
  '/:id/activity',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE),
  classroomController.listClassroomActivity
);
router.get(
  '/integrations/status',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE),
  classroomController.getIntegrationsStatus
);
router.post(
  '/:id/co-teachers',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.addCoTeacher
);
router.post(
  '/:id/co-teachers/:userId/remove',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.removeCoTeacher
);
router.post(
  '/:id/integrations/google-classroom/link',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE),
  classroomController.linkGoogleClassroom
);
router.post(
  '/:id/integrations/google-classroom/unlink',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MANAGE),
  classroomController.unlinkGoogleClassroom
);
router.post(
  '/:id/members/:userId/approve',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.approveClassroomMember
);
router.post(
  '/:id/members/:userId/reject',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.rejectClassroomMember
);
router.post(
  '/:id/members/:userId/remove',
  authenticate,
  requirePermissions(Permission.TEACHER_CLASSROOM_MEMBERS_MANAGE),
  classroomController.removeClassroomMember
);

export default router;
