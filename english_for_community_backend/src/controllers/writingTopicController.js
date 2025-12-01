// src/controllers/writingTopicController.js
import WritingSubmission from '../models/WritingSubmission.js';
import WritingTopic from "../models/WritingTopics.js";
import {updateGamificationStats} from "../services/gamificationService.js";
import {trackUserProgress} from "../untils/progressTracker.js";
export const getTopicSubmissions = async (req, res) => {
  try {
    const { id } = req.params; // topicId
    const { userId } = req;

    const submissions = await WritingSubmission.find({
      topicId: id,
      userId: userId,
      status: 'reviewed' // Chỉ lấy bài đã có kết quả
    })
      .select('score generatedPrompt createdAt wordCount durationInSeconds feedback content')
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json(submissions);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};
// GET /api/writing-topics
export const getWritingTopics = async (req, res) => {
  try {
    const { userId } = req; // Lấy userId từ token (middleware)

    // 1. Lấy danh sách Topic
    const topics = await WritingTopic.find({ isActive: true })
      .select('name slug icon color order stats aiConfig') // Vẫn lấy stats gốc (nếu muốn dùng làm backup)
      .sort({ order: 1, createdAt: -1 })
      .lean();

    // 2. Tính toán thống kê CỦA RIÊNG USER (User Personal Stats)
    // Query bảng Submission, lọc theo userId và status 'reviewed'
    const userStats = await WritingSubmission.aggregate([
      {
        $match: {
          userId: userId,
          status: 'reviewed' // Chỉ tính các bài đã chấm điểm
        }
      },
      {
        $group: {
          _id: '$topicId', // Gom nhóm theo Topic
          mySubmissionsCount: { $sum: 1 }, // Đếm số bài mình đã làm
          myAvgScore: { $avg: '$score' },  // Tính điểm trung bình của mình
          // myMaxScore: { $max: '$score' } // (Tuỳ chọn) Nếu muốn lấy điểm cao nhất
        }
      }
    ]);

    // 3. Tạo Map để tra cứu nhanh
    const userStatsMap = {};
    userStats.forEach(stat => {
      userStatsMap[stat._id.toString()] = stat;
    });

    // 4. Ghép dữ liệu User Stats vào danh sách Topic
    // Chúng ta sẽ GHI ĐÈ lên trường 'stats' để Frontend không cần sửa code
    const personalizedTopics = topics.map(topic => {
      const myStat = userStatsMap[topic._id.toString()];

      return {
        ...topic,
        stats: {

          submissionsCount: myStat ? myStat.mySubmissionsCount : 0,
          avgScore: myStat ? myStat.myAvgScore : null, // null để Frontend ẩn số điểm đi nếu chưa làm
        }
      };
    });

    return res.status(200).json(personalizedTopics);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// POST /api/writing/:id/start
export const startWritingForTopic = async (req, res) => {
  try {
    const { id } = req.params;

    // ⬇️ SỬA Ở ĐÂY ⬇️
    // const { userId, generatedPrompt } = req.body; // <-- Dòng CŨ (SAI)
    const { generatedPrompt } = req.body;       // <-- Dòng MỚI (ĐÚNG)
    const { userId } = req; // <-- Dòng MỚI (ĐÚNG) - Lấy từ token
    // ⬆️ KẾT THÚC SỬA ⬆️

    if (!userId) return res.status(401).json({ message: 'User not authenticated' }); // ⬅️ Thêm kiểm tra

    const topic = await WritingTopic.findById(id).lean();
    if (!topic || !topic.isActive) return res.status(404).json({ message: 'Topic not found' });

    // ... (Phần còn lại của hàm giữ nguyên) ...
    // Resume draft
    const existing = await WritingSubmission.findOne({
      userId, topicId: topic._id, status: 'draft'
    }).sort({ updatedAt: -1 }).lean();
    if (existing) {
      return res.status(200).json({
        submissionId: existing._id,
        generatedPrompt: existing.generatedPrompt,
        resumed: true,
      });
    }

    // ...
    const sub = await WritingSubmission.create({
      userId, // ⬅️ userId này giờ đã an toàn
      topicId: topic._id,
      generatedPrompt: {
        title: generatedPrompt.title,
        text: generatedPrompt.text,
        taskType: generatedPrompt.taskType,
        level: generatedPrompt.level,
      },
      status: 'draft',
    });
    // ...
    return res.status(200).json({
      submissionId: sub._id,
      generatedPrompt: sub.generatedPrompt,
      resumed: false,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};
// PATCH /api/writing-submissions/:id/draft
export const updateDraft = async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const { userId } = req; // Giả sử 'authenticate' middleware đã gán userId

    const submission = await WritingSubmission.findOneAndUpdate(
      { _id: id, userId, status: 'draft' },
      {
        $set: {
          content,
          wordCount: content.trim().split(/\s+/).length,
        }
      },
      { new: true }
    ).lean();

    if (!submission) {
      return res.status(404).json({ message: 'Draft not found or already submitted' });
    }

    return res.status(200).json({ message: 'Draft updated', wordCount: submission.wordCount });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// POST /api/writing-submissions/:id/submit
export const submitForReview = async (req, res) => {
  try {
    const { id } = req.params;
    // ⬇️ LẤY THÊM durationInSeconds TỪ BODY
    const { content, feedback, durationInSeconds } = req.body;
    const { userId } = req;

    if (!feedback || !feedback.overall) {
      return res.status(400).json({ message: 'Feedback object is required' });
    }

    // ⬇️ GIÁ TRỊ durationInSeconds SẼ ĐƯỢC GỬI TỪ BLOC
    if (durationInSeconds == null || durationInSeconds < 0) {
      return res.status(400).json({ message: 'durationInSeconds is required' });
    }

    const submission = await WritingSubmission.findOneAndUpdate(
      { _id: id, userId, status: 'draft' },
      {
        $set: {
          content,
          wordCount: content.trim().split(/\s+/).length,
          feedback, // Lưu toàn bộ object feedback
          score: feedback.overall, // Lưu điểm tổng để query nhanh
          durationInSeconds: durationInSeconds, // <-- ĐÃ THÊM
          status: 'reviewed',
          submittedAt: new Date(),
          reviewedAt: feedback.evaluatedAt || new Date(),
        }
      },
      { new: true }
    ).lean();

    if (!submission) {
      return res.status(404).json({ message: 'Submission not found or already submitted' });
    }
    const activityData = {
      durationInSeconds: durationInSeconds
    };
    // Chạy ngầm, không cần await
    updateGamificationStats(userId, 'writing', activityData);
    // [Optional] Cập nhật stats cho Topic (denormalize)
    // Chạy bất đồng bộ để không block response
    updateTopicStats(submission.topicId);
    trackUserProgress(userId, 'writing', {
      duration: durationInSeconds,
      score: feedback.overall,
      isLessonJustFinished: true // 👈 Luôn true khi nộp bài
    });
    return res.status(200).json(submission);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Helper function để cập nhật stats (chạy ngầm)
const updateTopicStats = async (topicId) => {
  try {
    const stats = await WritingSubmission.aggregate([
      { $match: { topicId, status: 'reviewed', score: { $ne: null } } },
      {
        $group: {
          _id: '$topicId',
          submissionsCount: { $sum: 1 },                                                                  
          avgScore: { $avg: '$score' }
        }
      }
    ]);

    if (stats.length > 0) {
      await WritingTopic.findByIdAndUpdate(topicId, {
        $set: {
          'stats.submissionsCount': stats[0].submissionsCount,
          'stats.avgScore': stats[0].avgScore,
        }
      });
    }
  } catch (error) {
    console.error('Failed to update topic stats:', error);
  }
};
