// src/models/WritingTopic.js
import mongoose from 'mongoose';

const TASK_TYPES = [
  'Opinion',
  'Discussion',
  'Advantages-Disadvantages',
  'Problem-Solution',
  'Discuss both views and give your own opinion',
  'Two-part question',
];

const WritingTopicSchema = new mongoose.Schema(
  {
    name:     { type: String, required: true },                  // "Art", "Technology", ...
    isActive: { type: Boolean, default: true },
    // cấu hình để GEN đề khi user bấm vào topic
    aiConfig: {
      language:        { type: String, default: 'vi-VN' },
      taskTypes:       [{ type: String, enum: TASK_TYPES }], // ['Discussion','Opinion',...]
      defaultTaskType: { type: String, enum: TASK_TYPES, default: 'Discussion' },
      level:           { type: String, default: 'Intermediate' },
      targetWordCount: { type: String, default: '250–320' },
      generationTemplate: { type: String }, // prompt khung riêng cho topic (optional)
    },

    // thống kê nhẹ để hiển thị list (denormalized)
    stats: {
      submissionsCount: { type: Number, default: 0 },
      avgScore:         { type: Number, min: 0, max: 9, default: null },
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// sắp xếp theo order trước, rồi createdAt
WritingTopicSchema.index({ isActive: 1, order: 1, createdAt: -1 });

// Model name nên ở dạng số ít: 'WritingTopic', collection cố định: 'writing_topics'
const WritingTopic = mongoose.model('WritingTopic', WritingTopicSchema, 'writing_topics');
export default WritingTopic;
