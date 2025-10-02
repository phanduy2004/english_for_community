// src/controllers/listening.controller.js
import mongoose from 'mongoose';
import Listening from '../models/Listening.js';

const basePopulate = [
  {
    path: 'lessonId',
    select: '_id name description order type content imageUrl isActive createdAt updatedAt unitId',
    populate: {
      path: 'unitId',
      select: '_id name description order imageUrl isActive createdAt updatedAt trackId',
      populate: {
        path: 'trackId',
        select: '_id name description level imageUrl order isActive createdAt updatedAt'
      }
    }
  }
];

/**
 * GET /api/listenings/:id
 * Lấy 1 listening theo _id (populate lesson/unit/track). Ẩn transcript.
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

    const find = {};
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

    return res.status(200).json({ items: docs });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const listeningController = {
  getListeningById,
  listListenings,
};
