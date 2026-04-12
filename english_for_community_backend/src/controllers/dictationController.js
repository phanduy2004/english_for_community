import * as dictationService from '../services/dictationService.js';

export const submitDictation = async (req, res) => {
  try {
    const userId = req.user?._id || null;
    const result = await dictationService.submitDictation(userId, req.body);
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};

export const getDictationAttempts = async (req, res) => {
  try {
    const userId = req.user?._id || null;
    const listeningId = String(req.query.listeningId || '');
    const latest = String(req.query.latest || 'true') === 'true';

    const result = await dictationService.getDictationAttempts(userId, listeningId, latest);
    if (result.error) {
      return res.status(result.error.status).json({ message: result.error.message });
    }
    return res.status(200).json(result.data);
  } catch (e) {
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
};
