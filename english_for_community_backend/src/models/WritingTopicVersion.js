import mongoose from 'mongoose';

const WritingTopicVersionSchema = new mongoose.Schema(
  {
    topicId: { type: mongoose.Schema.Types.ObjectId, ref: 'WritingTopic', required: true, index: true },
    snapshot: { type: mongoose.Schema.Types.Mixed, required: true },
    changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    changeReason: { type: String, default: '' },
  },
  { timestamps: true, versionKey: false }
);

const WritingTopicVersion = mongoose.model('WritingTopicVersion', WritingTopicVersionSchema, 'writing_topic_versions');
export default WritingTopicVersion;
