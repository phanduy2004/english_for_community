import mongoose from 'mongoose';

/** Chuẩn hoá speakingSetId (string | ObjectId) → ObjectId cho query/populate. */
export function toSpeakingSetObjectId(id) {
  if (id == null || id === '') return null;
  if (id instanceof mongoose.Types.ObjectId) return id;
  const s = String(id).trim();
  if (!mongoose.Types.ObjectId.isValid(s)) return null;
  return new mongoose.Types.ObjectId(s);
}

export function toSpeakingSetObjectIdList(ids) {
  const out = [];
  const seen = new Set();
  for (const id of ids ?? []) {
    const oid = toSpeakingSetObjectId(id);
    if (!oid) continue;
    const key = oid.toString();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(oid);
  }
  return out;
}
