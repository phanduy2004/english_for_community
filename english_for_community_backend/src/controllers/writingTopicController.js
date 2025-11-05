// src/controllers/writingTopicController.js
import WritingSubmission from '../models/WritingSubmission.js';
import WritingTopic from "../models/WritingTopics.js";

// GET /api/writing-topics
export const getWritingTopics = async (req, res) => {
  try {
    const topics = await WritingTopic.find({ isActive: true })
    .select('name slug icon color order stats aiConfig')
    .sort({ order: 1, createdAt: -1 })
    .lean();
    return res.status(200).json(topics);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// POST /api/writing/:id/start
export const startWritingForTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, generatedPrompt } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId is required' });

    const topic = await WritingTopic.findById(id).lean();
    if (!topic || !topic.isActive) return res.status(404).json({ message: 'Topic not found' });

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

    // BẮT BUỘC FE gửi generatedPrompt
    if (!generatedPrompt || !generatedPrompt.title || !generatedPrompt.text) {
      return res.status(400).json({ message: 'generatedPrompt { title, text } is required from FE' });
    }

    const sub = await WritingSubmission.create({
      userId,
      topicId: topic._id,
      generatedPrompt: {
        title: generatedPrompt.title,
        text: generatedPrompt.text,
        taskType: generatedPrompt.taskType,
        level: generatedPrompt.level,
      },
      status: 'draft',
    });

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
    // FE gửi lên feedback đã parse từ Gemini
    const { content, feedback } = req.body;
    const { userId } = req;

    if (!feedback || !feedback.overall) {
      return res.status(400).json({ message: 'Feedback object is required' });
    }

    const submission = await WritingSubmission.findOneAndUpdate(
      { _id: id, userId, status: 'draft' },
      {
        $set: {
          content,
          wordCount: content.trim().split(/\s+/).length,
          feedback, // Lưu toàn bộ object feedback
          score: feedback.overall, // Lưu điểm tổng để query nhanh
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

    // [Optional] Cập nhật stats cho Topic (denormalize)
    // Chạy bất đồng bộ để không block response
    updateTopicStats(submission.topicId);

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
