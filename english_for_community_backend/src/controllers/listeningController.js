// src/controllers/listening.controller.js
import mongoose from 'mongoose';
import Listening from '../models/Listening.js';
import {Enrollment} from "../models/index.js";

const basePopulate = [
  {
    path: 'lessonId',
    select: '_id name description order type content imageUrl isActive createdAt updatedAt',
  }
];

/**
 * GET /api/listenings/:id
 */
export const getListeningById = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(String(id))) {
      return res.status(400).json({ message: 'Invalid listening id' });
    }

    const doc = await Listening.findById(id, { transcript: 0 })
    .populate(basePopulate)
    .lean();

    if (!doc) return res.status(404).json({ message: 'Listening not found' });
    return res.status(200).json(doc);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

/**
 * GET /api/listenings
 * Lấy danh sách listening (populate). Hỗ trợ filter qua query:
 * - lessonId (optional): chỉ lấy listening thuộc lesson này
 * - q (optional): tìm theo title/code (regex i)
 * - level (optional): beginner|intermediate|advanced -> map difficulty
 */
export const listListenings = async (req, res) => {
  try {
    const { lessonId, q = '', level = '' } = req.query;
    const userId = req.user?._id || null; // <-- 2. Lấy userId (nếu đã đăng nhập)

    const find = {};
    // ... (giữ nguyên logic find, keyword, difficulty)
    if (lessonId) {
      if (!mongoose.Types.ObjectId.isValid(String(lessonId))) {
        return res.status(400).json({ message: 'Invalid lessonId' });
      }
      find.lessonId = lessonId;
    }
    const keyword = String(q).trim();
    if (keyword) {
      find.$or = [
        { title: { $regex: keyword, $options: 'i' } },
        { code:  { $regex: keyword, $options: 'i' } },
      ];
    }
    const levelMap = { beginner: 'easy', intermediate: 'medium', advanced: 'hard' };
    const difficulty = levelMap[String(level).toLowerCase()];
    if (difficulty) find.difficulty = difficulty;

    const docs = await Listening.find(find, { transcript: 0 })
    .populate(basePopulate)
    .sort({ createdAt: -1, _id: -1 })
    .lean();

    // 3. Logic lấy và trộn tiến độ (progress)
    let docsWithProgress = docs;

    if (userId) {
      // Lấy tất cả enrollment của user này
      const enrollments = await Enrollment.find(
        { userId, listeningId: { $in: docs.map(d => d._id) } },
        { listeningId: 1, progress: 1, _id: 0 } // chỉ lấy các trường cần thiết
      ).lean();

      // Tạo map để tra cứu nhanh
      const progressMap = new Map();
      for (const enr of enrollments) {
        progressMap.set(enr.listeningId.toString(), enr.progress);
      }

      // Map 'docs' để thêm trường 'userProgress'
      docsWithProgress = docs.map(doc => {
        const progress = progressMap.get(doc._id.toString()) ?? 0.0;
        return {
          ...doc,
          userProgress: progress, // Thêm trường mới
        };
      });
    } else {
      // Nếu không đăng nhập, gán mặc định progress = 0
      docsWithProgress = docs.map(doc => ({ ...doc, userProgress: 0.0 }));
    }

    // 4. Trả về mảng đã được trộn tiến độ
    return res.status(200).json({ docs: docsWithProgress });

  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const listeningController = {
  getListeningById,
  listListenings,
};
