import { speakingService } from "../services/speakingService.js";
import {trackUserProgress} from "../utils/progressTracker.js";
import mongoose from "mongoose";
const sanitizeSentences = (sentences) => {
  if (!Array.isArray(sentences)) return [];
  return sentences.map(s => ({
    ...s,
    // Nếu không có id hoặc id là chuỗi rỗng, tạo ObjectId mới
    id: (s.id && s.id.trim() !== "") ? s.id : new mongoose.Types.ObjectId().toString()
  }));
};
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
    // --- BỔ SUNG ĐOẠN NÀY ---
    if (req.body.sentences) {
      req.body.sentences = sanitizeSentences(req.body.sentences);
    }
    // ------------------------

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

    // --- BỔ SUNG ĐOẠN NÀY ---
    if (req.body.sentences) {
      req.body.sentences = sanitizeSentences(req.body.sentences);
    }
    // ------------------------

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

const adminGetDeleted = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const result = await speakingService.getDeletedSpeakingSets(page, limit);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const adminRestore = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });
    const result = await speakingService.restoreSpeakingSet(id);
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.status(200).json({ message: 'Restored', data: result });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Đọc .env an toàn: trim + bỏ BOM; tránh giá trị rỗng do khoảng trắng sau dấu "=" trong .env
const _envTrim = (key) => {
  const raw = process.env[key];
  if (raw == null) return '';
  return String(raw).replace(/^\uFEFF/, '').trim();
};

// Cấu hình Vapi cho app Free Speaking — key giữ trên server, không hardcode trong Flutter release.
const getVapiConfig = async (req, res) => {
  try {
    const publicKey = _envTrim('VAPI_PUBLIC_KEY');
    const assistantId = _envTrim('VAPI_ASSISTANT_ID');
    if (!publicKey || !assistantId) {
      return res.status(503).json({
        message: 'Voice chat is not configured. Set VAPI_PUBLIC_KEY and VAPI_ASSISTANT_ID on the server.',
      });
    }
    res.status(200).json({ publicKey, assistantId });
  } catch (error) {
    console.error('getVapiConfig:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const evaluateConversation = async (req, res) => {
  try {
    const conversation = await speakingService.evaluateConversation(req.user.id, req.body);
    res.status(201).json({ conversation });
  } catch (error) {
    if (error.code === 'TOO_SHORT') {
      return res.status(422).json({
        code: 'TOO_SHORT',
        message: error.message,
        details: error.details,
      });
    }
    if (error.code === 'AI_FAILED') {
      return res.status(502).json({
        code: 'AI_FAILED',
        message: error.message,
        conversation: error.conversation,
      });
    }
    console.error('Error evaluating speaking conversation:', error);
    res.status(error.statusCode || 500).json({ message: error.message || 'Internal server error' });
  }
};

const getConversationHistory = async (req, res) => {
  try {
    const result = await speakingService.getConversationHistory(req.user.id, req.query);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching speaking conversation history:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getConversationById = async (req, res) => {
  try {
    const conversation = await speakingService.getConversationById(req.user.id, req.params.id);
    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }
    res.status(200).json({ conversation });
  } catch (error) {
    console.error('Error fetching speaking conversation:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getScenarios = async (req, res) => {
  try {
    const result = await speakingService.getScenarios(req.query);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching speaking scenarios:', error);
    res.status(error.statusCode || 500).json({
      message: error.message || 'Internal server error',
      details: error.details,
    });
  }
};

const getProgressSummary = async (req, res) => {
  try {
    const result = await speakingService.getProgressSummary(req.user.id, req.query);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching speaking progress summary:', error);
    res.status(error.statusCode || 500).json({
      message: error.message || 'Internal server error',
      details: error.details,
    });
  }
};

const getNotebook = async (req, res) => {
  try {
    const result = await speakingService.getNotebook(req.user.id, req.query);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching speaking notebook:', error);
    res.status(error.statusCode || 500).json({
      message: error.message || 'Internal server error',
      details: error.details,
    });
  }
};

export const speakingController = {
  getSpeakingSetsWithProgress,
  getSpeakingSetDetails,
  submitAttempt,
  getVapiConfig,
  evaluateConversation,
  getConversationHistory,
  getConversationById,
  getScenarios,
  getProgressSummary,
  getNotebook,
  admin: {
    getList: adminGetList,
    getDetail: adminGetDetail,
    create: adminCreate,
    update: adminUpdate,
    delete: adminDelete,
    getDeleted: adminGetDeleted,
    restore: adminRestore,
  }
};
