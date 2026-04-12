import * as cueService from '../services/cueService.js';

export const getCues = async (req, res) => {
  try {
    const { listeningId, idx, from = 0, limit = 10 } = req.query;
    const result = await cueService.getCuesByQuery({
      listeningId,
      idx,
      from,
      limit,
    });
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};
