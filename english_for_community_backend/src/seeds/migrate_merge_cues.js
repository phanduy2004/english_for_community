import mongoose from 'mongoose';
import dotenv from 'dotenv';

// Config env nếu bạn dùng file .env, hoặc điền trực tiếp string connection bên dưới
dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/english_community';

// ============================================================
// 1. ĐỊNH NGHĨA MODEL TẠM THỜI (Để script hiểu cấu trúc)
// ============================================================

// Schema cũ của Cue (để đọc dữ liệu)
const OldCueSchema = new mongoose.Schema({
  listeningId: { type: mongoose.Schema.Types.ObjectId, required: true },
  idx: Number,
  startMs: Number,
  endMs: Number,
  spk: String,
  text: String,
  textNorm: String
});
const OldCue = mongoose.model('Cue', OldCueSchema);

// Schema mới của Listening (để update dữ liệu)
const NewListeningSchema = new mongoose.Schema({
  code: { type: String },
  title: String,
  audioUrl: String,
  lessonId: { type: mongoose.Schema.Types.ObjectId }, // Khai báo để tí nữa xóa nó
  // Cấu trúc cues nhúng
  cues: [{
    _id: { type: mongoose.Schema.Types.ObjectId, auto: true },
    startMs: Number,
    endMs: Number,
    spk: String,
    text: String,
    textNorm: String
  }]
}, { strict: false }); // strict: false để cho phép xóa field lessonId

const Listening = mongoose.model('Listening', NewListeningSchema);

// ============================================================
// 2. HÀM MIGRATE
// ============================================================

const runMigration = async () => {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected.');

    // 1. Lấy tất cả bài nghe
    const listenings = await Listening.find({});
    console.log(`📊 Found ${listenings.length} listening documents.`);

    let count = 0;

    for (const doc of listenings) {
      // 2. Tìm các Cues cũ thuộc về bài nghe này
      // Sort theo idx để đảm bảo thứ tự đúng khi push vào mảng
      const oldCues = await OldCue.find({ listeningId: doc._id }).sort({ idx: 1 });

      // 3. Map dữ liệu từ Cue cũ sang cấu trúc mới (SubSchema)
      const newCues = oldCues.map(c => ({
        _id: c._id, // Giữ nguyên ID cũ của Cue (tốt cho việc tracking sau này)
        startMs: c.startMs,
        endMs: c.endMs,
        spk: c.spk,
        text: c.text,
        textNorm: c.textNorm
      }));

      // 4. Update Document Listening
      // Gán mảng cues mới
      doc.cues = newCues;

      // Xóa field lessonId (Set undefined để Mongoose xóa field này)
      doc.lessonId = undefined;
      doc.set('lessonId', undefined, { strict: false });

      // Tạo code nếu chưa có (Vì schema mới yêu cầu unique code)
      if (!doc.code) {
        // Tạo code từ title viết liền không dấu hoặc dùng ID
        const slug = doc.title
          ? doc.title.toLowerCase().replace(/[^a-z0-9]/g, '_')
          : 'lesson';
        doc.code = `${slug}_${doc._id.toString().slice(-4)}`;
      }

      // Lưu lại
      await doc.save();
      count++;

      // Log tiến độ
      if (count % 10 === 0) {
        console.log(`🔄 Processed ${count}/${listenings.length} docs...`);
      }
    }

    console.log('🎉 Migration Completed Successfully!');
    console.log(`✅ Updated ${count} listening documents with embedded cues.`);
    console.log('⚠️  Please verify data before dropping the old "cues" collection.');

  } catch (error) {
    console.error('❌ Migration Failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Disconnected.');
  }
};

// Chạy script
runMigration();