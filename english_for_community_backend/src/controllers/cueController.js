import Cue from '../models/Cue.js';

// GET /api/cues?listeningId=...&idx=... | from, limit
export const getCues = async (req, res) => {
  try {
    const { listeningId, idx, from = 0, limit = 10 } = req.query;
    if (!listeningId) return res.status(400).json({ message: 'listeningId is required' });

    // hide answers
    const projection = { textNorm: 0, __v: 0, createdAt: 0, updatedAt: 0 };

    if (idx !== undefined) {
      const cue = await Cue.findOne({ listeningId, idx: Number(idx) }, projection).lean();
      if (!cue) return res.status(404).json({ message: 'Cue not found' });
      return res.status(200).json(cue);
    }

    const docs = await Cue.find({ listeningId }, projection)
      .sort({ idx: 1 })
      .skip(Number(from))
      .limit(Number(limit))
      .lean();

    return res.status(200).json(docs);
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};