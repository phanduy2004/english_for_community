import Report from '../models/Report.js';

// --- API CLIENT (User gửi) ---

// 1. Tạo Report (Code cũ của bạn, giữ nguyên)
const createReport = async (req, res) => {
  try {
    let { type, title, description, deviceInfo } = req.body;

    if (deviceInfo && typeof deviceInfo === 'string') {
      try {
        deviceInfo = JSON.parse(deviceInfo);
      } catch (e) {
        deviceInfo = {};
      }
    }

    const images = req.files ? req.files.map(file => file.path) : [];

    const newReport = new Report({
      user: req.user._id,
      type,
      title,
      description,
      deviceInfo,
      images
    });

    await newReport.save();
    res.status(201).json({ message: 'Cảm ơn bạn đã đóng góp ý kiến!' });
  } catch (error) {
    console.error("Create Report Error:", error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

// --- API ADMIN (Quản lý) ---

// 2. Lấy danh sách Report (Có lọc status + Phân trang)
const getReports = async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;

    // Tạo bộ lọc
    const filter = {};

    // Nếu client gửi status lên thì lọc theo status (pending, reviewed, resolved, rejected)
    if (status && status !== 'all') {
      filter.status = status;
    }

    // Query DB
    const reports = await Report.find(filter)
      .populate('user', 'fullName email avatarUrl') // 🔥 Populate để lấy tên & avatar user hiện lên Card
      .sort({ createdAt: -1 }) // Mới nhất lên đầu
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    // Đếm tổng số để tính totalPages
    const total = await Report.countDocuments(filter);

    res.status(200).json({
      data: reports,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error("Get Reports Error:", error);
    res.status(500).json({ message: 'Lỗi lấy danh sách báo cáo', error: error.message });
  }
};

// 3. Lấy chi tiết 1 Report
const getReportDetail = async (req, res) => {
  try {
    const { id } = req.params;

    const report = await Report.findById(id)
      .populate('user', 'fullName email avatarUrl phone role'); // Lấy chi tiết user để contact nếu cần

    if (!report) {
      return res.status(404).json({ message: 'Không tìm thấy báo cáo' });
    }

    res.status(200).json(report);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy chi tiết', error: error.message });
  }
};

// 4. Cập nhật trạng thái Report (Admin xử lý)
const updateReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminResponse } = req.body;

    // Validate status hợp lệ
    const validStatuses = ['pending', 'reviewed', 'resolved', 'rejected'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Trạng thái không hợp lệ' });
    }

    // Update
    const updatedReport = await Report.findByIdAndUpdate(
      id,
      {
        status,
        adminResponse, // Admin có thể ghi chú thêm (VD: "Đã fix trong v1.2")
        // updatedAt: Date.now() // Nếu bạn muốn track thời gian update
      },
      { new: true } // Trả về object mới sau khi update
    ).populate('user', 'fullName email');

    if (!updatedReport) {
      return res.status(404).json({ message: 'Không tìm thấy báo cáo' });
    }

    // TODO: Ở đây có thể bắn Notification hoặc Socket cho User biết là "Admin đã trả lời"

    res.status(200).json({
      message: 'Cập nhật trạng thái thành công',
      report: updatedReport
    });

  } catch (error) {
    console.error("Update Status Error:", error);
    res.status(500).json({ message: 'Lỗi cập nhật', error: error.message });
  }
};

export default {
  createReport,
  getReports,
  getReportDetail,
  updateReportStatus
};