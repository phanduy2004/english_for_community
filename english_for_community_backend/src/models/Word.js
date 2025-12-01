import mongoose from 'mongoose';

const UserWordSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  headword: { type: String, required: true },
  ipa: { type: String, default: null },
  shortDefinition: { type: String, default: null },
  pos: { type: String, default: null },
  status: {
    type: String,
    enum: ['recent','learning', 'saved'],
    required: true,
    default: 'recent'
  },
  learningLevel: { type: Number, default: 0 },
  nextReviewDate: { type: Date, default: Date.now },
  lastReviewedDate: { type: Date, default: Date.now },
  lastRemindedDate: { type: Date, default: null },
}, { timestamps: true });
UserWordSchema.index({ user: 1, headword: 1 }, { unique: true });
UserWordSchema.index({ user: 1, status: 1 });
UserWordSchema.index({ user: 1, updatedAt: -1 });


const Word = mongoose.model('Word', UserWordSchema);
export default Word;