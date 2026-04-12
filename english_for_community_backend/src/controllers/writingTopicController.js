import * as writingTopicService from '../services/writingTopicService.js';

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
    const { taskType } = req.body;
    const { userId } = req;

    const result = await writingTopicService.startWritingForTopic(userId, id, taskType);
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
    return res.status(200).json(topic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const createWritingTopic = async (req, res) => {
  try {
    const { name, aiConfig, isActive } = req.body;
    const newTopic = await writingTopicService.createWritingTopic({ name, aiConfig, isActive });
    return res.status(201).json(newTopic);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const updateWritingTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const updatedTopic = await writingTopicService.updateWritingTopicById(id, updateData);
    if (!updatedTopic) return res.status(404).json({ message: 'Topic not found' });
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
    return res.status(200).json({ message: 'Topic deleted successfully' });
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
