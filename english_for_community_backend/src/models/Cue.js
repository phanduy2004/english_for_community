// src/models/Cue.js

import mongoose from "mongoose";

const CueSchema = new mongoose.Schema(
  {
    listeningId: { type: mongoose.Schema.Types.ObjectId, ref: 'Listening', index: true, required: true },
    idx:         { type: Number, required: true },   // 0..N-1 (duy nhất trong 1 listening)
    startMs:     { type: Number, required: true },
    endMs:       { type: Number, required: true },
    spk:         { type: String },                   // 'A' | 'B' | 'Announcer'...
    text:        { type: String },                   // ground truth (KHÔNG gửi xuống client trước khi nộp)
    textNorm:    { type: String },                   // normalized để chấm
  },
  { timestamps: true }
);

// Đảm bảo (listeningId, idx) duy nhất
CueSchema.index({ listeningId: 1, idx: 1 }, { unique: true });
let Cue =  mongoose.model('Cue', CueSchema)
export default Cue;
