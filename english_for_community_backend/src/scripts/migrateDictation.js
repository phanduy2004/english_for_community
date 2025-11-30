import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config(); // Load biến môi trường

// 1. Định nghĩa Schema (Copy từ file model của bạn)
const DictationAttemptSchema = new mongoose.Schema({
  // ... Paste toàn bộ nội dung schema vào đây ...
  // Hoặc import từ file model nếu có thể
}, { timestamps: true, strict: false }); // strict: false để lấy hết mọi trường

// 2. Tạo 2 Model trỏ vào 2 bảng khác nhau
const OldModel = mongoose.model('OldDictation', DictationAttemptSchema, 'dictationattemptschemas');
const NewModel = mongoose.model('NewDictation', DictationAttemptSchema, 'dictationattempts');

const migrate = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/english_community');
    console.log("🔌 Connected to MongoDB");

    // Lấy toàn bộ dữ liệu cũ
    const oldDocs = await OldModel.find().lean();
    console.log(`📦 Tìm thấy ${oldDocs.length} bản ghi cũ.`);

    if (oldDocs.length === 0) {
      console.log("Không có gì để chuyển.");
      return;
    }

    // Chuyển đổi dữ liệu (nếu cần)
    const newDocs = oldDocs.map(doc => {
      // Xóa _id nếu bạn muốn tạo ID mới, hoặc giữ nguyên để khớp data
      // const { _id, ...rest } = doc;
      // return rest;

      return doc; // Giữ nguyên toàn bộ
    });

    // Ghi vào bảng mới
    // ordered: false để nếu 1 dòng lỗi thì các dòng khác vẫn chạy tiếp
    await NewModel.insertMany(newDocs, { ordered: false });

    console.log("✅ Đã chuyển dữ liệu thành công sang 'dictationattempts'!");

  } catch (error) {
    console.error("❌ Lỗi migration:", error);
  } finally {
    await mongoose.disconnect();
  }
};

migrate();