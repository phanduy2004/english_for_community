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

// POST /api/writing-topics/:id/start
// Body: { userId, generatedPrompt }  // FE PHẢI gửi kèm
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
