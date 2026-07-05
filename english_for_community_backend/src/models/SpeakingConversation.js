import mongoose from 'mongoose';

const { Schema, Types } = mongoose;

// A correction has a field literally named `type`. Declaring it inline as
// `{ type: String, ... }` makes Mongoose read `type: String` as the SchemaType
// descriptor (i.e. "this element is a String") and silently drop before/after/
// reason — so corrections would be stored as [String] and reject real objects
// with "Cast to [string] failed". An explicit sub-schema disambiguates it.
const SpeakingCorrectionSchema = new Schema({
  type: { type: String, default: '' },
  before: { type: String, default: '' },
  after: { type: String, default: '' },
  reason: { type: String, default: '' },
}, { _id: false });

const SpeakingFeedbackSchema = new Schema({
  overall: Number,
  cefr: String,
  summary: String,

  fc: Number,
  fcBullets: [String],
  fcNote: String,
  lr: Number,
  lrBullets: [String],
  lrNote: String,
  gra: Number,
  graBullets: [String],
  graNote: String,
  ia: Number,
  iaBullets: [String],
  iaNote: String,

  taskAchievement: Number,
  taskBullets: [String],
  taskNote: String,
  scenarioTitle: String,
  trends: {
    overall: Number,
    fc: Number,
    lr: Number,
    gra: Number,
    ia: Number,
  },

  strengths: [String],
  improvements: [{ issue: String, before: String, after: String, explain: String }],
  corrections: [SpeakingCorrectionSchema],
  vocabUpgrades: [{ said: String, better: String, note: String }],
  modelAnswers: [{ context: String, yourTurn: String, modelTurn: String }],
  nextSteps: [String],

  stats: {
    words: Number,
    durationSec: Number,
    wpm: Number,
    fillerCount: Number,
    questionCount: Number,
    turnCount: Number,
  },
  modelInfo: { provider: String, model: String },
  evaluatedAt: { type: Date, default: Date.now },
}, { _id: false });

const SpeakingConversationSchema = new Schema({
  userId: { type: Types.ObjectId, ref: 'User', index: true, required: true },
  mode: { type: String, default: 'freeSpeaking' },
  scenario: { type: String, default: null },
  scenarioId: { type: Types.ObjectId, ref: 'SpeakingScenario', default: null, index: true },
  scenarioSnapshot: {
    slug: String,
    title: String,
    group: String,
    levelSuggested: String,
    goals: [String],
  },
  level: { type: String, default: null },
  turns: [{
    role: { type: String, enum: ['user', 'ai'], required: true },
    text: { type: String, default: '' },
    ts: Number,
  }],
  wordCount: Number,
  durationSeconds: { type: Number, default: 0, min: 0 },
  status: { type: String, enum: ['evaluating', 'reviewed', 'failed'], default: 'evaluating', index: true },
  feedback: SpeakingFeedbackSchema,
  score: Number,
  startedAt: Date,
  endedAt: Date,
  errorMessage: String,
}, {
  timestamps: true,
  versionKey: false,
});

SpeakingConversationSchema.index({ userId: 1, createdAt: -1 });
SpeakingConversationSchema.index({ userId: 1, status: 1, createdAt: -1 });
SpeakingConversationSchema.index({ userId: 1, status: 1, scenarioId: 1, createdAt: -1 });

const SpeakingConversation = mongoose.model(
  'SpeakingConversation',
  SpeakingConversationSchema,
  'speakingconversations',
);

export default SpeakingConversation;
