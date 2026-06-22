import WritingSubmission from '../models/WritingSubmission.js';
import WritingTopic from '../models/WritingTopics.js';
import { updateGamificationStats } from './gamificationService.js';
import { trackUserProgress } from '../utils/progressTracker.js';
import { aiService } from './aiService.js';
import WritingTopicVersion from '../models/WritingTopicVersion.js';

async function updateTopicStats(topicId) {
  try {
    const stats = await WritingSubmission.aggregate([
      { $match: { topicId, status: 'reviewed', score: { $ne: null } } },
      {
        $group: {
          _id: '$topicId',
          submissionsCount: { $sum: 1 },
          avgScore: { $avg: '$score' },
        },
      },
    ]);

    if (stats.length > 0) {
      await WritingTopic.findByIdAndUpdate(topicId, {
        $set: {
          'stats.submissionsCount': stats[0].submissionsCount,
          'stats.avgScore': stats[0].avgScore,
        },
      });
    }
  } catch (error) {
    console.error('Failed to update topic stats:', error);
  }
}

export async function getTopicSubmissions(userId, topicId) {
  return WritingSubmission.find({
    topicId,
    userId,
    status: 'reviewed',
  })
    .select('score generatedPrompt createdAt wordCount durationInSeconds feedback content')
    .sort({ createdAt: -1 })
    .lean();
}

export async function getWritingTopicsForUser(userId) {
  const topics = await WritingTopic.find({ isActive: true,  })
    .select('name slug icon color order stats aiConfig')
    .sort({ order: 1, createdAt: -1 })
    .lean();

  const userStats = await WritingSubmission.aggregate([
    { $match: { userId, status: 'reviewed' } },
    {
      $group: {
        _id: '$topicId',
        mySubmissionsCount: { $sum: 1 },
        myAvgScore: { $avg: '$score' },
      },
    },
  ]);

  const userStatsMap = {};
  userStats.forEach((stat) => {
    userStatsMap[stat._id.toString()] = stat;
  });

  return topics.map((topic) => {
    const myStat = userStatsMap[topic._id.toString()];
    return {
      ...topic,
      stats: {
        submissionsCount: myStat ? myStat.mySubmissionsCount : 0,
        avgScore: myStat ? myStat.myAvgScore : null,
      },
    };
  });
}

export async function startWritingForTopic(userId, topicId, taskType, opts = {}) {
  if (!userId) return { error: { status: 401, message: 'User not authenticated' } };

  const topic = await WritingTopic.findById(topicId).lean();
  if (!topic || !topic.isActive) return { error: { status: 404, message: 'Topic not found' } };

  const freshStart = opts.freshStart === true;

  const existing = freshStart
    ? null
    : await WritingSubmission.findOne({
        userId,
        topicId: topic._id,
        status: 'draft',
      }).sort({ updatedAt: -1 });

  if (existing) {
    if (existing.content && existing.content.trim().length > 0) {
      return {
        data: {
          submissionId: existing._id,
          generatedPrompt: existing.generatedPrompt,
          content: existing.content,
          resumed: true,
        },
      };
    }
    await WritingSubmission.deleteOne({ _id: existing._id });
  }

  let aiPromptData;
  if (opts.fixedPrompt && opts.fixedPrompt.text) {
    // Use teacher-assigned fixed prompt — all students get the same question
    aiPromptData = {
      title: opts.fixedPrompt.title || topic.name,
      text: opts.fixedPrompt.text,
      taskType: opts.fixedPrompt.taskType || taskType || 'Essay',
      level: opts.fixedPrompt.level || topic.aiConfig?.level || 'Intermediate',
    };
  } else {
    try {
      aiPromptData = await aiService.generateWritingPrompt(
        topic.name,
        topic.aiConfig,
        taskType || 'Essay',
      );
    } catch (aiError) {
      console.error('Error generating prompt:', aiError);
      aiPromptData = {
        title: topic.name,
        text: `Write about ${topic.name}. Task Type: ${taskType}`,
        taskType,
        level: topic.aiConfig?.level || 'Intermediate',
      };
    }
  }

  const sub = await WritingSubmission.create({
    userId,
    topicId: topic._id,
    generatedPrompt: aiPromptData,
    status: 'draft',
    content: '',
  });

  return {
    data: {
      submissionId: sub._id,
      generatedPrompt: sub.generatedPrompt,
      content: '',
      resumed: false,
    },
  };
}

export async function updateDraft(userId, submissionId, content) {
  const submission = await WritingSubmission.findOneAndUpdate(
    { _id: submissionId, userId, status: 'draft' },
    {
      $set: {
        content,
        wordCount: content ? content.trim().split(/\s+/).length : 0,
        updatedAt: new Date(),
      },
    },
    { new: true },
  ).lean();

  if (!submission) {
    return { error: { status: 404, message: 'Draft not found or already submitted' } };
  }

  return {
    data: {
      message: 'Draft saved successfully',
      wordCount: submission.wordCount,
      updatedAt: submission.updatedAt,
    },
  };
}

export async function submitForReview(userId, submissionId, content, durationInSeconds) {
  if (durationInSeconds == null || durationInSeconds < 0) {
    return { error: { status: 400, message: 'durationInSeconds is required' } };
  }

  const submissionCheck = await WritingSubmission.findOne({ _id: submissionId, userId });
  if (!submissionCheck) {
    return { error: { status: 404, message: 'Submission not found' } };
  }

  let feedbackData;
  try {
    const taskType = submissionCheck.generatedPrompt?.taskType || 'Essay';
    feedbackData = await aiService.generateFeedback(content, taskType);
    feedbackData.evaluatedAt = new Date();
  } catch (aiError) {
    return { error: { status: 500, message: 'AI Grading failed', detail: aiError.message } };
  }

  const submission = await WritingSubmission.findOneAndUpdate(
    { _id: submissionId, userId, status: 'draft' },
    {
      $set: {
        content,
        wordCount: content.trim().split(/\s+/).length,
        feedback: feedbackData,
        score: feedbackData.overall,
        durationInSeconds,
        status: 'reviewed',
        submittedAt: new Date(),
        reviewedAt: new Date(),
      },
    },
    { new: true },
  ).lean();

  if (!submission) {
    return { error: { status: 404, message: 'Submission not found or already submitted' } };
  }

  const activityData = { durationInSeconds };
  updateGamificationStats(userId, 'writing', activityData);
  await updateTopicStats(submission.topicId);
  trackUserProgress(userId, 'writing', {
    duration: durationInSeconds,
    score: feedbackData.overall,
    isLessonJustFinished: true,
  });

  return { data: submission };
}

export async function getAdminWritingTopics() {
  const topics = await WritingTopic.aggregate([
    {
      $lookup: {
        from: 'writingsubmissions',
        let: { topicId: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: { $eq: ['$topicId', '$$topicId'] },
              status: 'reviewed',
            },
          },
          { $project: { score: 1 } },
        ],
        as: 'submissionData',
      },
    },
    {
      $addFields: {
        stats: {
          submissionsCount: { $size: '$submissionData' },
          avgScore: {
            $cond: {
              if: { $gt: [{ $size: '$submissionData' }, 0] },
              then: { $round: [{ $avg: '$submissionData.score' }, 1] },
              else: null,
            },
          },
        },
      },
    },
    { $unset: 'submissionData' },
    { $sort: { order: 1, createdAt: -1 } },
  ]);

  return topics.map((topic) => ({
    ...topic,
    id: topic._id.toString(),
  }));
}

export async function getWritingTopicById(id) {
  return WritingTopic.findById(id).lean();
}

export async function createWritingTopic({ name, aiConfig, isActive }) {
  const count = await WritingTopic.countDocuments();
  return WritingTopic.create({
    name,
    isActive: isActive !== undefined ? isActive : true,
    approvalStatus: 'draft',
    aiConfig,
    order: count + 1,
    stats: { submissionsCount: 0, avgScore: null },
  });
}

export async function updateWritingTopicById(id, updateData, changedBy, changeReason = '') {
  const current = await WritingTopic.findById(id).lean();
  if (!current) return null;

  await WritingTopicVersion.create({
    topicId: current._id,
    snapshot: current,
    changedBy,
    changeReason,
  });

  return WritingTopic.findByIdAndUpdate(id, updateData, { new: true });
}

export async function deleteWritingTopicById(id) {
  return WritingTopic.findByIdAndUpdate(id, { isActive: false }, { new: true });
}

export async function submitWritingTopicForApproval(id, submittedBy) {
  return WritingTopic.findByIdAndUpdate(
    id,
    {
      $set: {
        approvalStatus: 'pending_review',
        'approval.submittedBy': submittedBy,
        'approval.submittedAt': new Date(),
      },
    },
    { new: true }
  );
}

export async function reviewWritingTopicApproval(id, { decision, reviewNote }, reviewedBy) {
  const allowed = ['approved', 'rejected', 'published'];
  if (!allowed.includes(decision)) return null;
  return WritingTopic.findByIdAndUpdate(
    id,
    {
      $set: {
        approvalStatus: decision,
        'approval.reviewedBy': reviewedBy,
        'approval.reviewedAt': new Date(),
        'approval.reviewNote': reviewNote || '',
      },
    },
    { new: true }
  );
}

export async function listDeletedWritingTopics(page = 1, limit = 20) {
  const p = Math.max(1, parseInt(page, 10) || 1);
  const l = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const [data, total] = await Promise.all([
    WritingTopic.find({ isActive: false })
      .sort({ updatedAt: -1 })
      .skip((p - 1) * l)
      .limit(l)
      .lean(),
    WritingTopic.countDocuments({ isActive: false }),
  ]);
  return {
    data,
    pagination: { page: p, limit: l, total, totalPages: Math.ceil(total / l) },
  };
}

export async function restoreWritingTopicById(id) {
  return WritingTopic.findByIdAndUpdate(
    id,
    {
      $set: {
        isActive: true,
        approvalStatus: 'draft',
      },
    },
    { new: true }
  );
}

export async function deleteSubmissionForUser(userId, submissionId) {
  const deleted = await WritingSubmission.findOneAndDelete({
    _id: submissionId,
    userId,
  });

  if (!deleted) {
    return { error: { status: 404, message: 'Submission not found or not authorized' } };
  }

  if (deleted.status === 'reviewed') {
    await updateTopicStats(deleted.topicId);
  }

  return { data: { message: 'Submission deleted successfully' } };
}

export async function listWritingTopicVersions(topicId, page = 1, limit = 20) {
  const p = Math.max(1, parseInt(page, 10) || 1);
  const l = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const [data, total] = await Promise.all([
    WritingTopicVersion.find({ topicId })
      .populate('changedBy', 'fullName email role')
      .sort({ createdAt: -1 })
      .skip((p - 1) * l)
      .limit(l)
      .lean(),
    WritingTopicVersion.countDocuments({ topicId }),
  ]);
  return {
    data,
    pagination: {
      page: p,
      limit: l,
      total,
      totalPages: Math.ceil(total / l),
    },
  };
}

export async function rollbackWritingTopicVersion(topicId, versionId, changedBy) {
  const version = await WritingTopicVersion.findOne({ _id: versionId, topicId }).lean();
  if (!version) return null;
  const current = await WritingTopic.findById(topicId).lean();
  if (!current) return null;

  await WritingTopicVersion.create({
    topicId: current._id,
    snapshot: current,
    changedBy,
    changeReason: `Rollback from version ${versionId}`,
  });

  const snapshot = version.snapshot || {};
  const safeRestore = {
    name: snapshot.name,
    isActive: snapshot.isActive,
    aiConfig: snapshot.aiConfig,
    stats: snapshot.stats,
    order: snapshot.order,
  };
  return WritingTopic.findByIdAndUpdate(topicId, safeRestore, { new: true });
}
