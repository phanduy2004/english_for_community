import { speakingService } from "../services/speakingService.js";
import {trackUserProgress} from "../untils/progressTracker.js";
import mongoose from "mongoose";

const getSpeakingSetsWithProgress = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      mode,       // 'Read-aloud', 'Shadowing', v.v.
      level,      // 'Beginner', 'Intermediate', 'Advanced'
      page = 1,
      limit = 10
    } = req.query;
    if (!mode) {
      return res.status(400).json({ message: 'Mode is required' });
    }
    if (!level) {
      return res.status(400).json({ message: 'Level is required' });
    }
    const options = {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    };
    const filters = {
      mode: mode,
      level: level,
    };
    const result = await speakingService.getSetsWithProgress(userId, filters, options);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching speaking sets:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
const getSpeakingSetDetails = async (req, res) => {
  try {
    const { setId } = req.params;
    const userId = req.user.id;
    const speakingSet = await speakingService.getSetById(setId, userId);
    if (!speakingSet) {
      return res.status(404).json({ message: 'Speaking set not found' });
    }
    res.status(200).json(speakingSet);
  } catch (error) {
    console.error('Error fetching speaking set details:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
const submitAttempt = async (req, res) => {
  try {
    const userId = req.user.id;
    const data = req.body;
    // Gọi service
    const result = await speakingService.submitAttempt(userId, data);

    // Nếu service trả về object { attempt, isLessonComplete } thì sửa lại:
    const newAttempt = result.attempt || result;
    const isLessonJustFinished = result.isLessonComplete || false; // Lấy cờ từ kết quả service
    const accuracy = newAttempt.score && newAttempt.score.wer != null
      ? Math.max(0, 1 - newAttempt.score.wer)
      : 0;

    trackUserProgress(userId, 'speaking', {
      duration: newAttempt.audioDurationSeconds || data.audioDurationSeconds,
      score: accuracy, // 👈 Khớp với migration (0.0 - 1.0)
      isLessonJustFinished: isLessonJustFinished
    });
    res.status(201).json(newAttempt); // 201 Created
  } catch (error) {
    console.error('Error submitting speaking attempt:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
const adminGetList = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const { level } = req.query;

    const result = await speakingService.getAdminList(page, limit, level);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const adminGetDetail = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });

    const data = await speakingService.getAdminDetail(id);
    if (!data) return res.status(404).json({ message: 'Not found' });

    res.status(200).json({ data }); // Bọc trong data
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const adminCreate = async (req, res) => {
  try {
    const result = await speakingService.createSpeakingSet(req.body);
    res.status(201).json({ message: 'Created', data: result });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const adminUpdate = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });

    const result = await speakingService.updateSpeakingSet(id, req.body);
    if (!result) return res.status(404).json({ message: 'Not found' });

    res.status(200).json({ message: 'Updated', data: result });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const adminDelete = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });

    await speakingService.deleteSpeakingSet(id);
    res.status(200).json({ message: 'Deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
export const speakingController = {
  getSpeakingSetsWithProgress,
  getSpeakingSetDetails,
  submitAttempt,
  admin: {
    getList: adminGetList,
    getDetail: adminGetDetail,
    create: adminCreate,
    update: adminUpdate,
    delete: adminDelete
  }
};