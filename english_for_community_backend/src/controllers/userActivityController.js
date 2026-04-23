/**
 * Lịch sử bài tập cho user đang đăng nhập.
 * GET /api/users/me/activities
 * GET /api/users/me/activities/:activityId
 */
import historyService from '../services/historyService.js';

export const getMyActivities = async (req, res) => {
  try {
    const { startDate, endDate, type, page, limit, sort } = req.query;
    const userId = req.user._id;

    if (
      type &&
      !['writing', 'reading', 'speaking', 'listening'].includes(type)
    ) {
      return res.status(400).json({ message: 'Invalid type filter' });
    }

    const rangeErr = historyService.validateActivityDateRange(startDate, endDate);
    if (rangeErr.error) {
      return res.status(400).json({ message: rangeErr.error });
    }

    const result = await historyService.getHistoryPaginated(
      userId.toString(),
      startDate || undefined,
      endDate || undefined,
      type || undefined,
      { page, limit, sort },
    );

    const data = result.data.map(historyService.normalizeActivityListItem);

    return res.status(200).json({
      success: true,
      data,
      total: result.total,
      page: result.page,
      limit: result.limit,
      hasMore: result.hasMore,
    });
  } catch (error) {
    console.error('[getMyActivities]', error);
    return res.status(500).json({ message: error.message || 'Server error' });
  }
};

export const getMyActivityDetail = async (req, res) => {
  try {
    const { activityId } = req.params;
    const { type, subType } = req.query;
    const userId = req.user._id;

    if (!type) {
      return res.status(400).json({ message: "Missing 'type' query parameter" });
    }

    if (!['writing', 'reading', 'speaking', 'listening'].includes(type)) {
      return res.status(400).json({ message: 'Invalid type' });
    }

    const data = await historyService.getActivityDetailForUser(
      activityId,
      type,
      subType,
      userId.toString(),
    );

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('[getMyActivityDetail]', error);
    if (error.message === 'Activity not found') {
      return res.status(404).json({ message: error.message });
    }
    if (error.message === 'Forbidden') {
      return res.status(403).json({ message: 'Access denied' });
    }
    return res.status(500).json({ message: error.message || 'Server error' });
  }
};
