import mongoose from 'mongoose';
const { Schema, model, Types } = mongoose;

// 1️⃣ Sub-Schema cho Cue (Tương tự Question trong Reading)
const CueSubSchema = new Schema({
  _id: { type: Types.ObjectId, auto: true }, // Tự tạo ID để frontend dễ key
  startMs: { type: Number, required: true },
  endMs:   { type: Number, required: true },
  spk:     { type: String },                 // 'A', 'B'...
  text:    { type: String, required: true }, // Đáp án gốc
  textNorm:{ type: String }                  // Đáp án chuẩn hóa để chấm điểm
}, { _id: false }); // _id: false ở option nhưng define bên trong để control type

// 2️⃣ Main Schema cho Listening
const ListeningSchema = new Schema(
  {
    code:       { type: String, unique: true, index: true }, // vd: 'p1_wakeup'
    title:      { type: String, required: true },

    // Audio & Config
    audioUrl:   { type: String, required: true },
    playbackPad:{
      before: { type: Number, default: 200 },
      after:  { type: Number, default: 200 }
    },

    // Metadata
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    tags:       [{ type: String }],
    transcript: { type: String }, // Script gộp (nếu cần hiển thị full)

    // 3️⃣ Nhúng mảng Cues vào đây (thay vì table riêng)
    cues: [CueSubSchema]
  },
  { timestamps: true }
);

// Virtual field: Tính tổng số cue tự động
ListeningSchema.virtual('totalCues').get(function() {
  return this.cues ? this.cues.length : 0;
});

const Listening = model('Listening', ListeningSchema);
export default Listening;