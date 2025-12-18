import { listeningService } from '../services/listeningService.js';
import { trackUserProgress } from "../untils/progressTracker.js";
import mongoose from 'mongoose';
import {getIO} from "../socket/socketManager.js";
import CueComment from "../models/CueComment.js";
import Listening from "../models/Listening.js";
import {notificationService} from "../services/notificationService.js";

// ============================================================
// 🌍 PUBLIC API
// ============================================================

const getAllListenings = async (req, res) => {
  try {
    const userId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const { difficulty, q } = req.query; // ✅ Đã lấy difficulty

    // 🔥 SỬA: Đảm bảo chỉ truyền difficulty nếu nó có giá trị (Để tránh lỗi nếu FE gửi string rỗng)
    const filters = {
      difficulty: difficulty || undefined,
      q: q || undefined
    };

    const result = await listeningService.getAllListenings(
      userId, filters, page, limit // ✅ Đã truyền filters chứa difficulty
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
    let payload = { ...req.body }; // Copy req.body để tránh side-effect

    // 🔥 FIX LỖI Ở ĐÂY: Kiểm tra nếu cues là String thì parse ra JSON
    if (typeof payload.cues === 'string') {
      try {
        payload.cues = JSON.parse(payload.cues);
      } catch (e) {
        return res.status(400).json({ message: 'Invalid cues JSON format' });
      }
    }

    // Nếu có file audio mới upload lên thì cập nhật link (nếu bạn có xử lý file)
    // if (req.file) payload.audioUrl = req.file.path;

    const result = await listeningService.updateListening(id, payload);
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
// 🔥 1. Lấy danh sách comment của 1 Cue (Thêm mới)
const getCueComments = async (req, res) => {
  try {
    const { listeningId, cueId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    let comments = await CueComment.find({ listeningId, cueId })
      .sort({ createdAt: -1 }) // 🔥 Quan trọng: Lấy tin mới nhất trước
      .skip(skip)
      .limit(limit)
      .populate('userId', 'fullName avatarUrl');
    const totalCount = await CueComment.countDocuments({ listeningId, cueId });
    const hasMore = totalCount > skip + comments.length;
    res.status(200).json({
      data: comments,
      pagination: {
        page,
        limit,
        hasMore
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};
// 🔥 2. Post New Comment (Supports Reply)
const postCueComment = async (req, res) => {
  try {
    const { listeningId, cueId, content, parentId } = req.body;
    const userId = req.user.id;

    // 1. Create new comment
    const newComment = await CueComment.create({
      listeningId,
      cueId,
      userId,
      content,
      parentId: parentId || null
    });

    // 2. Handle Notification Logic
    if (parentId) {
      const parentComment = await CueComment.findById(parentId);

      if (parentComment) {
        const listening = await Listening.findById(listeningId);
        const lessonTitle = listening ? listening.title : 'the lesson';

        const participantComments = await CueComment.find({ parentId: parentId }).select('userId');
        const recipientSet = new Set();

        const rootUserId = parentComment.userId._id ? parentComment.userId._id.toString() : parentComment.userId.toString();
        recipientSet.add(rootUserId);

        participantComments.forEach(c => {
          const pid = c.userId._id ? c.userId._id.toString() : c.userId.toString();
          recipientSet.add(pid);
        });

        recipientSet.delete(userId);

        const notificationsPromises = Array.from(recipientSet).map(recipientId => {
          return notificationService.createNotification({
            recipientId: recipientId,
            senderId: userId,
            type: 'COMMENT_REPLY',
            title: 'New Reply',
            message: `replied to a discussion in "${lessonTitle}"`,
            data: {
              listeningId: listeningId,
              cueId: cueId, // 🔥 ĐÃ THÊM: Frontend cần cái này để mở đúng Cue
              commentId: newComment._id.toString()
            }
          });
        });

        await Promise.all(notificationsPromises);
      }
    }

    const populatedComment = await newComment.populate('userId', 'fullName avatarUrl');

    try {
      getIO().to(`listening_${listeningId}`).emit('new_comment', {
        cueId: cueId, // 🔥 QUAN TRỌNG: Thêm dòng này để Client biết comment thuộc câu nào
        comment: populatedComment,
        parentId: parentId
      });
    } catch (socketErr) {
      console.error("Socket emit error:", socketErr);
    }

    res.status(201).json(populatedComment);

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 🔥 2. REACT TO COMMENT
const reactToComment = async (req, res) => {
  try {
    const { commentId } = req.params;
    const { type } = req.body;
    const userId = req.user.id;

    const validEmotions = ['LIKE', 'LOVE', 'HAHA', 'WOW', 'SAD', 'ANGRY'];
    if (!validEmotions.includes(type)) {
      return res.status(400).json({ message: 'Invalid reaction type' });
    }

    const comment = await CueComment.findById(commentId);
    console.log("👉 DEBUG REACT COMMENT:", comment); // Xem log này trên server
    if (!comment) return res.status(404).json({ message: 'Comment not found' });

    const existingReactionIndex = comment.reactions.findIndex(
      (r) => r.userId.toString() === userId
    );

    let isNewReaction = false;

    if (existingReactionIndex > -1) {
      if (comment.reactions[existingReactionIndex].type === type) {
        comment.reactions.splice(existingReactionIndex, 1);
      } else {
        comment.reactions[existingReactionIndex].type = type;
      }
    } else {
      comment.reactions.push({ userId, type });
      isNewReaction = true;
    }

    await comment.save();

    if (isNewReaction) {
      const listening = await Listening.findById(comment.listeningId);
      const lessonTitle = listening ? listening.title : 'the lesson';

      const emotionIcons = { LIKE: '👍', LOVE: '❤️', HAHA: '😂', WOW: '😮', SAD: '😢', ANGRY: '😡' };
      const icon = emotionIcons[type] || 'reaction';

      const recipientIdStr = comment.userId._id ? comment.userId._id.toString() : comment.userId.toString();

      if (recipientIdStr !== userId) {
        await notificationService.createNotification({
          recipientId: recipientIdStr,
          senderId: userId,
          type: 'COMMENT_REACTION',
          title: 'New Reaction',
          message: `reacted ${icon} to your comment in "${lessonTitle}": "${comment.content.substring(0, 20)}..."`,
          data: {
            listeningId: comment.listeningId.toString(),
            cueId: comment.cueId ? comment.cueId.toString() : "", // 🔥 ĐÃ THÊM: Lấy cueId từ comment gốc
            commentId: comment._id.toString()
          }
        });
      }
    }

    try {
      getIO().to(`listening_${comment.listeningId}`).emit('comment_reaction_updated', {
        commentId: comment._id,
        cueId: comment.cueId, // 🟢 THÊM DÒNG NÀY: Để client biết reaction này thuộc câu nào
        reactions: comment.reactions
      });
    } catch (socketErr) {
      console.error("Socket emit error:", socketErr);
    }

    res.status(200).json({ message: 'Success', reactions: comment.reactions });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

export const listeningController = {
  getAllListenings,
  getListeningById,
  submitAttempt,
  getAttempts,
  createListening,
  adminUpdate,
  deleteListening,
  postCueComment,
  getCueComments,
  reactToComment
};