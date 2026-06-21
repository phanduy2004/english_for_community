// models/CueComment.js
import mongoose from 'mongoose';
import { toJsonIdPlugin } from '../lib/mongoosePlugins.js';

const cueCommentSchema = new mongoose.Schema({
  listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', required: true },
  cueId: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true },
  parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'CueComment', default: null },

  // 🔥 THAY ĐỔI: Chuyển từ likedBy sang reactions
  // type: Loại cảm xúc (LIKE, LOVE, HAHA, WOW, SAD, ANGRY)
  reactions: [
    {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      type: {
        type: String,
        enum: ['LIKE', 'LOVE', 'HAHA', 'WOW', 'SAD', 'ANGRY'],
        required: true
      }
    }
  ],

  createdAt: { type: Date, default: Date.now }
});

cueCommentSchema.index({ listeningId: 1, cueId: 1, createdAt: -1 });
cueCommentSchema.index({ parentId: 1, createdAt: 1 });

toJsonIdPlugin(cueCommentSchema);

// Populate user info
cueCommentSchema.pre(/^find/, function(next) {
  this.populate('userId', 'fullName avatarUrl');
  next();
});

const CueComment = mongoose.model('CueComment', cueCommentSchema);
export default CueComment;