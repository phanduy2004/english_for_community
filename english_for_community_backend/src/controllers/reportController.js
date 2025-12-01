import Report from '../models/Report.js';

// POST /api/reports
const createReport = async (req, res) => {
  try {
    const { type, title, description, targetId, targetModel } = req.body;
    const userId = req.user.userId; // Lấy từ middleware authenticate

    const newReport = new Report({
      userId,
      type,
      title,
      description,
      targetId, // Ví dụ: ID của bài Reading bị lỗi
      targetModel // Ví dụ: 'ReadingPassage'
    });

    await newReport.save();

    res.status(201).json({
      message: 'Report submitted successfully',
      report: newReport
    });
  } catch (error) {
    res.status(500).json({ message: 'Error submitting report', error: error.message });
  }
};

export default {
  createReport
};