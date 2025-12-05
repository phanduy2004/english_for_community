import { listeningService } from '../services/listeningService.js';
import { trackUserProgress } from "../untils/progressTracker.js";
import mongoose from 'mongoose';

// ============================================================
// 🌍 PUBLIC API
// ============================================================

const getAllListenings = async (req, res) => {
  try {
    const userId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const { difficulty, q } = req.query;

    const result = await listeningService.getAllListenings(
      userId, { difficulty, q }, page, limit
    );
    res.status(200).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

const getListeningById = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });

    const listening = await listeningService.getListeningById(id);
    if (!listening) return res.status(404).json({ message: 'Not found' });

    res.status(200).json({ data: listening });
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

// 🟢 Nộp bài (Thay thế dictationController.submitDictation)
const submitAttempt = async (req, res) => {
  try {
    const userId = req.user.id;
    const payload = req.body;

    const result = await listeningService.submitAttempt(userId, payload);

    // Tracking analytics
    let normalizedScore = 0;
    if (result.totalCues > 0) {
      normalizedScore = result.correctCount / result.totalCues;
    }
    trackUserProgress(userId, 'dictation', {
      duration: payload.durationInSeconds || 0,
      score: normalizedScore,
      isLessonJustFinished: result.isCompleted
    });

    res.status(201).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

// 🟢 Lấy lịch sử (Thay thế dictationController.getDictationAttempts)
const getAttempts = async (req, res) => {
  try {
    const userId = req.user.id;
    const listeningId = req.query.listeningId;
    const latest = String(req.query.latest || 'true') === 'true';

    if (!listeningId) return res.status(400).json({ message: 'listeningId required' });

    const attempts = await listeningService.getAttempts(userId, listeningId, latest);
    res.status(200).json(attempts);
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

// ============================================================
// 🔐 ADMIN API
// ============================================================

const createListening = async (req, res) => {
  try {
    const payload = req.body;

    // 2. Nếu có file Audio upload lên -> Lấy URL từ Cloudinary
    if (req.file && req.file.path) {
      payload.audioUrl = req.file.path;
    }

    // 3. Parse cues nếu gửi dạng JSON string (do FormData)
    if (typeof payload.cues === 'string') {
      try {
        payload.cues = JSON.parse(payload.cues);
      } catch (e) {
        payload.cues = [];
      }
    }
    const result = await listeningService.createListening(payload);
    res.status(201).json({ message: 'Created successfully', data: result });
  } catch (error) {
    if (error.code === 11000) return res.status(400).json({ message: 'Duplicate Code' });
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const adminUpdate = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await listeningService.updateListening(id, req.body);
    res.status(200).json({ message: 'Update success', data: result });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const deleteListening = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await listeningService.deleteListening(id);
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.status(200).json({ message: 'Deleted successfully', id });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const listeningController = {
  getAllListenings,
  getListeningById,
  submitAttempt,
  getAttempts,
  createListening,
  adminUpdate,
  deleteListening
};