import { listeningCompService } from '../services/listeningCompService.js';
import { trackUserProgress } from "../untils/progressTracker.js";
import mongoose from 'mongoose';

const getAllListenings = async (req, res) => {
  try {
    const userId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const { difficulty, q } = req.query;

    const filters = {
      difficulty: difficulty || undefined,
      q: q || undefined
    };

    const result = await listeningCompService.getAllListenings(userId, filters, page, limit);
    res.status(200).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

const getListeningById = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid ID' });

    const listening = await listeningCompService.getListeningById(id);
    if (!listening) return res.status(404).json({ message: 'Not found' });

    res.status(200).json({ data: listening });
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

const submitAttempt = async (req, res) => {
  try {
    const userId = req.user.id;
    const payload = req.body;

    // Gọi service
    const result = await listeningCompService.submitAttempt(userId, payload);

    // 🔥 GỌI HÀM TRACKING VÀO BẢNG TIẾN ĐỘ HÀNG NGÀY
    // Dùng type 'dictation' để nó ăn vào biến lessonsCompleted.listening trong progressTracker
    let normalizedScore = result.attempt.score / 100; // Đưa về hệ số 0-1 nếu tracker của bạn đang dùng 0-1

    await trackUserProgress(userId, 'dictation', {
      duration: payload.durationInSeconds || 0,
      score: normalizedScore,
      isLessonJustFinished: result.isLessonJustFinished
    });

    // Trả về dữ liệu cho app Flutter
    res.status(201).json({ data: result.attempt });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

const getAttempts = async (req, res) => {
  try {
    const userId = req.user.id;
    const listeningId = req.query.listeningId;

    if (!listeningId) return res.status(400).json({ message: 'listeningId required' });

    const attempts = await listeningCompService.getAttempts(userId, listeningId);
    res.status(200).json({ data: attempts });
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

    // Lấy URL từ Cloudinary nếu có file upload
    if (req.file && req.file.path) {
      payload.audioUrl = req.file.path;
    }

    // Parse chuỗi JSON thành object/array (dùng cho FormData)
    if (typeof payload.questions === 'string') {
      try {
        payload.questions = JSON.parse(payload.questions);
      } catch (e) {
        payload.questions = [];
      }
    }

    const result = await listeningCompService.createListening(payload);
    res.status(201).json({ message: 'Created successfully', data: result });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const adminUpdate = async (req, res) => {
  try {
    const { id } = req.params;
    let payload = { ...req.body };

    if (typeof payload.questions === 'string') {
      try {
        payload.questions = JSON.parse(payload.questions);
      } catch (e) {
        return res.status(400).json({ message: 'Invalid questions JSON format' });
      }
    }

    if (req.file && req.file.path) {
      payload.audioUrl = req.file.path;
    }

    const result = await listeningCompService.updateListening(id, payload);
    res.status(200).json({ message: 'Update success', data: result });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const deleteListening = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await listeningCompService.deleteListening(id);
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.status(200).json({ message: 'Deleted successfully', id });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getDeletedListenings = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const result = await listeningCompService.getDeletedListenings(page, limit);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const restoreListening = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await listeningCompService.restoreListening(id);
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.status(200).json({ message: 'Restored successfully', data: result });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const listeningCompController = {
  getAllListenings, getListeningById, submitAttempt, getAttempts,
  createListening, adminUpdate, deleteListening,
  getDeletedListenings, restoreListening,
};