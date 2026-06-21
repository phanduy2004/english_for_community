/**
 * Serialize Mongo `.lean()` plain docs for API — thêm `id`/`attemptId`, giữ `_id` (expand-contract).
 */

function isPlainObject(v) {
  return v != null && typeof v === 'object' && !Array.isArray(v) && !(v instanceof Date);
}

/** Một document lean — thêm id (+ attemptId nếu là attempt). */
export function withLeanApiId(plain, { attempt = false } = {}) {
  if (!isPlainObject(plain) || plain._id == null) return plain;
  const id = String(plain._id);
  const out = { ...plain, id };
  if (attempt) out.attemptId = id;
  return out;
}

export function withLeanApiIds(list, opts) {
  if (!Array.isArray(list)) return list;
  return list.map((row) => withLeanApiId(row, opts));
}

/** Map sâu 1 cấp cho populate (userId, senderId, …). */
export function withLeanNestedIds(plain, nestedKeys = ['userId', 'senderId', 'recipientId', 'assignmentId', 'examId', 'classroomId']) {
  if (!isPlainObject(plain)) return plain;
  let out = withLeanApiId(plain);
  for (const key of nestedKeys) {
    const val = out[key];
    if (isPlainObject(val) && val._id != null) {
      out = { ...out, [key]: { ...val, id: String(val._id) } };
    }
  }
  return out;
}

export function withLeanNestedIdsList(list, nestedKeys) {
  if (!Array.isArray(list)) return list;
  return list.map((row) => withLeanNestedIds(row, nestedKeys));
}

/** Notification documents (Mongoose hoặc lean). */
export function serializeNotificationRow(n) {
  const plain = typeof n.toJSON === 'function' ? n.toJSON() : { ...n };
  return withLeanNestedIds(plain, ['senderId']);
}

export function serializeNotificationRows(rows) {
  return (rows ?? []).map(serializeNotificationRow);
}
