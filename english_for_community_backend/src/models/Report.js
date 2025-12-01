import mongoose from 'mongoose';

const reportSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Loại báo cáo
  type: {
    type: String,
    enum: ['content_error', 'system_bug', 'feature_request', 'other'],
    default: 'content_error'
  },
  // Tiêu đề ngắn (User nhập hoặc FE tự generate ví dụ: "Lỗi bài Reading #123")
  title: {
    type: String,
    required: true
  },
  // Nội dung chi tiết user mô tả
  description: {
    type: String,
    required: true
  },
  // Nếu báo lỗi nội dung cụ thể, lưu ID của đối tượng đó
  targetId: {
    type: mongoose.Schema.Types.ObjectId,
    required: false // Không bắt buộc vì nếu là 'system_bug' thì không có target cụ thể
  },
  // Tên Collection của đối tượng bị lỗi (để Admin biết mà query ngược lại)
  // Ví dụ: 'ReadingPassage', 'Vocabulary', 'SpeakingTopic'
  targetModel: {
    type: String,
    required: false
  },
  // Trạng thái xử lý của Admin
  status: {
    type: String,
    enum: ['new', 'in_progress', 'resolved', 'rejected'],
    default: 'new'
  },

  // Ghi chú của Admin (Ví dụ: "Đã sửa trong bản update v1.2")
  adminResponse: {
    type: String
  }
}, {
  timestamps: true // Tự động có createdAt, updatedAt
});

const Report = mongoose.model('Report', reportSchema);
export default Report;