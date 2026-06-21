import mongoose from 'mongoose';

/**
 * Sub-schema scores/integrity — strict:false để không reject document cũ (Mixed legacy).
 * JSON serialize giữ nguyên key (totalAwarded, skillScores object/map, finalScore, …).
 */
export const examScoresSubSchema = new mongoose.Schema(
  {
    totalAwarded: Number,
    totalMax: Number,
    items: mongoose.Schema.Types.Mixed,
    skillScores: mongoose.Schema.Types.Mixed,
    examFormat: String,
    grammarScore: mongoose.Schema.Types.Mixed,
    finalScore: Number,
    finalMax: Number,
    finalStatus: String,
  },
  { _id: false, strict: false }
);

export const examIntegritySubSchema = new mongoose.Schema(
  {
    tabSwitchCount: Number,
    focusLossSeconds: Number,
    copyPasteAttempts: Number,
    fullscreenExited: Boolean,
    lastEventAt: String,
    riskLevel: { type: String, enum: ['low', 'medium', 'high'] },
  },
  { _id: false, strict: false }
);
