import { readingService } from '../services/readingService.js';
import {trackUserProgress} from "../untils/progressTracker.js";

const getReadingById = async (req, res) => {
  try {
    const { id } = req.params; // Lấy ID từ URL

    const reading = await readingService.getReadingById(id);

    if (!reading) {
      return res.status(404).json({ message: 'Không tìm thấy bài đọc này.' });
    }

    // Trả về cấu trúc có key 'data' để khớp với logic Flutter: response.data['data']
    res.status(200).json({ data: reading });

  } catch (err) {
    // Bắt lỗi nếu ID không đúng định dạng ObjectId của MongoDB
    if (err.name === 'CastError') {
      return res.status(400).json({ message: 'ID bài đọc không hợp lệ' });
    }
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};
const getAllReadings = async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const { difficulty } = req.query;

    const paginatedResults = await readingService.getAllReadings(
      userId,
      difficulty,
      page,
      limit
    );

    res.status(200).json(paginatedResults);

  } catch (err) {
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};

/**
 * 👇 Tạo bài đọc mới (Admin)
 */
const createReading = async (req, res) => {
  try {
    // Kiểm tra quyền Admin (nếu bạn có middleware checkRole thì tốt, tạm thời để qua)
    // const userRole = req.user.role;
    // if (userRole !== 'admin') return res.status(403).json({ message: 'Access denied' });

    const payload = req.body;

    // Gọi service tạo mới
    const newReading = await readingService.createReading(payload);

    res.status(201).json({
      message: 'Tạo bài đọc thành công!',
      data: newReading
    });
  } catch (err) {
    // Bắt lỗi validation của Mongoose
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ', error: err.message });
    }
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};

/**
 * Nộp kết quả bài đọc
 */
const submitAttempt = async (req, res) => {
  try {
    const userId = req.user.id;
    const payload = req.body;

    const result = await readingService.submitAttempt(userId, payload);
    let normalizedScore = 0;
    if (result.totalQuestions > 0) {
      normalizedScore = result.correctCount / result.totalQuestions;
    }

    trackUserProgress(userId, 'reading', {
      duration: result.durationInSeconds || payload.durationInSeconds || 0,
      score: normalizedScore,
      wpm: result.wpm || payload.wpm,
      isLessonJustFinished: result.isCompleted
    });
    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};

/**
 * Lấy lịch sử làm bài
 */
const getAttemptHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { readingId } = req.params;

    const history = await readingService.getAttemptHistory(userId, readingId);
    res.status(200).json(history);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};
const deleteReading = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await readingService.deleteReading(id);

    if (!result) {
      return res.status(404).json({ message: 'Không tìm thấy bài đọc để xóa' });
    }

    res.status(200).json({ message: 'Xóa thành công', id: id });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi máy chủ: ' + err.message });
  }
};
// ✍️ Export
export const readingController = {
  getAllReadings,
  createReading, // 👈 Export hàm mới
  submitAttempt,
  getAttemptHistory,
  getReadingById,
  deleteReading
};