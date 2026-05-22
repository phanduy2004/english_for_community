import * as writingTopicService from '../services/writingTopicService.js';
import { writeAdminAudit } from '../services/adminAuditService.js';

export const getTopicSubmissions = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req;
    const submissions = await writingTopicService.getTopicSubmissions(userId, id);
    return res.status(200).json(submissions);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getWritingTopics = async (req, res) => {
  try {
    const { userId } = req;
    const personalizedTopics = await writingTopicService.getWritingTopicsForUser(userId);
    return res.status(200).json(personalizedTopics);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const startWritingForTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const { taskType, freshStart, fixedPrompt } = req.body;
    const { userId } = req;

    const result = await writingTopicService.startWritingForTopic(userId, id, taskType, {
      freshStart: freshStart === true,
      fixedPrompt: fixedPrompt || null,
    });
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const updateDraft = async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const { userId } = req;

    const result = await writingTopicService.updateDraft(userId, id, content);
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const submitForReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { content, durationInSeconds } = req.body;
    const { userId } = req;

    const result = await writingTopicService.submitForReview(
      userId,
      id,
      content,
      durationInSeconds,
    );
    if (result.error) {
      const { status, message, detail } = result.error;
      const body = detail ? { message, error: detail } : { message };
      return res.status(status).json(body);
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getAdminWritingTopics = async (req, res) => {
  try {
    const topics = await writingTopicService.getAdminWritingTopics();
    return res.status(200).json(topics);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getWritingTopicDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const topic = await writingTopicService.getWritingTopicById(id);
    if (!topic) return res.status(404).json({ message: 'Topic not found' });

    // Students only see active topics; admin/teacher may load drafts for CMS/exams.
    const role = req.user?.role;
    if (role === 'user' && topic.isActive === false) {
      return res.status(404).json({ message: 'Topic not found' });
    }

    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const createWritingTopic = async (req, res) => {
  try {
    const { name, aiConfig, isActive } = req.body;
    const newTopic = await writingTopicService.createWritingTopic({ name, aiConfig, isActive });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.create',
      targetType: 'writing_topic',
      targetId: newTopic?._id?.toString() || 'unknown',
      metadata: { name },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
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
    const updatedTopic = await writingTopicService.updateWritingTopicById(
      id,
      updateData,
      req.user?._id,
      req.body?.changeReason || '',
    );
    if (!updatedTopic) return res.status(404).json({ message: 'Topic not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.update',
      targetType: 'writing_topic',
      targetId: id,
      metadata: { keys: Object.keys(updateData || {}) },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json(updatedTopic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteWritingTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const deletedTopic = await writingTopicService.deleteWritingTopicById(id);
    if (!deletedTopic) return res.status(404).json({ message: 'Topic not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.soft_delete',
      targetType: 'writing_topic',
      targetId: id,
      metadata: {},
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json({ message: 'Topic archived successfully' });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getWritingTopicVersions = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const data = await writingTopicService.listWritingTopicVersions(id, page, limit);
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const rollbackWritingTopicVersion = async (req, res) => {
  try {
    const { id, versionId } = req.params;
    const topic = await writingTopicService.rollbackWritingTopicVersion(id, versionId, req.user?._id);
    if (!topic) return res.status(404).json({ message: 'Topic/version not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.rollback',
      targetType: 'writing_topic',
      targetId: id,
      metadata: { versionId },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const submitWritingTopicApproval = async (req, res) => {
  try {
    const { id } = req.params;
    const topic = await writingTopicService.submitWritingTopicForApproval(id, req.user?._id);
    if (!topic) return res.status(404).json({ message: 'Topic not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.submit_approval',
      targetType: 'writing_topic',
      targetId: id,
      metadata: {},
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const reviewWritingTopicApproval = async (req, res) => {
  try {
    const { id } = req.params;
    const { decision, reviewNote } = req.body;
    const topic = await writingTopicService.reviewWritingTopicApproval(
      id,
      { decision, reviewNote },
      req.user?._id,
    );
    if (!topic) return res.status(400).json({ message: 'Invalid decision or topic not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.review_approval',
      targetType: 'writing_topic',
      targetId: id,
      metadata: { decision, reviewNote },
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getDeletedWritingTopics = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const data = await writingTopicService.listDeletedWritingTopics(page, limit);
    return res.status(200).json(data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const restoreWritingTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const topic = await writingTopicService.restoreWritingTopicById(id);
    if (!topic) return res.status(404).json({ message: 'Topic not found' });
    await writeAdminAudit({
      actorId: req.user?._id,
      actorRole: req.user?.role,
      action: 'writing_topic.restore',
      targetType: 'writing_topic',
      targetId: id,
      metadata: {},
      ip: req.ip,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const deleteSubmission = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req;

    const result = await writingTopicService.deleteSubmissionForUser(userId, id);
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};
