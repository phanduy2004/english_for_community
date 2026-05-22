import TeacherAssignmentPreset from '../models/TeacherAssignmentPreset.js';
import { normalizeAssignmentConfig } from './teacherExamAssignmentService.js';

function httpError(statusCode, message) {
  const e = new Error(message);
  e.statusCode = statusCode;
  return e;
}

export const teacherAssignmentPresetService = {
  async list(teacherId) {
    return TeacherAssignmentPreset.find({ teacherId }).sort({ updatedAt: -1 });
  },

  async create(teacherId, body) {
    const name = String(body?.name || '').trim();
    if (!name) throw httpError(400, 'Preset name is required');
    const rawConfig = body?.config && typeof body.config === 'object' ? body.config : {};
    const config = normalizeAssignmentConfig({
      attemptPolicy: rawConfig.attemptPolicy,
      maxAttempts: rawConfig.maxAttempts,
      showResultsPolicy: rawConfig.showResultsPolicy,
      allowPartialSubmit: rawConfig.allowPartialSubmit ?? true,
      timeLimitSeconds: rawConfig.timeLimitSeconds,
    });
    return TeacherAssignmentPreset.create({
      teacherId,
      name,
      config: {
        mode: rawConfig.mode || 'self_paced',
        ...config,
      },
    });
  },

  async remove(teacherId, presetId) {
    const doc = await TeacherAssignmentPreset.findOne({ _id: presetId, teacherId });
    if (!doc) throw httpError(404, 'Preset not found');
    await doc.deleteOne();
    return { ok: true };
  },
};
