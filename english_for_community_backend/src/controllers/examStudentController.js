import { teacherExamAssignmentService } from '../services/teacherExamAssignmentService.js';
import { examAttemptService } from '../services/examAttemptService.js';
import { examSessionService } from '../services/examSessionService.js';
import { examIntegrityService } from '../services/examIntegrityService.js';
import { syncLiveViewForStudent } from '../services/examLiveMonitorService.js';

const getStatusCode = (err) => err.statusCode || 500;

export const listAvailableAssignments = async (req, res) => {
  try {
    const list = await teacherExamAssignmentService.listAvailableForStudent(req.user._id);
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const listAvailableAssignmentsForClassroom = async (req, res) => {
  try {
    const list = await teacherExamAssignmentService.listAvailableForStudentInClassroom(
      req.user._id,
      req.params.classroomId
    );
    return res.status(200).json(list);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const startExamAttempt = async (req, res) => {
  try {
    const doc = await examAttemptService.startAttempt(req.user._id, req.params.assignmentId);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const previewPublicExam = async (req, res) => {
  try {
    const doc = await teacherExamAssignmentService.previewPublicByToken(req.params.token);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const startPublicExamAttempt = async (req, res) => {
  try {
    const a = await teacherExamAssignmentService.findByPublicToken(req.params.token);
    if (!a) return res.status(404).json({ message: 'Link not found' });
    const doc = await examAttemptService.startAttempt(req.user._id, a._id.toString(), {
      publicToken: req.params.token,
    });
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const joinPublicExamSession = async (req, res) => {
  try {
    const doc = await examSessionService.joinPublicByToken(req.user._id, req.params.token);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const joinExamSession = async (req, res) => {
  try {
    const doc = await examSessionService.joinSession(req.user._id, req.params.sessionId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getMySessionAttempt = async (req, res) => {
  try {
    const doc = await examSessionService.getMyAttempt(req.user._id, req.params.sessionId);
    if (!doc) return res.status(404).json({ message: 'No attempt for this session yet' });
    if (doc.blocked === true) return res.status(200).json(doc);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const abandonRealtimeExamAttempt = async (req, res) => {
  try {
    const doc = await examSessionService.abandonStudentAttempt(req.user._id, req.params.attemptId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const patchExamAttempt = async (req, res) => {
  try {
    const doc = await examAttemptService.patchAnswers(req.user._id, req.params.attemptId, req.body.answers);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

/** Persists UI focus for teacher live mirror (JWT; does not rely on exam socket register). */
export const patchAttemptLiveView = async (req, res) => {
  try {
    const liveView = req.body?.liveView;
    await syncLiveViewForStudent(
      req.user._id,
      req.params.attemptId,
      liveView && typeof liveView === 'object' ? liveView : {}
    );
    return res.status(204).send();
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const submitExamAttempt = async (req, res) => {
  try {
    const doc = await examAttemptService.submit(req.user._id, req.params.attemptId, {
      force: req.body?.force === true,
    });
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getExamAttempt = async (req, res) => {
  try {
    const doc = await examAttemptService.getAttemptForStudent(req.user._id, req.params.attemptId);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const reportExamAttemptIntegrity = async (req, res) => {
  try {
    const doc = await examIntegrityService.reportForStudent(
      req.user._id,
      req.params.attemptId,
      req.body || {}
    );
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};
