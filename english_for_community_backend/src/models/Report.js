import mongoose from 'mongoose';

const reportSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Ai gửi

  type: {
    type: String,
    enum: ['bug', 'feature', 'improvement', 'other'],
    required: true
  }, // Loại báo cáo

  title: { type: String, required: true },
  description: { type: String, required: true },

  // URL ảnh đính kèm (nếu bạn muốn cho user gửi ảnh màn hình lỗi)
  images: [{ type: String }],

  // Thông tin thiết bị (Rất quan trọng khi fix bug)
  deviceInfo: {
    platform: String, // iOS/Android
    version: String,  // 14.0, 11.0...
    device: String    // iPhone 12, Samsung S21...
  },

  status: {
    type: String,
    enum: ['pending', 'reviewed', 'resolved', 'rejected'],
    default: 'pending'
  },
  adminResponse: {
    type: String,
  },

  createdAt: { type: Date, default: Date.now }
});

const Report = mongoose.model('Report', reportSchema);
export default Report;