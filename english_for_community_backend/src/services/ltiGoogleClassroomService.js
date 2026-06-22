import Classroom from '../models/Classroom.js';
import { httpError } from '../utils/AppError.js';
import { classroomService } from './classroomService.js';

export const ltiGoogleClassroomService = {
  getStatus() {
    return {
      googleClassroom: {
        configured: !!(process.env.GOOGLE_CLASSROOM_CLIENT_ID && process.env.GOOGLE_CLASSROOM_CLIENT_SECRET),
        redirectUri: process.env.GOOGLE_CLASSROOM_REDIRECT_URI || null,
      },
      lti: {
        configured: !!(process.env.LTI_PLATFORM_ISSUER && process.env.LTI_CLIENT_ID),
        issuer: process.env.LTI_PLATFORM_ISSUER || null,
      },
    };
  },

  async linkGoogleCourse(teacherId, classroomId, { googleCourseId, googleCourseName } = {}) {
    await classroomService.assertCanManageClassroom(teacherId, classroomId);
    if (!googleCourseId) throw httpError(400, 'googleCourseId is required');
    const classroom = await Classroom.findById(classroomId);
    if (!classroom) throw httpError(404, 'Classroom not found');
    classroom.integrations = {
      ...(classroom.integrations || {}),
      googleClassroom: {
        courseId: String(googleCourseId),
        courseName: String(googleCourseName || '').slice(0, 200),
        linkedAt: new Date().toISOString(),
      },
    };
    await classroom.save();
    return classroom;
  },

  async unlinkGoogleCourse(teacherId, classroomId) {
    await classroomService.assertCanManageClassroom(teacherId, classroomId);
    const classroom = await Classroom.findById(classroomId);
    if (!classroom) throw httpError(404, 'Classroom not found');
    if (classroom.integrations?.googleClassroom) {
      classroom.integrations = { ...classroom.integrations, googleClassroom: null };
    }
    await classroom.save();
    return classroom;
  },

  /** LTI 1.3 launch stub — validates minimal body and returns deep link payload. */
  async ltiLaunchStub(body = {}) {
    if (!process.env.LTI_CLIENT_ID) {
      throw httpError(503, 'LTI is not configured on this server');
    }
    const contextId = body.contextId || body['https://purl.imsglobal.org/spec/lti/claim/context']?.id;
    if (!contextId) throw httpError(400, 'LTI context id required');
    return {
      ok: true,
      contextId: String(contextId),
      message: 'LTI launch accepted (stub). Link classroom via teacher UI.',
      deepLink: `/teacher`,
    };
  },
};
