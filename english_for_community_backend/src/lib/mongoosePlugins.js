/**
 * Mongoose plugins — id serializer, soft-delete query helper, cascade hooks.
 */
import mongoose from 'mongoose';

/** Thêm `id` (string) vào toJSON/toObject; giữ `_id` (expand-contract). */
export function toJsonIdPlugin(schema) {
  const apply = (_doc, ret) => {
    if (ret._id != null) {
      ret.id = String(ret._id);
    }
    return ret;
  };

  if (!schema.get('toJSON')?.transform) {
    schema.set('toJSON', {
      virtuals: true,
      transform: apply,
    });
  }

  if (!schema.get('toObject')?.transform) {
    schema.set('toObject', {
      virtuals: true,
      transform: apply,
    });
  }
}

/**
 * Lọc mặc định bản ghi chưa xoá mềm.
 * Query `{ includeDeleted: true }` hoặc `Model.find().setOptions({ includeDeleted: true })` để bỏ lọc.
 */
export function softDeletePlugin(schema, options = {}) {
  const useDestroyFlag = options.useDestroyFlag !== false;

  if (!schema.path('deletedAt')) {
    schema.add({
      deletedAt: { type: Date, default: null, index: true },
    });
  }

  const applyFilter = function applyFilter() {
    if (this.getOptions?.()?.includeDeleted) return;
    const q = this.getQuery();
    if (q.deletedAt !== undefined) return;
    if (useDestroyFlag && q._destroy !== undefined) return;
    const clause = { deletedAt: null };
    if (useDestroyFlag) {
      this.where({ ...clause, _destroy: { $ne: true } });
    } else {
      this.where(clause);
    }
  };

  schema.pre(/^find/, applyFilter);
  schema.pre('countDocuments', applyFilter);
  schema.pre('aggregate', function () {
    if (this.options?.includeDeleted) return;
    const pipeline = this.pipeline();
    const hasDeletedMatch = pipeline.some(
      (stage) => stage.$match && ('deletedAt' in stage.$match || '_destroy' in stage.$match)
    );
    if (!hasDeletedMatch) {
      const match = { deletedAt: null };
      if (useDestroyFlag) match._destroy = { $ne: true };
      pipeline.unshift({ $match: match });
    }
  });

  schema.statics.softDeleteById = async function softDeleteById(id, extra = {}) {
    const now = new Date();
    const $set = { deletedAt: now, ...extra };
    if (useDestroyFlag) $set._destroy = true;
    return this.findByIdAndUpdate(id, { $set }, { new: true });
  };

  schema.statics.includeDeleted = function includeDeleted() {
    return this.find().setOptions({ includeDeleted: true });
  };
}

/** TTL dài — chỉ index, không xoá ngắn hạn (365 ngày mặc định). */
export function ttlIndexPlugin(schema, { field = 'createdAt', expireAfterSeconds = 365 * 24 * 3600 } = {}) {
  if (!schema.path(field)) {
    schema.add({ [field]: { type: Date, default: Date.now } });
  }
  schema.index({ [field]: 1 }, { expireAfterSeconds, name: `ttl_${field}_${expireAfterSeconds}` });
}

/** Cascade soft-delete con khi parent bị soft-delete (gọi từ service). */
export function registerCascadeSoftDelete(modelName, handlers) {
  const fn = async function cascadeSoftDelete(doc) {
    if (!doc?.deletedAt) return;
    for (const h of handlers) {
      await h(doc);
    }
  };
  mongoose.model(modelName).schema.post('findOneAndUpdate', async function (doc) {
    if (doc) await fn(doc);
  });
}

export async function softSetMany(Model, filter, extra = {}) {
  const now = new Date();
  const $set = { deletedAt: now, ...extra };
  if (Model.schema.path('_destroy')) $set._destroy = true;
  return Model.updateMany(filter, { $set });
}
