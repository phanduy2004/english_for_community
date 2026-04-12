import * as reportService from '../services/reportService.js';

const createReport = async (req, res) => {
  try {
    await reportService.createReportFromRequest({
      userId: req.user._id,
      body: req.body,
      files: req.files,
    });
    res.status(201).json({ message: 'Cảm ơn bạn đã đóng góp ý kiến!' });
  } catch (error) {
    console.error('Create Report Error:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

const getReports = async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const result = await reportService.listReports({ page, limit, status });
    res.status(200).json(result);
  } catch (error) {
    console.error('Get Reports Error:', error);
    res.status(500).json({ message: 'Lỗi lấy danh sách báo cáo', error: error.message });
  }
};

const getReportDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await reportService.getReportById(id);

    if (!report) {
      return res.status(404).json({ message: 'Không tìm thấy báo cáo' });
    }

    res.status(200).json(report);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy chi tiết', error: error.message });
  }
};

const updateReportStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminResponse } = req.body;

    const result = await reportService.updateReportStatus(id, { status, adminResponse });
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }

    res.status(200).json({
      message: 'Cập nhật trạng thái thành công',
      report: result.data,
    });
  } catch (error) {
    console.error('Update Status Error:', error);
    res.status(500).json({ message: 'Lỗi cập nhật', error: error.message });
  }
};

export default {
  createReport,
  getReports,
  getReportDetail,
  updateReportStatus,
};
