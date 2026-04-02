import { progressService } from '../services/progressService.js';

const getProgressSummary = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const userId = req.user.id;

    const result = await progressService.getSummaryData(userId, range);
    res.status(200).json(result);

  } catch (error) {
    console.error('Error in getProgressSummary controller:', error);
    res.status(500).json({ message: 'Lỗi server khi tải tóm tắt tiến trình.' });
  }
};

const getStatDetail = async (req, res) => {
  try {
    const { statKey, range = 'week' } = req.query;
    const userId = req.user.id;

    if (!statKey) {
      return res.status(400).json({ message: 'Thiếu statKey.' });
    }

    const result = await progressService.getStatDetailData(userId, statKey, range);
    res.status(200).json(result);

  } catch (error) {
    console.error('Error in getStatDetail controller:', error);
    // Xử lý lỗi từ Service (vd: 400 Invalid skill)
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    res.status(500).json({ message: 'Lỗi server khi tải chi tiết kỹ năng.' });
  }
};

const getLeaderboard = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await progressService.getLeaderboardData(userId);
    res.status(200).json(result);

  } catch (error) {
    console.error('Error in getLeaderboard controller:', error);
    res.status(500).json({ message: 'Lỗi server khi tải bảng xếp hạng.' });
  }
};

export const progressController = {
  getProgressSummary,
  getStatDetail,
  getLeaderboard
};