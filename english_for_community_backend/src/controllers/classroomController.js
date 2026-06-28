import { classroomService } from '../services/classroomService.js';
import { classroomActivityService } from '../services/classroomActivityService.js';
import { ltiGoogleClassroomService } from '../services/ltiGoogleClassroomService.js';

const getStatusCode = (err) => err.statusCode || 500;

export const createClassroom = async (req, res) => {
  try {
    const doc = await classroomService.createClassroom(req.user._id, req.body);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listMyClassroomsAsTeacher = async (req, res) => {
  try {
    const list = await classroomService.listMineAsTeacher(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listMyEnrolledClassrooms = async (req, res) => {
  try {
    const list = await classroomService.listEnrolledStudent(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getClassroom = async (req, res) => {
  try {
    const detail = await classroomService.getClassroomWithStats(req.params.id, req.user._id);
    return res.status(200).json(detail);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const updateClassroom = async (req, res) => {
  try {
    const doc = await classroomService.updateClassroom(req.user._id, req.params.id, req.body);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const archiveClassroom = async (req, res) => {
  try {
    const doc = await classroomService.archive(req.user._id, req.params.id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const rotateClassroomInvite = async (req, res) => {
  try {
    const doc = await classroomService.rotateInvite(req.user._id, req.params.id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listClassroomMembers = async (req, res) => {
  try {
    const list = await classroomService.listMembers(req.user._id, req.params.id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const approveClassroomMember = async (req, res) => {
  try {
    const doc = await classroomService.approveMember(req.user._id, req.params.id, req.params.userId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const rejectClassroomMember = async (req, res) => {
  try {
    const doc = await classroomService.rejectMember(req.user._id, req.params.id, req.params.userId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const removeClassroomMember = async (req, res) => {
  try {
    const doc = await classroomService.removeMember(req.user._id, req.params.id, req.params.userId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const leaveClassroom = async (req, res) => {
  try {
    const doc = await classroomService.leaveClassroom(req.user._id, req.params.id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const ltiLaunchStub = async (req, res) => {
  try {
    const doc = await ltiGoogleClassroomService.ltiLaunchStub(req.body || {});
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const joinClassroomByCode = async (req, res) => {
  try {
    const result = await classroomService.joinByCode(req.user._id, req.body.inviteCode);
    return res.status(200).json(result);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listClassroomActivity = async (req, res) => {
  try {
    const list = await classroomActivityService.listForClassroom(req.user._id, req.params.id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const searchTeachersForCoTeacher = async (req, res) => {
  try {
    const list = await classroomService.searchTeachersForCoTeacher(req.user._id, {
      q: req.query.q,
      limit: req.query.limit,
    });
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const addCoTeacher = async (req, res) => {
  try {
    const doc = await classroomService.addCoTeacher(req.user._id, req.params.id, req.body || {});
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const removeCoTeacher = async (req, res) => {
  try {
    const doc = await classroomService.removeCoTeacher(req.user._id, req.params.id, req.params.userId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getIntegrationsStatus = async (req, res) => {
  try {
    return res.status(200).json(ltiGoogleClassroomService.getStatus());
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const linkGoogleClassroom = async (req, res) => {
  try {
    const doc = await ltiGoogleClassroomService.linkGoogleCourse(req.user._id, req.params.id, req.body || {});
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const unlinkGoogleClassroom = async (req, res) => {
  try {
    const doc = await ltiGoogleClassroomService.unlinkGoogleCourse(req.user._id, req.params.id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const joinClassroomByToken = async (req, res) => {
  try {
    const result = await classroomService.joinByToken(req.user._id, req.body.token);
    return res.status(200).json(result);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};
