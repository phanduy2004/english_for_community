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
    const { userId } = req;

    // 1. Lấy danh sách Topic
    const topics = await WritingTopic.find({ isActive: true })
      .select('name slug icon color order stats aiConfig')
      .sort({ order: 1, createdAt: -1 })
      .lean();

    // 2. Tính toán thống kê CỦA RIÊNG USER
    const userStats = await WritingSubmission.aggregate([
      {
        $match: {
          userId: userId,
          status: 'reviewed'
        }
      },
      {
        $group: {
          _id: '$topicId',
          mySubmissionsCount: { $sum: 1 },
          myAvgScore: { $avg: '$score' },
        }
      }
    ]);

    // 3. Tạo Map để tra cứu nhanh
    const userStatsMap = {};
    userStats.forEach(stat => {
      userStatsMap[stat._id.toString()] = stat;
    });

    // 4. Ghép dữ liệu
    const personalizedTopics = topics.map(topic => {
      const myStat = userStatsMap[topic._id.toString()];
      return {
        ...topic,
        stats: {
          submissionsCount: myStat ? myStat.mySubmissionsCount : 0,
          avgScore: myStat ? myStat.myAvgScore : null,
        }
      };
    });

    return res.status(200).json(personalizedTopics);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const startWritingForTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const { generatedPrompt } = req.body;
    const { userId } = req;

    if (!userId) return res.status(401).json({ message: 'User not authenticated' });

    const topic = await WritingTopic.findById(id).lean();
    if (!topic || !topic.isActive) return res.status(404).json({ message: 'Topic not found' });

    // 1. Tìm bài draft cũ
    const existing = await WritingSubmission.findOne({
      userId, topicId: topic._id, status: 'draft'
    }).sort({ updatedAt: -1 }).lean();

    // 2. NẾU CÓ DRAFT -> TRẢ VỀ KÈM CONTENT
    if (existing) {
      return res.status(200).json({
        submissionId: existing._id,
        generatedPrompt: existing.generatedPrompt,
        // 👇 QUAN TRỌNG: Trả về nội dung cũ để client hiển thị
        content: existing.content || '',
        resumed: true,
      });
    }

    // 3. NẾU KHÔNG CÓ -> TẠO MỚI (Content rỗng)
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
      content: '', // Mới tinh thì content rỗng
    });

    return res.status(200).json({
      submissionId: sub._id,
      generatedPrompt: sub.generatedPrompt,
      content: '', // 👇 Trả về rỗng
      resumed: false,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// PATCH /api/writing-submissions/:id/draft
// 🟢 Đây chính là hàm lưu nội dung đang làm dở
export const updateDraft = async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const { userId } = req;

    // Chỉ update nếu bài đó đang là 'draft' và thuộc về user
    const submission = await WritingSubmission.findOneAndUpdate(
      { _id: id, userId, status: 'draft' },
      {
        $set: {
          content,
          wordCount: content ? content.trim().split(/\s+/).length : 0,
          updatedAt: new Date() // Cập nhật thời gian để sort resume sau này
        }
      },
      { new: true } // Trả về data mới
    ).lean();

    if (!submission) {
      // Có thể bài đã bị nộp rồi hoặc không tồn tại
      return res.status(404).json({ message: 'Draft not found or already submitted' });
    }

    return res.status(200).json({
      message: 'Draft saved successfully',
      wordCount: submission.wordCount,
      updatedAt: submission.updatedAt
    });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// POST /api/writing-submissions/:id/submit
export const submitForReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { content, feedback, durationInSeconds } = req.body;
    const { userId } = req;

    if (!feedback || !feedback.overall) {
      return res.status(400).json({ message: 'Feedback object is required' });
    }

    if (durationInSeconds == null || durationInSeconds < 0) {
      return res.status(400).json({ message: 'durationInSeconds is required' });
    }

    const submission = await WritingSubmission.findOneAndUpdate(
      { _id: id, userId, status: 'draft' },
      {
        $set: {
          content,
          wordCount: content.trim().split(/\s+/).length,
          feedback,
          score: feedback.overall,
          durationInSeconds: durationInSeconds,
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

    const activityData = { durationInSeconds: durationInSeconds };
    updateGamificationStats(userId, 'writing', activityData);
    updateTopicStats(submission.topicId);
    trackUserProgress(userId, 'writing', {
      duration: durationInSeconds,
      score: feedback.overall,
      isLessonJustFinished: true
    });

    return res.status(200).json(submission);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Helper function update stats
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

// --- CÁC API ADMIN ---

export const getAdminWritingTopics = async (req, res) => {
  try {
    const topics = await WritingTopic.aggregate([
      {
        $lookup: {
          from: 'writingsubmissions',
          let: { topicId: '$_id' },
          pipeline: [
            {
              $match: {
                $expr: { $eq: ['$topicId', '$$topicId'] },
                status: 'reviewed'
              }
            },
            { $project: { score: 1 } }
          ],
          as: 'submissionData'
        }
      },
      {
        $addFields: {
          stats: {
            submissionsCount: { $size: '$submissionData' },
            avgScore: {
              $cond: {
                if: { $gt: [{ $size: '$submissionData' }, 0] },
                then: { $round: [{ $avg: '$submissionData.score' }, 1] },
                else: null
              }
            }
          }
        }
      },
      { $unset: 'submissionData' },
      { $sort: { order: 1, createdAt: -1 } }
    ]);

    const formattedTopics = topics.map(topic => ({
      ...topic,
      id: topic._id.toString()
    }));

    return res.status(200).json(formattedTopics);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getWritingTopicDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const topic = await WritingTopic.findById(id).lean();
    if (!topic) return res.status(404).json({ message: 'Topic not found' });
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const createWritingTopic = async (req, res) => {
  try {
    const { name, aiConfig, isActive } = req.body;
    const count = await WritingTopic.countDocuments();
    const newTopic = await WritingTopic.create({
      name,
      isActive: isActive !== undefined ? isActive : true,
      aiConfig,
      order: count + 1,
      stats: { submissionsCount: 0, avgScore: null }
    });
    return res.status(201).json(newTopic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const updateWritingTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const updatedTopic = await WritingTopic.findByIdAndUpdate(
      id, updateData, { new: true }
    );
    if (!updatedTopic) return res.status(404).json({ message: 'Topic not found' });
    return res.status(200).json(updatedTopic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteWritingTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedTopic = await WritingTopic.findByIdAndDelete(id);
    if (!deletedTopic) return res.status(404).json({ message: 'Topic not found' });
    return res.status(200).json({ message: 'Topic deleted successfully' });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// 🔥 [MỚI] XÓA BÀI LÀM (DRAFT HOẶC SUBMITTED)
// DELETE /api/writing-submissions/:id
export const deleteSubmission = async (req, res) => {
  try {
    const { id } = req.params; // submissionId
    const { userId } = req;

    // Tìm và xóa submission của chính user đó
    const deleted = await WritingSubmission.findOneAndDelete({
      _id: id,
      userId: userId
    });

    if (!deleted) {
      return res.status(404).json({ message: 'Submission not found or not authorized' });
    }

    // [Optional] Nếu bài đã chấm (reviewed) bị xóa, có thể cần update lại Topic Stats
    // Nhưng thường chức năng này dùng cho việc xóa Draft để Start New nên ko ảnh hưởng stats nhiều.
    if (deleted.status === 'reviewed') {
      updateTopicStats(deleted.topicId);
    }

    return res.status(200).json({ message: 'Submission deleted successfully' });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};