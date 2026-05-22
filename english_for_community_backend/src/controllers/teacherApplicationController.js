import { teacherApplicationService } from '../services/teacherApplicationService.js';

const getStatusCode = (err) => err.statusCode || 500;

export const createTeacherApplication = async (req, res) => {
  try {
    const doc = await teacherApplicationService.createApplication(req.user._id, req.body);
    return res.status(201).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const getMyTeacherApplication = async (req, res) => {
  try {
    const doc = await teacherApplicationService.getMyLatest(req.user._id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};

export const withdrawTeacherApplication = async (req, res) => {
  try {
    const doc = await teacherApplicationService.withdraw(req.user._id);
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(getStatusCode(error)).json({ message: error.message });
  }
};
