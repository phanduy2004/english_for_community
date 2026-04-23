import Cue from '../models/Cue.js';

export async function getCuesByQuery({ listeningId, idx, from = 0, limit = 10 }) {
  if (!listeningId) {
    return { error: { status: 400, message: 'listeningId is required' } };
  }

  const projection = { textNorm: 0, __v: 0, createdAt: 0, updatedAt: 0 };

  if (idx !== undefined) {
    const cue = await Cue.findOne({ listeningId, idx: Number(idx) }, projection).lean();
    if (!cue) return { error: { status: 404, message: 'Cue not found' } };
    return { data: cue };
  }

  const docs = await Cue.find({ listeningId }, projection)
    .sort({ idx: 1 })
    .skip(Number(from))
    .limit(Number(limit))
    .lean();

  return { data: docs };
}
