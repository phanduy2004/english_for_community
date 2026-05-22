import { walkItems } from './teacherExamService.js';

/** Simple 3-tier adaptive engine based on rolling accuracy on auto-graded items. */
export function computeAdaptiveState(attempt, items) {
  const meta = attempt.meta && typeof attempt.meta === 'object' ? { ...attempt.meta } : {};
  const adaptive = meta.adaptive && typeof meta.adaptive === 'object' ? { ...meta.adaptive } : {};
  const answers = attempt.answers || {};
  const scores = attempt.scores?.items || {};

  let answered = 0;
  let correct = 0;
  for (const it of items) {
    if (['reading', 'listening', 'essay', 'speaking'].includes(it.kind)) continue;
    const ans = answers[it.itemId];
    if (!ans) continue;
    answered += 1;
    const ir = scores[it.itemId];
    const max = Number(it.points ?? 1);
    const got = Number(ir?.awardedPoints ?? ir?.auto?.points ?? 0);
    if (got >= max * 0.99) correct += 1;
  }

  const accuracy = answered > 0 ? correct / answered : 0.5;
  let level = adaptive.level || 'medium';
  if (accuracy >= 0.8 && answered >= 2) level = 'hard';
  else if (accuracy < 0.45 && answered >= 2) level = 'easy';
  else level = 'medium';

  adaptive.level = level;
  adaptive.answeredCount = answered;
  adaptive.accuracy = Math.round(accuracy * 1000) / 1000;
  adaptive.updatedAt = new Date().toISOString();
  meta.adaptive = adaptive;
  return meta;
}

export function isAdaptiveExamSnapshot(snapshot) {
  const settings = snapshot?.settings || {};
  return settings.adaptiveEnabled === true || settings.examFormat === 'adaptive';
}

export function filterItemsForAdaptiveLevel(items, level) {
  if (!items.length) return items;
  const sorted = [...items].sort((a, b) => Number(a.difficulty ?? 2) - Number(b.difficulty ?? 2));
  if (level === 'easy') return sorted.slice(0, Math.max(1, Math.ceil(sorted.length * 0.6)));
  if (level === 'hard') return sorted.slice(Math.floor(sorted.length * 0.35));
  return sorted;
}

export function applyAdaptiveToSnapshot(snapshot, level) {
  if (!isAdaptiveExamSnapshot(snapshot)) return snapshot;
  const sections = Array.isArray(snapshot.sections) ? snapshot.sections : [];
  const nextSections = sections.map((sec) => {
    const items = walkItems([sec]);
    const filtered = filterItemsForAdaptiveLevel(items, level);
    const keepIds = new Set(filtered.map((i) => i.itemId));
    return {
      ...sec,
      items: (sec.items || []).filter((it) => keepIds.has(it.itemId)),
    };
  });
  return { ...snapshot, sections: nextSections };
}
