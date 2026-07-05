import mongoose from 'mongoose';

const { Schema } = mongoose;

const SpeakingScenarioSchema = new Schema({
  slug: { type: String, required: true, unique: true, trim: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  group: {
    type: String,
    enum: ['daily', 'travel', 'work', 'study', 'service', 'ielts'],
    default: 'daily',
    index: true,
  },
  levelSuggested: {
    type: String,
    enum: ['Beginner', 'Intermediate', 'Advanced'],
    default: 'Beginner',
    index: true,
  },
  goals: [{ type: String, trim: true }],
  roleForAI: { type: String, required: true },
  firstMessage: { type: String, required: true },
  successCriteria: [{ type: String, trim: true }],
  starterHints: [{ type: String, trim: true }],
  sortOrder: { type: Number, default: 0, index: true },
  isActive: { type: Boolean, default: true, index: true },
  _destroy: { type: Boolean, default: false, index: true },
}, {
  timestamps: true,
  versionKey: false,
});

SpeakingScenarioSchema.index({ isActive: 1, group: 1, levelSuggested: 1, sortOrder: 1 });

const SpeakingScenario = mongoose.model(
  'SpeakingScenario',
  SpeakingScenarioSchema,
  'speakingscenarios',
);

export default SpeakingScenario;
