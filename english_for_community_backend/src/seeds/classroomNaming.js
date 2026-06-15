/**
 * Quy ước đặt tên lớp / đề / bài giao — giống trường THPT thật (không tiền tố seed).
 */

/** Lớp học: {Khối}{Tên lớp} — {Ca/Nhóm} · {Học kỳ} */
export const CLASSROOM_TEMPLATES = {
  homeroomMorning: (grade, section = 'A1') => ({
    name: `${grade}${section} — Ca sáng · HK2`,
    description: `Khối ${grade}, sĩ số ~36. Lịch T2–T4–T6 buổi sáng. Trọng tâm ngữ pháp nền và kỹ năng nghe–đọc.`,
  }),
  advanced: (gradeLabel, track = 'Nâng cao') => ({
    name: `${gradeLabel} — ${track} · HK2`,
    description: `Nhóm ${track.toLowerCase()} khối ${String(gradeLabel).replace(/\D/g, '')}. Tăng cường reading/writing và luyện đề định kỳ.`,
  }),
};

/**
 * Đề kiểm tra:
 * - KT 15' · Unit X — Kỹ năng
 * - Giữa HK · Đề n — ...
 * - Mock · Lần n — ...
 */
export function examTitle({ kind, unit, skillsLabel, index }) {
  const skill = skillsLabel || 'Tổng hợp';
  switch (kind) {
    case 'quick':
      return `KT 15' · Unit ${unit} — ${skill}`;
    case 'midterm':
      return `Giữa HK2 · Đề ${index} — ${skill}`;
    case 'homework':
      return `BTVN · Tuần ${unit} — ${skill}`;
    case 'mock':
      return `Mock lần ${index} — ${skill}`;
    case 'weekly':
      return `Ôn cuối tuần · Tuần ${unit} — ${skill}`;
    default:
      return `Kiểm tra · ${skill}`;
  }
}

export function assignmentWindowLabel(planKey) {
  const key = String(planKey || '').replace(/\s+/g, '_');
  const map = {
    past_closed: 'Đã đóng',
    recent_submissions: 'Vừa nộp bài',
    live_now: 'Đang diễn ra',
    opens_soon: 'Sắp mở',
    far_future: 'Lịch sau',
  };
  return map[key] || planKey;
}
